# 跨限界上下文解耦 实施计划

> 日期: 2026-06-04
> 设计规格: `docs/superpowers/specs/2026-06-04-cross-context-decoupling-design.md`
> 前置: Telemetry Redesign Plan (R1-R3) 覆盖 IoT + Health 解耦

---

## 设计约束

- 每个**上下文 domain 层**零跨域 import
- 跨域事件走 RocketMQ（非 @EventListener / @TransactionalEventListener）
- 跨域查询走 ACL 端口（非直接引用其他上下文 Repository）
- infrastructure 层允许跨域 import（ACL 实现类 + RocketMQ Consumer）

---

## 依赖关系

```
Batch D1: Topics + Commerce 事件桥接（基础设施层）
    ↓
Batch D2: Ranch ACL + Consumer 解耦
    ↓
Batch D3: Identity ACL + B2bFacade 解耦
    ↓
Batch D4: Commerce ACL 解耦
    ↓
Batch D5: Platform Consumers（替代 NotificationEventListener + AuditLogEventListener）
    ↓
Batch D6: Analytics ACL 解耦
    ↓
Batch D7: 全量验证 + 清理
```

---

### Batch D1: Topics 扩展 + Commerce 事件桥接

**Task D1a: Topics.java 新增 Commerce 事件 topics**
- 上下文: Shared
- 步骤:
  1. `Topics.java` 新增 9 个常量:
     - `SUBSCRIPTION_CREATED = "subscription-created"`
     - `SUBSCRIPTION_TIER_CHANGED = "subscription-tier-changed"`
     - `SUBSCRIPTION_SUSPENDED = "subscription-suspended"`
     - `SUBSCRIPTION_REACTIVATED = "subscription-reactivated"`
     - `SUBSCRIPTION_EXPIRED = "subscription-expired"`
     - `CONTRACT_SIGNED = "contract-signed"`
     - `SERVICE_DEGRADED = "service-degraded"`
     - `SERVICE_REVOKED = "service-revoked"`
     - `SERVICE_QUOTA_ADJUSTED = "service-quota-adjusted"`
- 验证: 编译通过
- 产出: Topics.java

**Task D1b: SpringEventPublisher 桥接 Commerce 事件**
- 上下文: Shared (infrastructure)
- 步骤:
  1. `SpringEventPublisher` 新增 9 个 `@EventListener` 方法:
     - `onSubscriptionCreated(SubscriptionCreatedEvent)` → Topics.SUBSCRIPTION_CREATED
     - `onSubscriptionTierChanged(SubscriptionTierChangedEvent)` → Topics.SUBSCRIPTION_TIER_CHANGED
     - ... 其余 7 个事件同理
  2. 新增 import: `com.smartlivestock.shared.domain.event.*`（这些事件在 shared 包下，不违反跨域规则）
- 验证: 编译通过
- 产出: SpringEventPublisher.java

---

### Batch D2: Ranch 上下文解耦

**Task D2a: Ranch ACL 端口（IoT 查询）**
- 上下文: Ranch
- 步骤:
  1. 新建 `ranch/domain/port/IoTQueryPort.java`:
     - `Optional<InstallationInfo> findActiveInstallation(Long deviceId)`
     - `DeviceStatsInfo getDeviceStats(Long farmId)`
  2. 新建 DTO:
     - `ranch/domain/port/dto/InstallationInfo.java` (record: id, deviceId, livestockId)
     - `ranch/domain/port/dto/DeviceStatsInfo.java` (record: total, active, inactive)
  3. 新建 `ranch/infrastructure/acl/IoTQueryPortImpl.java`:
     - 注入 IoT 的 `InstallationRepository`、`DeviceApplicationService`
     - 实现接口方法，返回 DTO
  4. 修改 `DashboardController`:
     - 删除 `DeviceApplicationService` 跨域引用
     - 注入 `IoTQueryPort`
  5. 修改 `GpsLogEventHandler` → 改为 `GpsLogEventConsumer`（RocketMQ）:
     - 新建 `ranch/infrastructure/mq/GpsLogEventConsumer.java`
     - `@RocketMQMessageListener(topic = "gps-log-updated", consumerGroup = "ranch-gps-consumer")`
     - 反序列化 GpsLogUpdatedEvent → 通过 IoTQueryPort 查安装记录 → 围栏检测 → 创建告警
     - 删除旧 `ranch/infrastructure/event/GpsLogEventHandler.java`
  6. 修改 `FenceController`:
     - 删除 `FarmRepository`（Identity）跨域引用，注入 `IdentityQueryPort`（如果 D3 未建，暂时在 Ranch 定义自己的 IdentityQueryPort）
  7. 修改 `TileAppController`:
     - 同上，删除 `FarmRepository` 跨域引用
