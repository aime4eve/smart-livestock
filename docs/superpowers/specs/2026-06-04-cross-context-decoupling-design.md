# 跨限界上下文解耦设计规格

> 日期: 2026-06-04
> 状态: 评审中
> 目标: 单体内完成跨域解耦，消除所有跨上下文直接依赖，为未来微服务拆分做好准备

---

## 1. 背景与问题

### 1.1 当前架构

系统包含 6 个限界上下文（Identity / Ranch / IoT / Health / Commerce / Analytics）+ 1 个平台层（Platform），部署为单个 Spring Boot 应用。

跨上下文通信存在三类问题：

**问题一：RocketMQ 有发无收**

`SpringEventPublisher` 桥接了 7 个 topic 到 RocketMQ，但没有任何 `@RocketMQMessageListener` 消费者。消息无限堆积，RocketMQ 空转。

**问题二：Commerce 事件未接入 RocketMQ**

Commerce 上下文发布了 9+ 种域事件（Subscription/Contract/Service 相关），但 `SpringEventPublisher` 完全没有桥接这些事件。

**问题三：跨域直接引用**

10 处代码直接 import 并调用其他上下文的 Repository 或 ApplicationService，违反限界上下文边界。

### 1.2 目标

- 补齐所有 RocketMQ Consumer，形成完整的 pub/sub 闭环
- 所有跨域事件走 RocketMQ，删除 `@EventListener` 跨域消费
- 查询类跨域调用通过 ACL（Anti-Corruption Layer）端口隔离
- 单体内完成解耦，代码层面零跨域 import
- 未来拆分微服务时，只需改部署方式 + ACL 实现类，领域层代码零改动

---

## 2. 架构设计

### 2.1 跨域通信规则

| 类型 | 机制 | 适用场景 |
|------|------|---------|
| 跨域事件 | RocketMQ pub/sub | 写操作产生的副作用（遥测→健康分析、GPS→围栏检测） |
| 跨域命令 | RocketMQ（或同步 REST） | 需要触发其他上下文执行操作 |
| 跨域查询 | ACL 端口 + DTO | 需要读取其他上下文的数据（Controller 聚合、ApplicationService 查询） |

### 2.2 数据流

```
发布方上下文                    RocketMQ Topic                  消费方上下文
───────────────────────────────────────────────────────────────────────────────
IoT                           telemetry-received        →    Health
IoT                           gps-log-updated           →    Ranch
IoT                           device-activated          →    Platform
IoT                           license-expired           →    Platform
Ranch                         fence-breach-detected     →    Platform
Ranch                         alert-status-changed      →    Platform
Identity                      tenant-phase-changed      →    Platform
Commerce                      subscription-created      →    Platform
Commerce                      subscription-tier-changed  →    Platform
Commerce                      subscription-suspended    →    Platform
Commerce                      subscription-reactivated  →    Platform
Commerce                      subscription-expired      →    Platform
Commerce                      contract-signed           →    Platform
Commerce                      service-degraded          →    Platform
Commerce                      service-revoked           →    Platform
Commerce                      service-quota-adjusted    →    Platform
```

---

## 3. RocketMQ Consumer 设计

### 3.1 原则

- Consumer 属于**消费方**上下文的 `infrastructure/mq/` 包
- 每个 Consumer 用 `@RocketMQMessageListener` 注解，指定 topic + consumerGroup
- Consumer 内部调用本上下文的 ApplicationService，不跨域
- 删除所有 `@EventListener` / `@TransactionalEventListener` 跨域消费

### 3.2 Consumer 清单

**Health 上下文**：

```java
// health/infrastructure/mq/TelemetryEventConsumer.java
@Component
@RocketMQMessageListener(topic = "telemetry-received", consumerGroup = "health-telemetry-consumer")
public class TelemetryEventConsumer implements RocketMQListener<String> {
    // 反序列化 TelemetryReceivedEvent → 调 HealthApplicationService.processTelemetry()
}
```

**Ranch 上下文**：

```java
// ranch/infrastructure/mq/GpsLogEventConsumer.java
@Component
@RocketMQMessageListener(topic = "gps-log-updated", consumerGroup = "ranch-gps-consumer")
public class GpsLogEventConsumer implements RocketMQListener<String> {
    // 反序列化 GpsLogUpdatedEvent → 查安装记录 → 围栏检测 → 创建告警
}
```

