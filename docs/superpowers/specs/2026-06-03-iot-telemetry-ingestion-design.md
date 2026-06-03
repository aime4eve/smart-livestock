# IoT 遥测数据采集 + 健康模拟器 设计规格

> 日期: 2026-06-03
> 状态: 设计中

---

## 1. 目标

实现从设备到健康分析的完整遥测数据链路：

1. IoT 上下文新增遥测数据接收能力（`TelemetryIngestionService`），作为真实设备和模拟器的统一内部入口
2. IoT 发布 `SensorTelemetryReceivedEvent` 领域事件，Health 上下文消费并驱动分析管线
3. 新增 `CapsuleTelemetrySimulator`，遵循与 `GpsSimulator` 一致的架构模式
4. 前端 TwinOverview / Stats 对接 Health API 展示实时数据
5. 为 Phase 3 IoT 真实接入预留标准接口

## 2. 架构概念澄清

### 2.1 IoT 遥测链路 vs Open API 能力开放

这是两个不同层面的概念，不能混淆：

| 维度 | IoT 遥测数据链路 | Open API 能力开放 |
|------|----------------|-------------------|
| **定位** | 设备数据采集的内部通道 | SaaS 平台对外暴露的查询/操作服务 |
| **调用方** | IoT 设备、模拟器、LoRa/NS 网关 | 第三方开发者、集成商 |
| **数据方向** | 写入（设备 → 平台） | 以读取为主 |
| **认证** | 设备身份认证（设备 ID + 安装关系） | API Key 认证 |
| **路由前缀** | `/api/v1/farms/{farmId}/devices/{deviceId}/telemetry`（App 路径） | `/api/v1/open/` |
| **协议** | MQTT / CoAP / HTTP（Phase 3 由网关决定） | HTTPS REST |

**遥测上报走 IoT 内部链路，不走 Open API。** Open API 的职责是为第三方提供平台数据的只读访问，以及极少量受控写操作（如设备自注册）。

### 2.2 现有代码问题

`OpenDeviceRegisterController`（`POST /api/v1/open/devices/register`）将设备自注册放在 Open API 层。设备自注册本质上是 IoT 设备管理能力的一部分，经过 Open API 暴露给合作伙伴，这一点在原设计中已明确（"唯一写操作"），暂不需要调整。但遥测上报不应走 Open API 路径。

### 2.3 Phase 3 设备接入路径预想

```
真实设备 (CAPSULE/TRACKER)
  → LoRa 网络 → NS 平台（Network Server）
  → HTTP 回调 → POST /api/v1/farms/{farmId}/devices/{deviceId}/telemetry (IoT App API)
  → TelemetryIngestionService
```

模拟器与此路径一致，只是跳过了 LoRa/NS 层，直接调 `TelemetryIngestionService`。

## 3. 现有架构分析

### 3.1 跨上下文通信模式（已有）

```
GpsSimulator (IoT, @ConditionalOnProperty)
  → GpsLogApplicationService.logGps()     // IoT 内部 Service
  → 写入 gps_logs                          // IoT 拥有的表

GpsLogUpdatedEvent (IoT 领域事件)
  → SpringEventPublisher 转发 RocketMQ    // Shared 桥接层
  → GpsLogEventHandler (Ranch)             // 跨上下文消费
    → 检测围栏越界 → 创建 Alert
```

### 3.2 原始设计定义的数据流方向（MVP Backend Design）

> **IoT → Health → Ranch（单向，不回头）**
> IoT ──遥测事件──→ Health（评分规则 → HealthAnomalyDetected）
> Health ──异常事件──→ Ranch（→ Alert）

本次实现 IoT → Health 段，Health → Ranch 段留到后续。

### 3.3 当前 Health 数据写路径（缺失）

Health 上下文有完整的分析管线（FeverAnalysisService、DigestiveAnalysisService 等）和 6 张数据表，但**没有写路径**——所有数据来自 V21 种子 SQL 直接插入。