- 验证: 编译通过 + `rg "import com.smartlivestock.iot" ranch/domain/` 零结果
- 产出: IoTQueryPort + DTO + Impl + GpsLogEventConsumer + DashboardController 修改 + 1 删除

**Task D2b: Ranch ACL 端口（Identity 查询）**
- 上下文: Ranch
- 步骤:
  1. 新建 `ranch/domain/port/IdentityQueryPort.java`:
     - `Optional<FarmInfo> findFarmById(Long farmId)`
  2. 新建 `ranch/domain/port/dto/FarmInfo.java` (record: id, tenantId, name)
  3. 新建 `ranch/infrastructure/acl/IdentityQueryPortImpl.java`
  4. FenceController / TileAppController / TileController 中的 `FarmRepository` 引用全部替换为 `IdentityQueryPort`
- 验证: 编译通过 + `rg "import com.smartlivestock.identity" ranch/domain/` 零结果
- 产出: IdentityQueryPort + DTO + Impl + Controller 修改

---

### Batch D3: Identity 上下文解耦

**Task D3a: Identity ACL 端口（Ranch 查询 + 命令）**
- 上下文: Identity
- 步骤:
  1. 新建 `identity/domain/port/RanchQueryPort.java`:
     - `List<FenceInfo> findFencesByFarmId(Long farmId)`
  2. 新建 `identity/domain/port/RanchCommandPort.java`:
     - `void initTileCoverage(Long farmId, GpsCoordinate center)`
  3. 新建 DTO:
     - `identity/domain/port/dto/FenceInfo.java`
     - `identity/domain/port/dto/CoordinateInfo.java`
  4. 新建 `identity/infrastructure/acl/RanchQueryPortImpl.java`:
     - 注入 Ranch 的 `FenceRepository`
  5. 新建 `identity/infrastructure/acl/RanchCommandPortImpl.java`:
     - 注入 Ranch 的 `TileAdminService` + `TileCoverageCalculator`
  6. 修改 `FarmApplicationService`:
     - 删除 Ranch 跨域引用（FenceRepository, TileAdminService, TileCoverageCalculator）
     - 注入 `RanchQueryPort` + `RanchCommandPort`
  7. 修改 `CreateFarmCommand`:
     - 删除 `com.smartlivestock.ranch.domain.model.GpsCoordinate` 引用
     - 改用本地值对象或 `identity/domain/port/dto/CoordinateInfo`
  8. 修改 `FarmController`:
     - 删除 Ranch `GpsCoordinate` 引用
- 验证: 编译通过 + `rg "import com.smartlivestock.ranch" identity/domain/` 零结果
- 产出: RanchQueryPort + RanchCommandPort + DTO + Impl + FarmApplicationService 修改

**Task D3b: B2bController 解耦 + B2bFacade**
- 上下文: Identity
- 步骤:
  1. 新建 Identity ACL 端口（扩展）:
     - `identity/domain/port/RanchQueryPort` 新增方法（如需牲畜/告警列表）
     - `identity/domain/port/CommerceQueryPort.java` (接口)
     - `identity/domain/port/IoTQueryPort.java` (接口)
     - 对应 DTO 和 Impl
  2. 新建 `identity/application/facade/B2bFacade.java`:
     - 注入所有 ACL 端口
     - 聚合多个上下文数据的方法（对应 B2bController 当前调用的各服务方法）
  3. 修改 `B2bController`:
     - 删除所有跨域 import（Commerce, IoT, Ranch）
     - 注入 `B2bFacade`
     - 所有方法改为调 Facade
- 验证: 编译通过 + `rg "import com.smartlivestock.commerce" identity/domain/` 零结果 + `rg "import com.smartlivestock.iot" identity/domain/` 零结果
- 产出: CommerceQueryPort + IoTQueryPort + DTO + Impl + B2bFacade + B2bController 修改

---

### Batch D4: Commerce 上下文解耦

**Task D4a: Commerce ACL 端口（Ranch 查询）**
- 上下文: Commerce
- 步骤:
  1. 新建 `commerce/domain/port/RanchQueryPort.java`:
     - `int countLivestockByFarmId(Long farmId)`
     - `int countFencesByFarmId(Long farmId)`
  2. 新建 `commerce/infrastructure/acl/RanchQueryPortImpl.java`:
     - 注入 Ranch 的 `LivestockRepository` + `FenceRepository`
  3. 修改 `FarmLivestockUsageResolver`:
     - 删除 `com.smartlivestock.ranch.domain.repository.LivestockRepository`
     - 注入 `RanchQueryPort`
  4. 修改 `FarmFenceUsageResolver`:
     - 删除 `com.smartlivestock.ranch.domain.repository.FenceRepository`
     - 注入 `RanchQueryPort`
