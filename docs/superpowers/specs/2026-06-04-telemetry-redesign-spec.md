# Telemetry 通用遥测管道 重构设计规格

> 日期: 2026-06-04
> 状态: 评审中
> 替代: `2026-06-03-iot-telemetry-ingestion-design.md` 中 §4.1/§4.2 的遥测模型设计
> 关联: `2026-06-04-cross-context-decoupling-design.md` — 跨域通信走 RocketMQ + ACL

---

## 1. 真实设备数据模型

### 1.1 LoRaWAN TLV 协议（TRACKER + CAPSULE 共用）

两种设备共用同一套 TLV 报文结构：

```
同步头 (68 6B 74) + SpecialType + PackSeq + TLV 字段块
```

差异仅在于各自上报的 TLV 字段类型不同。

依据：
- `docs/LoRaWAN 牛羊追踪器上行 Payload 解析协议定义.md`
- `docs/LoRa WAN瘤胃胶囊上行Payload解析协议定义.md`

### 1.2 TRACKER TLV 字段

**当前默认上报（`TRACK_ACC_ENABLE=1, FUNC_THTB_ENABLE=0, FUNC_TAMPER_ENABLE=0`）：**

| Type ID | 字段 | 编码 | 说明 |
|---------|------|------|------|
| 0x01 | 软硬件版本 | u8 + u8 | 硬件版本 + 软件版本 |
| 0x03 | 电量 | u8 | 电量百分比 |
| 0x10 | 纬度 | u32(特殊) | 度 × 1,000,000 |
| 0x11 | 经度 | u32(特殊) | 度 × 1,000,000 |
| 0x15 | 步数 | u16 | **本周期累计步数**，上报后清零 |
| 0x0B | X 轴加速度 | s16 | |
| 0x0C | Y 轴加速度 | s16 | |
| 0x0D | Z 轴加速度 | s16 | |
| 0x39 | 运行模式配置 | 15字节结构体 | |

可选字段（固件开关控制）：0x09 温度、0x0A 湿度、0x84 防拆状态

### 1.3 CAPSULE TLV 字段

**TLV 上报字段：**

| Type ID | 字段 | 编码 | 说明 |
|---------|------|------|------|
| 0x01 | 软硬件版本 | u8 + u8 | |
| 0x4D | 温度组数据 | Count + T[0..n] × 2字节 | 多组温度点 |
| 0x8B | 电池电压 | u16 | 单位 mV |
| 0x49 | 胃动量 | u32 | |
| 0x4A | X 轴加速度 | u8 | |
| 0x4B | Y 轴加速度 | u8 | |
| 0x4C | Z 轴加速度 | u8 | |
| 0x86 | 上报周期 | u16 | 单位分钟 |

### 1.4 设备类型与遥测字段映射

| DeviceType | 遥测包含字段 | 说明 |
|------------|-------------|------|
| **TRACKER** | latitude, longitude, stepCount, accelX, accelY, accelZ, batteryLevel, hwVersion, swVersion, runModeConfig | GPS + 加速度计 + 步数 |
| **CAPSULE** | temperatures[7], gastricMotility, batteryVoltage, accelX, accelY, accelZ | 7 温度点 + 胃动量 + 加速度 |
| **EAR_TAG** | (Phase 3) RFID | 无遥测上报 |

### 1.5 现有 Health 模型 vs 真实协议对比

| 现有字段 | 真实协议对应 | 差异 |
|---------|-------------|------|
| `TemperatureLog.temperature` (单个°C) | 7 个温度点（压缩编码） | 需解码后展开为 7 条记录 |
| `RumenMotilityLog.frequency` (蠕动频率) | `gastricMotility` (胃动量, u32) | **字段含义不同**：frequency 是次数/分，gastricMotility 是原始传感器值 |
| `RumenMotilityLog.intensity` (蠕动强度) | 协议中无直接对应 | 可能从 gastricMotility 推导 |
| `ActivityLog.activityIndex` (0-100) | 协议中无此字段 | 应从加速度数据 (accelX/Y/Z) 推导 |
| `ActivityLog.stepCount` | TRACKER 专用 (0x15) | CAPSULE 无步数 |
| `ActivityLog.distanceMeters` | 协议中无此字段 | 应从步数推算 (step × 0.3~0.6m) |

**设计决策：**

1. **温度**：payload 解码后产生 7 个温度点，每个点作为独立 TemperatureLog 写入，recordedAt 按采样间隔递推
2. **胃动量**：`gastricMotility` 作为原始值写入 `RumenMotilityLog.frequency`（字段复用，临时 /100000 映射，待协议明确后修正）
3. **activityIndex**：从 accelX/Y/Z 在平台侧计算推导（或由模拟器直接生成），暂不改动 ActivityLog 表结构

---

## 2. 架构设计

### 2.1 数据流总览（符合跨域解耦规格）