### 3.4 设备类型模型与遥测数据映射

**设备类型模型：**

- **CAPSULE（瘤胃胶囊）**：集成温度传感器 + 蠕动传感器 + 加速度计。单设备上报三类数据
- **TRACKER（GPS 追踪器）**：GPS 定位 + 步数计 + 距离计算
- **EAR_TAG（耳标）**：RFID 身份识别（Phase 3）

> **ACCELEROMETER 不是独立设备类型。** 加速度计是 CAPSULE 内部的传感器组件，其数据（activity_index）随胶囊遥测一起上报。现有代码中 `DeviceType.ACCELEROMETER` 及 V10 种子数据中 20 条 ACCELEROMETER 设备属于早期设计偏差，需要清理。

| 设备类型 | 上报遥测数据 | 写入目标表 | 所属上下文 |
|----------|-------------|-----------|-----------|
| CAPSULE | temperature | temperature_logs | Health |
| CAPSULE | frequency, intensity | rumen_motility_logs | Health |
| CAPSULE | activity_index | activity_logs | Health |
| TRACKER | step_count, distance_meters | activity_logs | Health |

注意：数据库表定义在 Health 上下文（V20 迁移），但 IoT 上下文拥有设备身份和安装关系。遥测数据通过事件从 IoT 流向 Health。

## 4. 架构设计

### 4.1 数据流总览

```
┌──────────────────────────────────────────────────────────────────┐
│ IoT Bounded Context                                               │
│                                                                    │
│  App API:                                                          │
│    POST /api/v1/farms/{farmId}/devices/{deviceId}/telemetry ─┐    │
│                                                                │   │
│  模拟器:                                                        │   │
│    TelemetrySimulator ────────────────────────────────────────┤   │
│                                                                ↓   │
│  Phase 3:                                                      │   │
│    LoRa/NS 网关回调 ──────────────────────────────────────────┤   │
│                                                                ↓   │
│                                                     TelemetryIngestionService│
│                                       → 验证设备 + 安装状态         │
│                                       → 发布                       │
│                                         SensorTelemetryReceived    │
│                                           Event (领域事件)          │
└────────────────────────── Spring Event Bus ──────────────────────┘
                            │
           ┌────────────────┤
           ↓                ↓
┌──────────────────┐  ┌──────────────────────────────────┐
│ Ranch (已有)      │  │ Health (新增消费)                  │
│ GpsLogEventHandler│  │ SensorTelemetryEventHandler       │
│ → 围栏越界检测    │  │   → 写入 temperature_logs         │
│                  │  │   → 写入 rumen_motility_logs       │
│                  │  │   → 写入 activity_logs             │
│                  │  │   → 驱动分析管线                    │
│                  │  │   → 更新 HealthSnapshot            │
│                  │  │   → 评估 EstrusScore               │
└──────────────────┘  └──────────────────────────────────┘
```

### 4.2 IoT 上下文新增组件

#### 4.2.1 领域事件: `SensorTelemetryReceivedEvent`

```
com.smartlivestock.iot.domain.event.SensorTelemetryReceivedEvent

字段:
  - Long deviceId
  - Long livestockId        // 从 Installation 解析
  - Long farmId             // 从 Livestock 解析
  - String telemetryType    // TEMPERATURE | MOTILITY | ACTIVITY

  // TEMPERATURE (来自 CAPSULE)
  - BigDecimal temperature
  - BigDecimal baselineTemp

  // MOTILITY (来自 CAPSULE)
  - BigDecimal motilityFrequency
  - BigDecimal motilityIntensity

  // ACTIVITY
  //   CAPSULE 上报: activity_index
  //   TRACKER 上报: step_count, distance_meters
  - Integer stepCount
  - BigDecimal activityIndex
  - BigDecimal distanceMeters

  - Instant recordedAt
```

#### 4.2.2 Application Service: `TelemetryIngestionService`

IoT 上下文的遥测数据入口，负责设备身份验证和事件发布。不写任何 Health 表。