- 验证: 编译通过 + `rg "import com.smartlivestock.ranch" commerce/domain/` 零结果
- 产出: RanchQueryPort + Impl + 2 个 Resolver 修改

---

### Batch D5: Platform Consumers（替代 @TransactionalEventListener）

**Task D5a: Platform Notification Consumers**
- 上下文: Platform
- 步骤:
  1. 新建 `platform/infrastructure/mq/IotNotificationConsumer.java`:
     - `@RocketMQMessageListener(topic = "device-activated", consumerGroup = "platform-iot-consumer")`
     - 消费 device-activated + license-expired（需要多个 Consumer 类或 topic 合并策略）
  2. 新建 `platform/infrastructure/mq/RanchNotificationConsumer.java`:
     - 消费 fence-breach-detected + alert-status-changed
  3. 新建 `platform/infrastructure/mq/IdentityNotificationConsumer.java`:
     - 消费 tenant-phase-changed
  4. 新建 `platform/infrastructure/mq/CommerceSubscriptionConsumer.java`:
     - 消费 subscription-created/tier-changed/suspended/reactivated/expired
  5. 新建 `platform/infrastructure/mq/CommerceContractConsumer.java`:
     - 消费 contract-signed
  6. 新建 `platform/infrastructure/mq/CommerceServiceConsumer.java`:
     - 消费 service-degraded/revoked/quota-adjusted
  7. 每个 Consumer 内部调用 `NotificationService.createNotification()`（同上下文，无需 ACL）
  8. 删除 `platform/messaging/NotificationEventListener.java`
- 验证: 编译通过 + `rg "NotificationEventListener" src/main/` 零引用
- 产出: 6 个 Consumer + 1 删除

**Task D5b: AuditLog Consumer**
- 上下文: Shared
- 步骤:
  1. 新建 `shared/infrastructure/mq/AuditLogEventConsumer.java`:
     - 消费所有事件 topic（每个 topic 需要一个 Consumer 类，或合并审计逻辑到各 Platform Consumer 中）
     - 策略：在每个 Platform Consumer 中同时写审计日志，替代独立的 AuditLogConsumer
  2. 删除 `shared/listeners/AuditLogEventListener.java`
- 验证: 编译通过 + `rg "AuditLogEventListener" src/main/` 零引用
- 产出: 审计逻辑集成到 Consumer + 1 删除

---

### Batch D6: Analytics 上下文解耦

**Task D6a: Analytics ACL 端口（Identity 查询）**
- 上下文: Analytics
- 步骤:
  1. 新建 `analytics/domain/port/IdentityQueryPort.java`:
     - `Optional<ApiKeyInfo> findApiKeyByKey(String apiKey)`
  2. 新建 `analytics/infrastructure/acl/IdentityQueryPortImpl.java`:
     - 注入 Identity 的 `ApiKeyApplicationService`
  3. 修改 `ApiCallLogInterceptor`:
     - 删除 `com.smartlivestock.identity.domain.model.ApiKey` 引用
     - 注入 `IdentityQueryPort`
  4. 修改 `PortalAdminController` + `PortalAppController`:
     - 删除 Identity 跨域引用
     - 注入 `IdentityQueryPort`
- 验证: 编译通过 + `rg "import com.smartlivestock.identity" analytics/domain/` 零结果
- 产出: IdentityQueryPort + Impl + 3 个 Controller 修改

---

### Batch D7: 全量验证 + 清理

**Task D7a: 全量编译 + 单元测试**
- 验证:
  - `compileJava` 成功
  - 全量单元测试通过（排除 integration 测试）

**Task D7b: 跨域 import 零验证**
- 验证:
  - 对每个上下文 domain 层扫描跨域 import：
    ```
    for ctx in iot ranch health identity commerce analytics; do
      echo "=== $ctx domain layer ==="
      rg "import com\.smartlivestock\." src/main/java/com/smartlivestock/$ctx/domain/ | grep -v "import com.smartlivestock.$ctx." | grep -v "import com.smartlivestock.shared.domain."
    done
    ```
  - 期望：只有 `com.smartlivestock.{ctx}.` 和 `com.smartlivestock.shared.domain.` 的 import（shared 域事件是跨域通信的契约，允许）
  - `@EventListener` 跨域消费零引用（只有 `SpringEventPublisher` 中的桥接保留）
  - 旧文件确认删除：SensorTelemetryEventHandler, GpsLogEventHandler, NotificationEventListener, AuditLogEventListener

**Task D7c: RocketMQ Consumer 注册验证**
- 验证:
  - 每个 topic 至少有一个 Consumer
  - `@RocketMQMessageListener` 注解的 consumerGroup 全局唯一
  - SpringEventPublisher 桥接的 topic 列表与 Consumer 覆盖的 topic 列表一致

---

## 风险与缓解