**Platform 上下文**（通知 + 审计日志）：

```java
// platform/infrastructure/mq/IotNotificationConsumer.java // + RanchNotificationConsumer, IdentityNotificationConsumer
@Component
@RocketMQMessageListener(topic = "device-activated", consumerGroup = "platform-notification-consumer")
// + license-expired, fence-breach-detected, alert-status-changed, tenant-phase-changed
// + commerce subscription/contract/service topics
```

当前 `NotificationEventListener` 和 `AuditLogEventListener` 中的逻辑全部迁移到对应的 RocketMQ Consumer。

### 3.3 单体模式下的 Consumer 运行

当前是单体部署，Producer 和 Consumer 在同一进程。RocketMQ 在这个模式下扮演的角色是：
- **代码解耦**：编译期无跨域依赖
- **失败重试**：消费失败自动重试
- **削峰填谷**：高并发时缓冲消息

单体模式下 RocketMQ Consumer 的 consumerGroup 必须全局唯一，避免同一应用内冲突。

### 3.4 幂等性

Consumer 必须保证幂等（同一消息可能重试投递）。策略：
- 写入操作通过数据库唯一约束（如 GPS log 的 deviceId + recordedAt）防重
- 通知创建通过 notificationType + referenceId 防重
- 审计日志通过 eventHash 防重

---

## 4. ACL 查询端口设计

### 4.1 结构

```
{context}/
  domain/
    port/                          ← 端口接口定义
      RanchQueryPort.java
      RanchCommandPort.java
      dto/
        LivestockInfo.java
        FenceInfo.java
  infrastructure/
    acl/                           ← 端口实现（单体模式：进程内调用）
      RanchQueryPortImpl.java
```

**端口接口**放在 domain 层，因为 ApplicationService 依赖它。
**DTO** 由消费方定义，只包含自己需要的字段，不暴露对方领域模型。

### 4.2 端口清单

#### IoT 上下文需要的端口

```java
// iot/domain/port/RanchQueryPort.java
public interface RanchQueryPort {
    Optional<LivestockInfo> findLivestockById(Long livestockId);
    List<FenceInfo> findFencesByFarmId(Long farmId);
}

// iot/domain/port/IdentityQueryPort.java
public interface IdentityQueryPort {
    Optional<FarmInfo> findFarmById(Long farmId);
}
```

**替代**：`TelemetryIngestionService` 直接引用 `LivestockRepository`、`GpsSimulator` 直接引用 `FenceRepository`/`FarmRepository`/`LivestockRepository`、`InstallationController` 直接引用 `LivestockRepository`。

#### Ranch 上下文需要的端口

```java
// ranch/domain/port/IoTQueryPort.java
public interface IoTQueryPort {
    Optional<InstallationInfo> findActiveInstallation(Long deviceId);
    DeviceStatsInfo getDeviceStats(Long farmId);
}
```

**替代**：`GpsLogEventHandler` 直接引用 `InstallationRepository`、`DashboardController` 直接引用 `DeviceApplicationService`。

#### Identity 上下文需要的端口

```java
// identity/domain/port/RanchQueryPort.java
public interface RanchQueryPort {
    List<FenceInfo> findFencesByFarmId(Long farmId);
}

// identity/domain/port/RanchCommandPort.java
public interface RanchCommandPort {
    void initTileCoverage(Long farmId, GpsCoordinate center);
}
```

**替代**：`FarmApplicationService` 直接引用 `FenceRepository`/`TileAdminService`/`TileCoverageCalculator`。

**B2bController 特殊处理**：引入 `B2bFacade`，通过 ACL 端口聚合 Identity/Ranch/Commerce/IoT 数据，Controller 只调 Facade。

```java
// identity/application/facade/B2bFacade.java
@Component
public class B2bFacade {
    private final RanchQueryPort ranchQueryPort;
    private final CommerceQueryPort commerceQueryPort;
    private final IoTQueryPort ioTQueryPort;
    // 聚合查询方法
}
```

#### Commerce 上下文需要的端口

```java
// commerce/domain/port/RanchQueryPort.java
public interface RanchQueryPort {
    int countLivestockByFarmId(Long farmId);
    int countFencesByFarmId(Long farmId);
}
```

**替代**：`FarmLivestockUsageResolver` 直接引用 `LivestockRepository`、`FarmFenceUsageResolver` 直接引用 `FenceRepository`。