```
com.smartlivestock.iot.application.TelemetryIngestionService

职责:
  1. 验证设备存在且 ACTIVE
  2. 查找活跃 Installation → 获取 livestockId
  3. 解析遥测类型（根据设备类型推断或显式传入）
  4. 发布 SensorTelemetryReceivedEvent

依赖:
  - DeviceRepository (IoT)
  - InstallationRepository (IoT)
  - ApplicationEventPublisher (Spring)

事务边界:
  @Transactional(readOnly = true) — IoT 不写新数据，只读+发事件
```

#### 4.2.3 App API Controller: `TelemetryController`

IoT 内部的遥测上报端点，走 JWT 认证（App API 路径），不是 Open API。

```
com.smartlivestock.iot.interfaces.TelemetryController

POST /api/v1/farms/{farmId}/devices/{deviceId}/telemetry
  - JWT 认证（同其他 App API）
  - farmId 用于验证设备归属（通过 Installation → Livestock → farmId）
  - 调用 TelemetryIngestionService.ingest()

Request body (CAPSULE 上报):
{
  "readings": [
    {
      "temperature": 38.6,
      "motilityFrequency": 3.2,
      "motilityIntensity": 45.0,
      "activityIndex": 62.0,
      "recordedAt": "2026-06-03T10:00:00Z"
    }
  ]
}

Request body (TRACKER 上报):
{
  "readings": [
    {
      "stepCount": 1500,
      "distanceMeters": 450.0,
      "recordedAt": "2026-06-03T10:00:00Z"
    }
  ]
}
```

为什么放在 App API 而不是 Open API：
- 这是 IoT 内部的设备数据采集接口
- 认证方式是 JWT（平台内部调用），不是 API Key（第三方调用）
- Phase 3 的 LoRa/NS 网关回调也走此端点（或通过内部 Service 直调）

#### 4.2.4 模拟器: `TelemetrySimulator`

与 `GpsSimulator` 完全一致的架构模式，统一处理 CAPSULE 和 TRACKER 的遥测模拟。

```
com.smartlivestock.iot.application.service.TelemetrySimulator

模式:
  @Component
  @ConditionalOnProperty(name = "telemetry.simulator.enabled", havingValue = "true")
  @Scheduled(fixedRateString = "${telemetry.simulator.interval-ms:300000}")

职责:
  1. 查找所有活跃安装，按设备类型分组
  2. CAPSULE 安装 → 生成 temperature + motility + activity_index
  3. TRACKER 安装 → 生成 step_count + distance_meters
  4. 全部调用 TelemetryIngestionService.ingest()

CAPSULE 模拟数据规则:
  温度: N(38.5, 0.3), 2% 概率发烧 (39.5~41.0°C)
  蠕动频率: N(3.0, 0.5), 1% 概率偏低 (< 1.5)
  蠕动强度: N(45, 10), 1% 概率偏低 (< 20)
  活动指数: 白天 N(55, 15), 夜间 N(15, 8)

TRACKER 模拟数据规则:
  步数: 白天 N(1200, 500), 夜间 N(80, 40)
  距离: 白天 N(400, 200), 夜间 N(20, 15)
```

### 4.3 Health 上下文新增组件

#### 4.3.1 事件处理器: `SensorTelemetryEventHandler`

```
com.smartlivestock.health.infrastructure.event.SensorTelemetryEventHandler

@EventListener
@Transactional
onSensorTelemetryReceived(SensorTelemetryReceivedEvent):
  → 调用 HealthApplicationService.processTelemetry()
```

#### 4.3.2 HealthApplicationService 新增方法

在现有 `HealthApplicationService` 中新增：