```
┌──────────────────────────────────────────────────────────────────────┐
│ IoT 上下文                                                           │
│                                                                       │
│  TRACKER / CAPSULE (LoRaWAN, TLV protocol)                           │
│    → LoRa 网络 → NS 平台 (Network Server)                            │
│                                                                       │
│  ingest(deviceId, readings, recordedAt):                              │
│    1. 验证 device + installation                                     │
│    2. 通过 RanchQueryPort (ACL) 解析 livestockId / farmId            │
│    3. 从 readings 提取运维字段，更新 Device                           │
│    4. TRACKER: 提取 GPS → GpsLogApplicationService.logGps()          │
│    5. 发布 TelemetryReceivedEvent(readings Map 透传)                  │
│         → SpringEventPublisher → RocketMQ topic "telemetry-received" │
└──────────────────────────────────────────────────────────────────────┘
                                    │ RocketMQ
                                    ▼
┌──────────────────────────────────────────────────────────────────────┐
│ Health 上下文                                                         │
│                                                                       │
│  TelemetryEventConsumer (@RocketMQMessageListener)                   │
│    → 反序列化 TelemetryReceivedEvent                                  │
│    → HealthApplicationService.processTelemetry()                     │
│                                                                       │
│  CAPSULE readings:                                                    │
│    → temperatures[7] → 7 条 TemperatureLog                           │
│    → gastricMotility → RumenMotilityLog.frequency                    │
│    → accelX/Y/Z → ActivityLog                                        │
│                                                                       │
│  TRACKER readings:                                                    │
│    → stepCount, distanceMeters → ActivityLog                         │
│                                                                       │
│  → refreshSnapshot + triggerEstrusScoring                            │
│  → 通过 RanchCommandPort (ACL) 创建告警                              │
└──────────────────────────────────────────────────────────────────────┘
```

### 2.2 TelemetryReceivedEvent

```java
public class TelemetryReceivedEvent extends DomainEvent {
    private final Long deviceId;
    private final Long livestockId;
    private final Long farmId;
    private final DeviceType deviceType;
    private final Map<String, Object> readings;
    private final Instant recordedAt;
}
```

**readings Map key 命名约定：**

| Key | 设备类型 | 类型 | 说明 |
|-----|---------|------|------|
| `batteryLevel` | TRACKER | Integer | 电量 0-100 |
| `batteryVoltage` | CAPSULE | Integer | 电池电压 mV |
| `hwVersion` | ALL | Integer | 硬件版本 |
| `swVersion` | ALL | Integer | 软件版本 |
| `latitude` | TRACKER | BigDecimal | 纬度 |
| `longitude` | TRACKER | BigDecimal | 经度 |
| `stepCount` | TRACKER | Integer | 本周期累计步数 |
| `accelX` | TRACKER(s16) / CAPSULE(u8) | Integer | X 轴加速度 |
| `accelY` | TRACKER(s16) / CAPSULE(u8) | Integer | Y 轴加速度 |
| `accelZ` | TRACKER(s16) / CAPSULE(u8) | Integer | Z 轴加速度 |
| `temperatures` | CAPSULE | List\<BigDecimal\> | 解码后 7 个温度点 (°C) |
| `gastricMotility` | CAPSULE | Long | 胃动量原始值 (u32) |

### 2.3 GPS 链路整合

TRACKER 的 telemetry 包含 GPS → `TelemetryIngestionService` 提取后调 `GpsLogApplicationService.logGps()`（同上下文内调用，无需 ACL）。GpsSimulator 保留但默认关闭。

### 2.4 跨域通信（符合解耦规格）

| 调用方 | 被调用方 | 方式 | 说明 |
|--------|---------|------|------|
| IoT → Health | telemetry-received | RocketMQ | 遥测事件 |
| IoT → Ranch | `RanchQueryPort` (ACL) | 查询端口 | 根据 livestockId 查 farmId |
| IoT → Identity | `IdentityQueryPort` (ACL) | 查询端口 | Simulat 查 Farm 中心坐标 |
| Health → Ranch | `RanchQueryPort` + `RanchCommandPort` (ACL) | 查询+命令端口 | 查牲畜信息、创建告警 |

---

## 3. TelemetrySimulator 仿真模型

### 3.1 SimulationState

```java
class SimulationState {
    BigDecimal tempBaselineOffset;   // ±0.3°C 个体偏移
    BigDecimal motilityBaseline;     // 2.5–3.5
    boolean abnormalTemp;            // 5% 概率
    boolean abnormalMotility;        // 3% 概率
    boolean inEstrus;                // 5% 雌性
    int lastStepCount;
    int initialBattery;
}
```

### 3.2 TRACKER 仿真规则

```
readings:
  latitude/longitude: 通过 RanchQueryPort 获取围栏，围栏内随机点
  stepCount: 白天 800–2500, 夜间 50–300, 发情 ×2.5 (u16, 周期累计)
  accelX/Y/Z: 基于活动量的合理值 (s16)
  batteryLevel: 缓慢衰减 (0-100)
```