| 风险 | 缓解 |
|------|------|
| 大量文件改动可能引入 bug | 分批实施，每批编译+测试验证 |
| RocketMQ Consumer 多 topic 监听 | 一个 Consumer 类只能监听一个 topic，多 topic 需要多 Consumer 类 |
| ACL 端口 DTO 可能遗漏字段 | 每个 Resolver/Service 只定义自己需要的字段，保持最小化 |
| B2bFacade 聚合逻辑复杂 | 只做数据聚合，不含业务逻辑；每个方法对应一个页面接口 |
| Platform Consumer 数量多 | 按来源上下文分组（IoT/Ranch/Identity/Commerce），每组一个或多个 Consumer |
| @TransactionalEventListener 的 AFTER_COMMIT 语义丢失 | RocketMQ Consumer 天然在事务外执行；SpringEventPublisher 在 publish 后才发 MQ，等效于 AFTER_COMMIT |
| shared.domain.event 中的 Commerce 事件被 SpringEventPublisher import | SpringEventPublisher 在 shared/infrastructure 层，import shared.domain.event 合法 |

---

## 执行顺序总结

| 批次 | 内容 | 上下文 |
|------|------|--------|
| D1 | Topics 扩展 + Commerce 事件桥接 | Shared |
| D2 | Ranch ACL + GpsLog Consumer | Ranch |
| D3 | Identity ACL + B2bFacade | Identity |
| D4 | Commerce ACL | Commerce |
| D5 | Platform Consumers | Platform + Shared |
| D6 | Analytics ACL | Analytics |
| D7 | 全量验证 + 清理 | All |

---

## 执行上下文：3 份 Plan × 2 份 Spec 交叉比对

### 文件清单

| 类型 | 文件 | 说明 |
|------|------|------|
| Spec 1 | `2026-06-04-telemetry-redesign-spec.md` | 遥测管道重构设计 |
| Spec 2 | `2026-06-04-cross-context-decoupling-design.md` | 跨域解耦设计 |
| Plan A（旧） | `2026-06-04-iot-telemetry-ingestion-plan.md` | 旧版 14 Task 计划，T1-T11 已实现，归档 |
| Plan B | `2026-06-04-telemetry-redesign-plan.md` | 遥测重构（R1-R3），Phase 1 执行 |
| Plan C（本文件） | `2026-06-04-cross-context-decoupling-plan.md` | 跨域解耦（D1-D7），Phase 2 执行 |

### Spec 覆盖矩阵

**Spec 1（Telemetry Redesign）**：完全由 Plan B (R1-R3) 覆盖。

**Spec 2（Cross-Context Decoupling）**：

| Spec 章节 | Plan B 覆盖 | Plan C 覆盖 |
|-----------|------------|------------|
| §3 RocketMQ Consumer 补齐 | ✅ R1c (Health Consumer) | ✅ D2 (Ranch), D5 (Platform) |
| §4 ACL 查询端口 | ✅ R1b (IoT→Ranch), R1c (Health→Ranch) | ✅ D2-D6 (其余上下文) |
| §5 Commerce 事件桥接 | — | ✅ D1 |
| §6 变更范围 | ✅ IoT + Health 部分 | ✅ 其余全部 |

**两份 Spec 合计覆盖**：Plan B + Plan C = 100%。

### 全局执行顺序

```
Phase 1: Plan B — Telemetry Redesign (R1→R2→R3)
  │  重构 IoT + Health 两个上下文的遥测管道
  │  同时引入 ACL + RocketMQ（作为解耦的起点）
  ↓
Phase 2: Plan C（本文件）— Cross-Context Decoupling (D1→D2→D3→D4→D5→D6→D7)
  │  解耦剩余所有上下文（Ranch/Identity/Commerce/Platform/Analytics）
  │  补齐所有 RocketMQ Consumer + ACL 端口
  ↓
Phase 3: Plan A 残留 T12-T14 — 前端对接 + E2E 验证
  │  T12: 前端 TwinOverview 对接 health/overview
  │  T13: 前端 StatsPage 实现
  │  T14: 部署 + 端到端验证
  └─ 完成
```

### Plan A（旧）处理

Plan A 的 T1-T11 已全部在代码中实现，且将被 Plan B 重构覆盖。**Plan A 归档，不再执行。** 仅保留 T12-T14 移至 Phase 3（前端对接与验证），可在 Plan B + C 完成后单独执行。

### 未覆盖 Gap

| Gap | 来源 | 建议处理 |
|-----|------|---------|
| T12: 前端 TwinOverview 对接 | Plan A | Phase 3 单独执行 |
| T13: 前端 StatsPage 实现 | Plan A | Phase 3 单独执行 |
| T14: 部署 + E2E 验证 | Plan A | Phase 3 单独执行 |