```
processTelemetry(deviceId, livestockId, telemetryType, payload, recordedAt):
  switch(telemetryType):
    TEMPERATURE → ingestTemperature() → refreshSnapshot()
    MOTILITY    → ingestMotility()    → refreshSnapshot()
    ACTIVITY    → ingestActivity()     → refreshSnapshot()

ingestTemperature():
  1. 写入 temperature_logs
  2. 用 FeverAnalysisService 评估状态

ingestMotility():
  1. 写入 rumen_motility_logs
  2. 用 DigestiveAnalysisService 评估状态

ingestActivity():
  1. 写入 activity_logs
     CAPSULE 来源: activity_index 字段
     TRACKER 来源: step_count + distance_meters 字段

refreshSnapshot(livestockId):
  1. 查或建 HealthSnapshot
  2. 用最新时序数据更新 status 字段
  3. 触发 EstrusAnalysisService 评估发情评分（如有足够数据）
  4. 保存 EstrusScore（如评分有变化）
```

### 4.4 Shared 层新增

#### 4.4.1 Topics 新增常量

```java
public static final String SENSOR_TELEMETRY_RECEIVED = "sensor-telemetry-received";
```

#### 4.4.2 SpringEventPublisher 新增桥接

```java
@EventListener
public void onSensorTelemetryReceived(SensorTelemetryReceivedEvent event) {
    rocketMQEventPublisher.publish(Topics.SENSOR_TELEMETRY_RECEIVED, event);
}
```

### 4.5 配置参数

```yaml
# application.yml
telemetry:
  simulator:
    enabled: false              # 默认关闭，部署时按需开启
    interval-ms: 300000         # 5 分钟
    capsule:
      temperature:
        baseline: 38.5
        stddev: 0.3
        fever-probability: 0.02
      motility:
        freq-baseline: 3.0
        freq-stddev: 0.5
        intensity-baseline: 45.0
        intensity-stddev: 10.0
        abnormal-probability: 0.01
      activity-index:
        daytime-mean: 55.0
        nighttime-mean: 15.0
        stddev: 10.0
    tracker:
      steps:
        daytime-mean: 1200
        nighttime-mean: 80
        stddev: 300
      distance:
        daytime-mean: 400.0
        nighttime-mean: 20.0
        stddev: 150.0
```

## 5. 数据库变更

### 5.1 现有表无需修改

temperature_logs、rumen_motility_logs、activity_logs、health_snapshots、estrus_scores 表结构完全满足需求。

### 5.2 ACCELEROMETER 清理迁移

需要新增迁移清理 ACCELEROMETER 相关数据：

```sql
-- V24__remove_accelerometer_device_type.sql

-- 1. 将现有 ACCELEROMETER 设备的状态改为 DECOMMISSIONED（不删除，保留审计）
UPDATE devices SET status = 'DECOMMISSIONED' WHERE device_type = 'ACCELEROMETER';

-- 2. 收窄 CHECK 约束
ALTER TABLE devices DROP CONSTRAINT IF EXISTS chk_devices_type;
ALTER TABLE devices ADD CONSTRAINT chk_devices_type
    CHECK (device_type IN ('EAR_TAG', 'TRACKER', 'CAPSULE'));
```

DeviceType 枚举中移除 `ACCELEROMETER`（Java 代码变更）。

### 5.3 补充分区表

如需要，通过 `V25__add_future_partitions.sql` 补充 2026-09 之后的分区。

## 6. 前端对接

### 6.1 TwinOverviewPage 增强

当前 TwinOverviewPage 已调用 `dashboardControllerProvider`（显示牲畜数/告警数）。需要：

1. 新增 HealthOverview Provider，调用 `GET /farms/{farmId}/health/overview`
2. 用 API 返回的 `sceneSummary`（发热/消化/发情/疫病）替换硬编码场景卡片
3. 显示 `pendingTasks`（危急牲畜、异常告警等）

### 6.2 StatsPage 实现

从 ComingSoonPage 升级为真实统计页：

1. 新增 `StatsApiRepository`，聚合调用：
   - `GET /farms/{farmId}/dashboard/summary` → 健康汇总
   - `GET /farms/{farmId}/health/overview` → 健康趋势
   - `GET /farms/{farmId}/alerts` → 告警趋势