### 3.3 CAPSULE 仿真规则

```
readings:
  temperatures: 生成 7 个温度点
    baseTemp = 38.5 + offset + (abnormal ? +0.8~2.0 : 0) + noise(±0.15)
    deltas = small_noise(±0.1°C) × 6
  gastricMotility:
    baseline = 500000 + offset(±100000)
    abnormal: baseline × 0.2
    noise: ±50000
  accelX/Y/Z: u8 合理值
  batteryVoltage: 2800~3600 mV, 缓慢衰减
```

### 3.4 昼夜节律

```java
double hourFactor(int hour) {
    return (hour >= 6 && hour <= 20) ? 1.0 : 0.2;
}
```

---

## 4. Health 消费端变更

### 4.1 RocketMQ Consumer（替代 @EventListener）

```java
// health/infrastructure/mq/TelemetryEventConsumer.java
@Component
@RocketMQMessageListener(topic = "telemetry-received", consumerGroup = "health-telemetry-consumer")
public class TelemetryEventConsumer implements RocketMQListener<String> {
    // 反序列化 TelemetryReceivedEvent
    // 调 HealthApplicationService.processTelemetry()
}
```

### 4.2 CAPSULE 处理

```java
List<BigDecimal> temperatures = (List<BigDecimal>) readings.get("temperatures");
Long gastricMotility = (Long) readings.get("gastricMotility");

if (temperatures != null) {
    for (int i = 0; i < temperatures.size(); i++) {
        ingestTemperature(deviceId, livestockId, temperatures.get(i),
                           recordedAt.minus(Duration.ofMinutes(5L * (temperatures.size() - 1 - i))));
    }
}

if (gastricMotility != null) {
    ingestMotility(deviceId, livestockId,
                    new BigDecimal(gastricMotility).divide(new BigDecimal("100000"), 2, RoundingMode.HALF_UP),
                    null, recordedAt);
}
```

### 4.3 TRACKER 处理

不变，从 readings 提取 `stepCount` / `distanceMeters`。

---

## 5. 变更范围

### 5.1 需要修改的文件

| 文件 | 变更 |
|------|------|
| `TelemetryReceivedEvent` (新建) | 替换 SensorTelemetryReceivedEvent，Map 透传 + DeviceType |
| `SensorTelemetryReceivedEvent` (删除) | 删除 |
| `TelemetryIngestionService` | 移除分支；新增运维更新 + GPS 提取；LivestockRepository → RanchQueryPort |
| `TelemetrySimulator` | 重写为状态仿真；跨域 Repo → ACL 端口 |
| `Topics.java` | 常量重命名 |
| `SpringEventPublisher` | 事件类型更新 |
| `SensorTelemetryEventHandler` (删除) | 由 TelemetryEventConsumer 替代 |
| `TelemetryEventConsumer` (新建) | RocketMQ Consumer，Health 上下文 |
| `HealthApplicationService.processTelemetry()` | 签名改为接收 readings Map；Ranch Repo → ACL 端口 |
| `HealthApplicationServiceTelemetryTest` | 适配 |
| `application.yml` | gps.simulator.enabled 默认 false |

### 5.2 需要新建的 ACL 端口（IoT 上下文）

| 端口 | 方法 | 替代 |
|------|------|------|
| `iot/domain/port/RanchQueryPort` | findLivestockById, findFencesByFarmId | 直接引用 Ranch Repo |
| `iot/domain/port/IdentityQueryPort` | findFarmById | 直接引用 Identity Repo |
| `iot/infrastructure/acl/RanchQueryPortImpl` | 进程内调用 Ranch Repo | — |
| `iot/infrastructure/acl/IdentityQueryPortImpl` | 进程内调用 Identity Repo | — |
| `iot/domain/port/dto/LivestockInfo` | record: id, farmId, code, gender | — |
| `iot/domain/port/dto/FenceInfo` | record: id, name, coordinates | — |
| `iot/domain/port/dto/FarmInfo` | record: id, centerLat, centerLng | — |

### 5.3 需要新建的 ACL 端口（Health 上下文）

| 端口 | 方法 | 替代 |
|------|------|------|
| `health/domain/port/RanchQueryPort` | findLivestockById | 直接引用 Ranch Repo |
| `health/domain/port/RanchCommandPort` | createAlert | 直接引用 AlertRepo |
| `health/infrastructure/acl/RanchQueryPortImpl` | 进程内调用 Ranch Repo | — |
| `health/infrastructure/acl/RanchCommandPortImpl` | 进程内调用 Ranch Repo | — |

### 5.4 不需要修改

| 文件 | 原因 |
|------|------|
| GpsLogApplicationService | 接口不变（同上下文内调用） |
| GpsSimulator | 保留，默认关闭 |
| Health 分析 Service | 分析逻辑不变 |
| DB 表结构 | 无新迁移 |
| TelemetryController | HTTP API 契约不变 |