#### Health 上下文需要的端口

```java
// health/domain/port/RanchQueryPort.java
public interface RanchQueryPort {
    Optional<LivestockInfo> findLivestockById(Long livestockId);
}

// health/domain/port/RanchCommandPort.java
public interface RanchCommandPort {
    void createAlert(Long farmId, Long livestockId, AlertInfo alertInfo);
}
```

**替代**：`HealthApplicationService` 直接引用 `LivestockRepository`/`AlertRepository`。

### 4.3 DTO 定义

每个消费方在自己的 `domain/port/dto/` 下定义需要的 DTO：

```java
// iot/domain/port/dto/LivestockInfo.java
public record LivestockInfo(Long id, Long farmId, String livestockCode, String gender) {}

// iot/domain/port/dto/FenceInfo.java
public record FenceInfo(Long id, String name, List<CoordinateInfo> coordinates) {}

// ranch/domain/port/dto/InstallationInfo.java
public record InstallationInfo(Long id, Long deviceId, Long livestockId) {}
```

注意：不同上下文可能定义同名 DTO（如 IoT 和 Commerce 各自定义 `RanchQueryPort`），这是允许的——各自只包含自己需要的字段，未来拆分后独立演进。

---

## 5. Commerce 事件桥接

### 5.1 现状

Commerce 上下文通过 `DomainEventPublisher.publishDomainEvents()` 发布域事件到 Spring ApplicationEvent，但 `SpringEventPublisher` 没有桥接这些事件到 RocketMQ。

### 5.2 改造

在 `Topics.java` 新增 Commerce 相关 topic：

```java
public static final String SUBSCRIPTION_CREATED = "subscription-created";
public static final String SUBSCRIPTION_TIER_CHANGED = "subscription-tier-changed";
public static final String SUBSCRIPTION_SUSPENDED = "subscription-suspended";
public static final String SUBSCRIPTION_REACTIVATED = "subscription-reactivated";
public static final String SUBSCRIPTION_EXPIRED = "subscription-expired";
public static final String CONTRACT_SIGNED = "contract-signed";
public static final String SERVICE_DEGRADED = "service-degraded";
public static final String SERVICE_REVOKED = "service-revoked";
public static final String SERVICE_QUOTA_ADJUSTED = "service-quota-adjusted";
```

在 `SpringEventPublisher` 新增对应的 `@EventListener` 桥接方法。

---

## 6. 变更范围

### 6.1 新增文件

**RocketMQ Consumer**（消费方上下文 `infrastructure/mq/`）：

| 文件 | 上下文 | 消费 topic |
|------|--------|-----------|
| `TelemetryEventConsumer` | Health | telemetry-received |
| `GpsLogEventConsumer` | Ranch | gps-log-updated |
| `IotNotificationConsumer` | Platform | device-activated, license-expired |
| `RanchNotificationConsumer` | Platform | fence-breach-detected, alert-status-changed |
| `IdentityNotificationConsumer` | Platform | tenant-phase-changed |
| `CommerceNotificationConsumer` | Platform | subscription-created, subscription-tier-changed, subscription-suspended, subscription-reactivated, subscription-expired |
| `CommerceContractConsumer` | Platform | contract-signed |
| `CommerceServiceConsumer` | Platform | service-degraded, service-revoked, service-quota-adjusted |
| `AuditLogEventConsumer` | Shared | 所有事件 topic |

**ACL 端口接口 + DTO**：

| 上下文 | 端口 | DTO |
|--------|------|-----|
| IoT | `RanchQueryPort`, `IdentityQueryPort` | `LivestockInfo`, `FenceInfo`, `FarmInfo` |
| Ranch | `IoTQueryPort` | `InstallationInfo`, `DeviceStatsInfo` |
| Identity | `RanchQueryPort`, `RanchCommandPort`, `CommerceQueryPort`, `IoTQueryPort` | `FenceInfo`, `SubscriptionInfo`, `DeviceStatsInfo` |
| Commerce | `RanchQueryPort` | `LivestockInfo`, `FenceInfo` |
| Health | `RanchQueryPort`, `RanchCommandPort` | `LivestockInfo`, `AlertInfo` |

**ACL 端口实现**（每个消费方上下文 `infrastructure/acl/`）：