2. 时间范围选择器（7天/30天）
3. 图表展示：健康率、告警数、设备在线率趋势

### 6.3 空状态兜底

当 health API 返回空数据时（无传感器设备的牧场），显示友好提示：
- "当前牧场暂无传感器设备，健康分析功能需要安装瘤胃胶囊后启用"
- 提供"前往设备管理"按钮

## 7. 与 Phase 3 的衔接

Phase 3 IoT 真实接入时，只需：

1. **关闭模拟器**: `telemetry.simulator.enabled=false`
2. **对接 LoRa/NS 网关**: 网关回调 `POST /api/v1/farms/{farmId}/devices/{deviceId}/telemetry`
3. **认证**: JWT（内部服务）或 API Key（网关专用 Key）
4. **数据链路不变**: IoT 验证 → 发布事件 → Health 消费 → 分析管线

模拟器与真实设备走完全相同的 `TelemetryIngestionService` 入口，替换过程零代码改动。

## 8. 现有代码问题与修正

### 8.1 GpsSimulator 未发布事件（已有 Bug）

`GpsSimulator` 调用 `GpsLogApplicationService.logGps()` 保存 GPS 日志，但 `logGps()` 没有发布 `GpsLogUpdatedEvent`。导致 `GpsLogEventHandler`（围栏越界检测）从未触发。

**修正方案**: 在 `GpsLogApplicationService.logGps()` 保存后，发布 `GpsLogUpdatedEvent`，使围栏越界检测链路通畅。

### 8.2 ACCELEROMETER 独立设备类型（设计偏差）

`DeviceType.ACCELEROMETER` 将加速度计建模为独立设备类型，实际物理设备中加速度计是 CAPSULE 的内部传感器组件。

**修正方案**:
- V24 迁移将 ACCELEROMETER 设备标记为 DECOMMISSIONED，收窄 CHECK 约束
- DeviceType 枚举移除 ACCELEROMETER
- OpenDeviceRegisterController 注释更新

### 8.3 Open API 边界一致性

现有 `OpenDeviceRegisterController` 的设备自注册能力放在 Open API 层是合理的（给合作伙伴用的设备入网入口）。遥测上报不在 Open API 中新增端点，保持 Open API "以读为主"的设计原则。

### 8.4 种子数据坐标不一致（严重）

**问题**: V4 注册 Farm 1（主牧场）坐标为 `(28.2458, 112.8519)`，V9 种子围栏/牲畜坐标在 `(28.224~28.234, 112.932~112.944)`，两者相距约 10km。

- GpsSimulator 中心 `(28.2458, 112.8519)` 与 Farm 坐标一致，但远离围栏区域
- 模拟器生成的 GPS 点全部在围栏外 → 每个点都触发围栏越界告警（如果事件链路通畅的话）
- 或者反过来理解：围栏/牲畜的位置根本不在 Farm 1 附近

**影响**:
- GPS 轨迹与围栏位置不匹配
- 围栏越界检测会产生大量误报或漏报
- 地图上牲畜标记与围栏不在一起

**修正方案**: 统一坐标体系。将 Farm 1 的坐标修正到围栏中心附近（以围栏为基准），或反过来将围栏/牲畜坐标调整到 Farm 1 附近。建议以围栏数据为准，修正 Farm 1 坐标：

```sql
-- 修正 Farm 1 坐标到围栏区域中心
UPDATE farms SET latitude = 28.2290, longitude = 112.9380 
WHERE id = 1 AND name = '主牧场';
```

同时修正 GpsSimulator 中心坐标：

```yaml
gps:
  simulator:
    center-lat: 28.2290
    center-lng: 112.9380
```

### 8.5 GpsSimulator 应按围栏区域生成轨迹（逻辑缺陷）

**问题**: 当前 `GpsSimulator` 使用单一中心点 + 随机偏移生成所有设备的 GPS 坐标。这会导致：
- 所有牲畜的 GPS 轨迹聚集在同一个区域
- 无法模拟牲畜在各自围栏内的运动
- 牲畜可能出现在围栏外（误触发越界告警）