| 上下文 | 实现 |
|--------|------|
| IoT | `RanchQueryPortImpl`, `IdentityQueryPortImpl` |
| Ranch | `IoTQueryPortImpl` |
| Identity | `RanchQueryPortImpl`, `RanchCommandPortImpl`, `CommerceQueryPortImpl`, `IoTQueryPortImpl` |
| Commerce | `RanchQueryPortImpl` |
| Health | `RanchQueryPortImpl`, `RanchCommandPortImpl` |

**Facade**：

| 文件 | 上下文 | 替代 |
|------|--------|------|
| `B2bFacade` | Identity | B2bController 直接跨域调用 |

### 6.2 修改文件

| 文件 | 变更 |
|------|------|
| `TelemetryIngestionService` | 删 `LivestockRepository`，注入 `RanchQueryPort` |
| `GpsSimulator` | 删跨域引用，注入 `RanchQueryPort` + `IdentityQueryPort` |
| `InstallationController` | 删 `LivestockRepository`，注入 `RanchQueryPort` |
| `DashboardController` | 删 `DeviceApplicationService`，注入 `IoTQueryPort` |
| `FarmApplicationService` | 删 Ranch 引用，注入 `RanchQueryPort` + `RanchCommandPort` |
| `B2bController` | 删所有跨域引用，注入 `B2bFacade` |
| `FarmLivestockUsageResolver` | 删 `LivestockRepository`，注入 `RanchQueryPort` |
| `FarmFenceUsageResolver` | 删 `FenceRepository`，注入 `RanchQueryPort` |
| `HealthApplicationService` | 删 Ranch 引用，注入 `RanchQueryPort` + `RanchCommandPort` |
| `Topics.java` | 新增 9 个 Commerce topic |
| `SpringEventPublisher` | 新增 Commerce 事件桥接 |
| `CreateFarmCommand` | 删 `GpsCoordinate` 跨域引用，改用本地值对象 |

### 6.3 删除文件

| 文件 | 原因 |
|------|------|
| `SensorTelemetryEventHandler` | 由 `TelemetryEventConsumer` 替代 |
| `GpsLogEventHandler` | 由 `GpsLogEventConsumer` 替代 |
| `NotificationEventListener` | 由 Platform Consumer 替代 |
| `AuditLogEventListener` | 由 `AuditLogEventConsumer` 替代 |

### 6.4 不变

- 域事件类本身（`GpsLogUpdatedEvent` 等）保持不变
- `DomainEventPublisher` / `RocketMQEventPublisher` 框架不变
- Controller API 契约不变
- DB 表结构不变

---

## 7. 测试策略

### 7.1 Consumer 测试

每个 Consumer 用单元测试：
- Mock RocketMQ 消息（JSON 字符串）
- 验证反序列化正确
- 验证调用了正确的 ApplicationService 方法

### 7.2 ACL 端口测试

每个端口实现用单元测试：
- 端口实现内部调用对应上下文的 Repository
- 验证 DTO 映射正确

### 7.3 集成测试

- 部署完整环境（含 RocketMQ）
- 发送消息到 topic → 验证消费者正确处理
- 验证无跨域 import（`rg` 扫描验证）

---

## 8. 风险与缓解

| 风险 | 缓解 |
|------|------|
| RocketMQ Consumer 与 Producer 同进程，启动顺序依赖 | `RocketMQEventPublisher` 已做优雅降级；Consumer 连接失败会自动重连 |
| Consumer 重复消费（进程内 @EventListener 残留） | 彻底删除旧 @EventListener，确保只有一个消费路径 |
| ACL 端口实现类仍 import 其他上下文类 | 这是预期行为——ACL 实现在 infrastructure 层，domain 层零跨域 import |
| B2bController Facade 增加间接层 | Facade 只做数据聚合，不含业务逻辑，复杂度可控 |
| 大量文件改动可能引入 bug | 分批实施，每批编译+测试验证 |

---

## 9. 与 Telemetry Redesign Plan 的关系

本设计是一个**更大的架构改造**，涵盖整个系统的跨域通信。`2026-06-04-telemetry-redesign-plan.md` 中的 R1-R3 任务可以视为本设计的一个子集。

建议执行顺序：
1. 先完成本设计的 spec 评审
2. 将 telemetry redesign plan 合并到本设计的实施计划中
3. 按依赖顺序分批实施