**修正方案**: GpsSimulator 应根据每个 Installation 对应牲畜所在的围栏，在该围栏边界内生成随机 GPS 点：

1. 通过 Installation → Livestock → farmId → Fences 获取围栏多边形
2. 在围栏多边形内生成随机点（而非全局中心 + offset）
3. 对于无围栏的牲畜，fallback 到 Farm 中心点 + 小偏移

这确保 GPS 轨迹在围栏内正常分布，偶尔因偏移越界触发真实告警。

### 8.6 种子数据时间线过旧

**问题**: 种子数据的时间线停留在 `2026-03-01 ~ 2026-04-08`。距今接近 2 个月。Health 分析查询使用 `Instant.now().minus(72h)` 等相对时间，查不到种子数据。

**修正方案**: 新增迁移 `V25__refresh_seed_timestamps.sql`，将所有时序数据（gps_logs、temperature_logs、rumen_motility_logs、activity_logs）的 `recorded_at` 批量平移到近 7 天。或者依赖模拟器重新生成数据（模拟器启用后会持续写入新数据）。

**建议策略**: 保留历史种子数据作为基线，模拟器启动后生成近期数据。Health 分析查询基于最新数据即可正常工作。如果需要演示效果，可以先运行模拟器一段时间积累数据。

### 8.7 Livestock 位置更新链路未连通

**问题**: `GpsLogEventHandler` 在围栏越界检测时会调用 `livestock.updatePosition()` 更新牲畜的最后位置。但因为事件链路未连通（§8.1），牲畜的 `last_latitude` / `last_longitude` 永远停留在种子数据的初始值。

**修正方案**: 随 §8.1 的 GpsLogUpdatedEvent 修复，此链路自动通畅。每次 GPS 日志写入后，EventHandler 会更新牲畜位置。地图上的牲畜标记会随之移动。

### 8.8 MapController 返回的牲畜位置格式

**已验证正确**: `MapController` 返回 `"lng": l.lastLongitude(), "lat": l.lastLatitude()`。前端 `MapApiRepository` 使用 `m['latitude'] ?? m['lat']` 和 `m['longitude'] ?? m['lng']` 双格式兼容。`GpsCoordinate` 的 `@JsonProperty` 注解也正确映射 `lat`/`lng`。此链路无需修正，只需上游坐标数据正确即可。

## 9. 实施任务拆分

| # | 任务 | 上下文 | 预估 |
|---|------|--------|------|
| T1 | SensorTelemetryReceivedEvent 领域事件 | IoT | 0.5h |
| T2 | TelemetryIngestionService (验证+发布事件) | IoT | 1h |
| T3 | TelemetryController (App API, JWT 认证) | IoT | 1h |
| T4 | TelemetrySimulator (CAPSULE + TRACKER) | IoT | 2h |
| T5 | Topics 常量 + SpringEventPublisher 桥接 | Shared | 0.5h |
| T6 | SensorTelemetryEventHandler | Health | 0.5h |
| T7 | HealthApplicationService.processTelemetry() | Health | 2h |
| T8 | 修正 GpsLogApplicationService 发布事件 | IoT | 0.5h |
| T9 | V24 迁移清理 ACCELEROMETER + 枚举移除 | IoT + DB | 0.5h |
| T10 | V25 修正 Farm 1 坐标 + 围栏坐标统一 | DB | 0.5h |
| T11 | 修正 GpsSimulator 按围栏区域生成轨迹 | IoT | 1.5h |
| T12 | 配置参数 application.yml | Config | 0.5h |
| T13 | 前端 TwinOverview 对接 health/overview | Flutter | 2h |
| T14 | 前端 StatsPage 实现 | Flutter | 3h |
| T15 | 端到端验证（GPS轨迹 + 围栏越界 + 地图展示 + 健康分析） | Test | 3h |

**总计: ~21.5h**
