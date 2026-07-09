# Phase 3 实施设计：中台（agentic-middle-platform）对接迁移 + 设备健康管理 + 数据采集

**Date**: 2026-07-08
**Status**: ✅ 已实施（2026-07-10 部署验证通过 12/12）
**前置条件**: [Phase C 中台对接设计（整合版）](2026-07-07-phase-c-blade-device-integration.md) PoC 已验证
**影响范围**: IoT 上下文（Device 模型 + 表结构）、datagen 上下文（合成数据适配）、Health 上下文（遥测 ingestion）

---

## 1. 总览

### 1.1 背景

Phase C PoC 已验证中台（agentic-middle-platform，Nacos 服务名 hkt-blade-*）全链路可通（OAuth2 换票 → 设备注册 → 遥测采集）。本设计是将 PoC 成果正式迁移到 `smart-livestock-server`，并完成三个方面的增强：

| # | 主题 | 核心问题 |
|---|------|---------|
| A | 设备健康管理 | 当前 devices 表只有 battery_level，缺 rssi/snr/gateway/anti-disassembly 等运维指标 |
| B | 设备入网用户旅程 | 需从"纯本地注册"升级为"中台同步注册"全流程 |
| C | datagen + 数据存储 | datagen 合成数据需对齐 中台真实上报格式，设备时序数据需独立存储 |

### 1.2 现有表结构盘点

**devices（V3 创建，当前状态）：**

```sql
CREATE TABLE devices (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    device_code VARCHAR(50) NOT NULL UNIQUE,
    device_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'INVENTORY',
    battery_level INTEGER,
    firmware_version VARCHAR(50),
    dev_eui VARCHAR(16),
    last_online_at TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMP, updated_at TIMESTAMP
);
```

**缺失的字段**（中台已上报但 smart-livestock 未存储）：

| 中台 字段 | 类型 | 用途 |
|-----------|------|------|
| `rssi` | int (dBm) | LoRa 信号强度 |
| `snr` | numeric | 信噪比 |
| `lastGateway` | varchar | 网关 ID |
| `antiDisassemblyStatus` | int | 防拆卸状态 |
| `platform_device_id` | bigint | 中台 侧设备 ID（19 位 snowflake ID） |
| `software` / `hardware` | varchar | 软硬件版本（当前只有 firmware_version） |
| `last_telemetry_synced_at` | timestamp | 轮询同步游标 |

**现有遥测时序表（Health 上下文）：**
- `temperature_logs`（CAPSULE，月分区）
- `rumen_motility_logs`（CAPSULE，月分区）
- `activity_logs`（TRACKER 步数 + ACCELEROMETER 活动指数，月分区）
- `gps_logs`（TRACKER 定位）

**缺失的表**：设备运维指标时序表（battery 趋势、信号质量趋势），当前没有按设备维度记录运维指标的时序表。

### 1.3 中台真实数据维度（CATTLE_TRACKER 实测）

| 分类 | 字段 | 说明 |
|------|------|------|
| 运维 | battery, rssi, snr, lastGateway | 设备可维护性指标 |
| 运维 | onlineStatus, lastActiveTime, offlineDuration | 在线状态 |
| 定位 | latitude, longitude | GPS 坐标（scale=1e-06） |
| 活动 | stepNumber | 累计步数 |
| 安全 | antiDisassemblyStatus | 防拆卸告警 |
| 加速度 | x/y/zAxisDirectionAccelerationValue | 三轴加速度原始值（LIS3DH uint16，需 §5.6 换算为 g 值 → 合矢量 → 活动分类） |
| 配置 | workMode, fixedReportInterval, segment1-2 时间段 | 工作模式 |
| 版本 | software, hardware | 软硬件版本 |

---

## 2. 设备模型扩展（表结构 + 领域模型）

### 2.1 devices 表扩展

```sql
ALTER TABLE devices
    ADD COLUMN IF NOT EXISTS platform_device_id BIGINT,
    ADD COLUMN IF NOT EXISTS rssi INTEGER,
    ADD COLUMN IF NOT EXISTS snr NUMERIC(4,1),
    ADD COLUMN IF NOT EXISTS last_gateway VARCHAR(128),
    ADD COLUMN IF NOT EXISTS anti_disassembly_status INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS software_version VARCHAR(50),
    ADD COLUMN IF NOT EXISTS hardware_version VARCHAR(50),
    ADD COLUMN IF NOT EXISTS work_mode VARCHAR(20),
    ADD COLUMN IF NOT EXISTS last_telemetry_synced_at TIMESTAMP;

CREATE UNIQUE INDEX IF NOT EXISTS idx_devices_platform_device_id
    ON devices (platform_device_id) WHERE platform_device_id IS NOT NULL;
```

> **dev_eui vs platform_device_id 区别**：
> - `dev_eui`（现有字段，VARCHAR(16)）= 中台的 `deviceIdentifier`，是 LoRaWAN 设备硬件标识（如 `0095690600028ea6`），注册时**传入**中台
> - `platform_device_id`（新增字段，**BIGINT**）= 中台的 `deviceId`，是 中台数据库主键（如 `2074666288126443520`），注册成功后**返回**，后续所有 中台 API 查询用
>
> **中台 deviceId 类型兼容**：中台当前将 deviceId 实现为 VARCHAR（已知 bug，对方承诺后续改为 BIGINT）。中台的 deviceId 实际是 19 位纯数字 snowflake ID，完全在 bigint 范围内。smart-livestock 侧采用分层策略：
> - **DB 层**：`BIGINT` — 遵循 smart-livestock 设计规范（主键/外键/引用 ID 统一 bigint）
> - **Feign DTO 层**：`String` — 匹配 中台当前 API（JSON 中是字符串）
> - **边界转换**：Application Service 中 `Long.parseLong(deviceIdStr)` 接收 / `String.valueOf(deviceIdLong)` 发送
> - **中台修复后**：只需把 Feign DTO 的 String 改为 Long，删除转换代码，DB 和领域模型零迁移

**字段说明：**

| 字段 | 类型 | 来源 | 更新时机 |
|------|------|------|---------|
| `platform_device_id` | BIGINT | 中台 registerDevice 返回 | 设备注册到 中台 时写入，不可变。DB 用 BIGINT 遵循本地规范，Feign DTO 用 String 匹配 中台 API，边界转换 |
| `rssi` | INTEGER | 中台遥测 / report-record | 每次轮询同步更新 |
| `snr` | NUMERIC(4,1) | 中台遥测 | 每次轮询同步更新 |
| `last_gateway` | VARCHAR(128) | 中台遥测 | 每次轮询同步更新 |
| `anti_disassembly_status` | INTEGER | 中台遥测 | 非零时触发防拆卸告警 |
| `software_version` | VARCHAR(50) | 中台物模型 | 固件升级时更新 |
| `hardware_version` | VARCHAR(50) | 中台物模型 | 设备注册时写入 |
| `work_mode` | VARCHAR(20) | 中台物模型 | 设备配置变更时更新 |
| `last_telemetry_synced_at` | TIMESTAMP | 轮询 Job 内部 | 每次轮询完成后更新（游标） |

> `firmware_version` 保留不变（向后兼容），新增 `software_version` / `hardware_version` 对齐 中台字段名。

### 2.2 新增：device_telemetry_logs 表（设备运维指标时序）

设备运维指标需要独立于牲畜健康数据存储，用于电池趋势分析、信号质量监控、设备寿命预测。

```sql
CREATE TABLE device_telemetry_logs (
    id BIGSERIAL,
    device_id BIGINT NOT NULL REFERENCES devices(id),
    tenant_id BIGINT NOT NULL,
    battery_level INTEGER,
    rssi INTEGER,
    snr NUMERIC(4,1),
    gateway_id VARCHAR(128),
    anti_disassembly_status INTEGER,
    step_number INTEGER,
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    accel_x_raw INTEGER,           -- LIS3DH 原始 uint16
    accel_y_raw INTEGER,
    accel_z_raw INTEGER,
    accel_x_g NUMERIC(6,3),         -- 换算后 g 值（见 §5.6）
    accel_y_g NUMERIC(6,3),
    accel_z_g NUMERIC(6,3),
    accel_magnitude_g NUMERIC(6,3), -- 合矢量 sqrt(x²+y²+z²)
    motion_intensity NUMERIC(4,2),  -- 运动强度 = (magnitude_g - 1) × 100
    activity_class VARCHAR(10),     -- rest / light / active / intense
    roll_degrees NUMERIC(5,2),      -- 绕 X 轴倾角（需重力分量）
    pitch_degrees NUMERIC(5,2),     -- 绕 Y 轴倾角
    report_time TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, report_time)
) PARTITION BY RANGE (report_time);
```

**设计决策：**
- **按月分区**：与 temperature_logs / activity_logs 一致，采样间隔 ~30min（中台上报频率）
- **device-centric**：以 device_id 为核心索引，区别于 activity_logs 的 livestock_id 为核心
- **step_number 存原始累计值**：activity_logs 存的是差值（增量步数），device_telemetry_logs 存 中台上报的原始累计值，增量在 ingestion 时计算

**索引：**
```sql
CREATE INDEX idx_dtl_device_time ON device_telemetry_logs(device_id, report_time DESC);
CREATE INDEX idx_dtl_tenant_time ON device_telemetry_logs(tenant_id, report_time DESC);
```

### 2.2a alerts 表扩展（设备告警）

设备告警（防拆卸/低电量）需要关联 device_id，现有 alerts 表只有 livestock_id 和 fence_id。

```sql
ALTER TABLE alerts
    ADD COLUMN IF NOT EXISTS device_id BIGINT REFERENCES devices(id);
CREATE INDEX IF NOT EXISTS idx_alerts_device_id ON alerts(device_id);
```

> alerts 表 CHECK 约束（`chk_alerts_type`）需同步更新，新增 `DEVICE_TAMPER` 和 `DEVICE_LOW_BATTERY`。

### 2.3 Device 领域模型扩展

```java
public class Device extends AggregateRoot {
    // --- 现有字段 ---
    private String deviceCode;
    private DeviceType deviceType;
    private DeviceStatus status;
    private Integer batteryLevel;
    private String firmwareVersion;
    private String devEui;
    private Instant lastOnlineAt;

    // --- 新增：中台对接 ---
    private Long agenticPlatformDeviceId;  // BIGINT (中台当前返回 String，边界转换为 Long)

    // --- 新增：运维指标（实时快照） ---
    private Integer rssi;
    private BigDecimal snr;
    private String lastGateway;
    private Integer antiDisassemblyStatus;
    private String softwareVersion;
    private String hardwareVersion;
    private String workMode;
    private Instant lastTelemetrySyncedAt;

    /**
     * Sync device operational status from 中台 telemetry.
     * Called by AgenticPlatformTelemetrySyncJob after polling report-record/page.
     */
    public void syncAgenticPlatformStatus(Integer rssi, BigDecimal snr, String gateway,
                                Integer battery, Integer antiDisassembly,
                                String software, String hardware, String workMode,
                                Instant reportTime, Instant syncedAt) {
        this.rssi = rssi;
        this.snr = snr;
        this.lastGateway = gateway;
        this.batteryLevel = battery;
        this.antiDisassemblyStatus = antiDisassembly;
        this.softwareVersion = software;
        this.hardwareVersion = hardware;
        this.workMode = workMode;
        this.lastOnlineAt = reportTime;
        this.lastTelemetrySyncedAt = syncedAt;
    }

    /**
     * Bind 中台 deviceId after 中台 registration.
     */
    public void bindAgenticPlatformDeviceId(Long agenticPlatformDeviceId) {
        if (this.agenticPlatformDeviceId != null && !this.agenticPlatformDeviceId.equals(agenticPlatformDeviceId)) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                "Device already bound to different 中台 deviceId");
        }
        this.agenticPlatformDeviceId = agenticPlatformDeviceId;
    }
}
```

---

## 3. 设备健康管理设计

### 3.1 设备健康评分模型

> **命名注意**：feature_gate 中已有 `health_score` key（牲畜健康评分，见 V31 seed）。本文档设计的"设备健康评分"命名为 `device_health_score` 避免冲突。

基于 中台实时上报的运维指标，计算设备综合健康分（0-100）。

| 维度 | 权重 | 评分规则 | 数据源 |
|------|------|---------|--------|
| 电量健康 | 30% | battery ≥ 80 → 100；50-79 → 70；20-49 → 40；< 20 → 10 | battery |
| 信号质量 | 25% | rssi ≥ -50 → 100；-70~-51 → 80；-90~-71 → 50；< -90 → 20 | rssi + snr |
| 在线状态 | 25% | lastActiveTime < 1h → 100；< 6h → 70；< 24h → 40；> 24h → 10 | onlineStatus + lastActiveTime |
| 防拆卸 | 10% | antiDisassembly=0 → 100；≠ 0 → 0（告警） | antiDisassemblyStatus |
| 数据上报 | 10% | 最近 3 个周期都有上报 → 100；缺 1 个 → 60；缺 2+ → 20 | device_telemetry_logs |

**健康等级：**
- 80-100：HEALTHY（绿）
- 60-79：WARNING（黄）
- < 60：CRITICAL（红）

### 3.2 设备健康展示

前端设备管理页面新增"设备健康"卡片，展示：
- 综合健康分 + 等级颜色
- 电量趋势图（最近 7 天，from device_telemetry_logs）
- 信号强度趋势图（RSSI + SNR）
- 网关信息（lastGateway + 切换历史）
- 最近上报时间 + 上报频率

### 3.3 防拆卸告警联动

当 `antiDisassemblyStatus ≠ 0` 时：
1. TelemetryIngestionService.ingest() 在 `detectDeviceAlerts()` 中检测到异常值（仅 source=AGENTIC_PLATFORM 时）
2. 内联创建 `DEVICE_TAMPER` (CRITICAL) 告警（对齐 GpsLogEventConsumer 模式，不走独立 AlertConsumer）
3. 去重：检查该设备是否已有同类型 ACTIVE 告警，有则跳过
4. 告警推送到 Mobile App + B 端管理后台

同样，`battery < 20` 时内联创建 `DEVICE_LOW_BATTERY` (WARNING) 告警。

> **告警创建模式**：对齐现有 `GpsLogEventConsumer.createAlertIfNeeded()`，在 ingest() 中直接调 `alertRepository.save()`。需要在 `alerts` 表新增 `device_id BIGINT` 列（现有表无此列）。

---

## 4. 设备入网用户旅程（中台集成）

### 4.1 现有流程（无中台）

```
采购设备 → 手动录入 deviceCode + DevEUI → INVENTORY → 激活 → ACTIVE → 安装到牲畜
```

### 4.2 新流程（中台集成）

```
① 采购设备（中台已注册 CATTLE_TRACKER）
    ↓
② smart-livestock 录入设备（输入 DevEUI，即 LoRaWAN 设备硬件标识）
    ↓
③ 中台 License 校验（GET /device-license/control/by-sn）
    ├─ 有效 → 继续
    └─ 无效 → 提示"设备未授权或 SN 错误"
    ↓
④ 中台 设备注册（POST /device/lifecycle/registerDevice）
    │   入参 deviceIdentifier = DevEUI
    ├─ 成功 → 获取 中台 deviceId，写入本地 devices.platform_device_id
    └─ 已存在 → 中台返回 existedDevices，同步 agenticPlatformDeviceId
    ↓
⑤ 本地设备创建（status=INVENTORY，agenticPlatformDeviceId 已绑定）
    ↓
⑥ 设备激活（activate → ACTIVE）
    ↓
⑦ 安装到牲畜（Installation 创建）
    ↓
⑧ 遥测采集启动（AgenticPlatformTelemetrySyncJob 按游标拉取该设备的 report-record）
    ↓
⑨ 数据流入 TelemetryIngestionService → Health 分析引擎
```

### 4.3 用户旅程状态机

```
                  中台 License                 中台 Register(deviceIdentifier=DevEUI)    activate           install
采购设备 ──────────────────────→ LICENSE_VERIFIED ──────────────→ REGISTERED ──────────→ INVENTORY ──────────→ ACTIVE
                  (GET by-sn)                   (POST register, 返回agenticPlatformDeviceId)         (local)            (Installation)
                       │                              │
                       │ isValid=false                │ already exists
                       ↓                              ↓
                   入网失败                      同步 agenticPlatformDeviceId
                                                 (从 existedDevices 取)
```

### 4.4 批量入网

支持通过 CSV/Excel 批量导入设备 SN 列表，调 中台 `batchRegisterDevices` 一次性注册：
- 成功设备：写入本地 devices + agenticPlatformDeviceId
- 已存在设备：从 existedDevices 同步 agenticPlatformDeviceId
- 失败设备：导出错误报告（含 reason）

---

## 5. 数据采集与存储设计

### 5.1 数据流架构 — 方案 B：TelemetryIngestionService 统一入口

**架构决策**：AgenticPlatformTelemetrySyncJob **不直接写 DB**，而是解析 decodeData、组装标准 readings Map，通过 `TelemetryIngestionService.ingest()` 统一入站。TelemetryIngestionService 从当前的"透传模式"升级为"分流+透传模式"，所有数据来源（中台轮询 / datagen 合成 / HTTP 直传）都经过同一个 ingest() 方法。

```
中台 report-record/page（每 30min 一条）
    ↓
AgenticPlatformTelemetrySyncJob（定时轮询）
    ↓ 解析 decodeData → 组装标准 readings Map（见 §6.2 规范）
    ↓
TelemetryIngestionService.ingest(deviceId, readings, recordedAt, source=AGENTIC_PLATFORM)
    ↓
    ├─ ① updateDeviceRuntimeStatus（rssi/snr/gateway/battery/antiDisassembly）
    ├─ ② logDeviceTelemetry → device_telemetry_logs（运维指标时序）
    ├─ ③ extractAndLogGps → gps_logs（GPS 定位）
    ├─ ④ 告警检测（仅 source=AGENTIC_PLATFORM 时触发）
    │       antiDisassembly ≠ 0 → 内联创建 DEVICE_TAMPER 告警
    │       battery < 20 → 内联创建 DEVICE_LOW_BATTERY 告警
    ├─ ⑤ publishEvent(TelemetryReceivedEvent) → 透传 readings → RocketMQ
    │       ↓
    │   HealthApplicationService.processTelemetry()
    │       ↓
    │   activity_logs / temperature_logs（牲畜健康数据）
    └─ ⑥ 更新 devices.last_telemetry_synced_at（游标推进）

datagen（SynthesisRunner）
    ↓
TelemetryIngestionPort.ingest(deviceId, readings, recordedAt)
    ↓
TelemetryIngestionService.ingest(deviceId, readings, recordedAt, source=DATAGEN)
    ↓
    （同上流程，source=DATAGEN 时跳过告警检测④，其余逻辑一致）
```

#### 配套设计要求（D1-D7）

| # | 设计要求 | 影响范围 |
|---|---------|---------|
| D1 | `ingest()` 签名新增 `source` 参数（枚举：AGENTIC_PLATFORM / DATAGEN / HTTP），区分数据来源 | TelemetryIngestionService + TelemetryIngestionPort |
| D2 | AgenticPlatformTelemetrySyncJob 组装 readings Map 时使用与 datagen 一致的标准字段名（见 §6.2） | AgenticPlatformTelemetrySyncJob |
| D3 | `logDeviceTelemetry()` 在 source=DATAGEN 时也写入（datagen 的运维指标同步归档到 device_telemetry_logs） | TelemetryIngestionService |
| D4 | 告警检测（防拆卸/低电量）仅在 source=AGENTIC_PLATFORM 时触发（datagen 模拟的数据不产生真实告警） | TelemetryIngestionService |
| D5 | datagen 的 `SynthesisService.generate()` 需要发送规范化的 readings（统一字段名） | SynthesisService |
| D6 | AgenticPlatformTelemetrySyncJob 引用 `TelemetryIngestionService`，必须在 smart-livestock-server 模块内 | 模块结构 |
| D7 | `TelemetryIngestionPort.ingest()` 也需加 `source` 参数（datagen 传入 DATAGEN） | TelemetryIngestionPort 接口 |

### 5.2 decodeData 解析规范

中台 `report-record/page` 的 `decodeData` 是嵌套 JSON 字符串：

```
decodeData
  └── properties
       └── properties
            ├── battery: 100
            ├── latitude: 0
            ├── longitude: 0
            ├── stepNumber: 3
            ├── workMode: 0
            ├── xAxisDirectionAccelerationValue: 65383
            ├── yAxisDirectionAccelerationValue: 65383
            └── zAxisDirectionAccelerationValue: 64922
```

解析代码（Java）：
```java
public record AgenticPlatformReportData(
    Integer battery,
    BigDecimal latitude,
    BigDecimal longitude,
    Integer stepNumber,
    Integer workMode,
    Integer accelXRaw,   // LIS3DH 原始 uint16
    Integer accelYRaw,
    Integer accelZRaw
) {
    public static AgenticPlatformReportData fromDecodeData(String decodeData) {
        JsonNode root = objectMapper.readTree(decodeData);
        JsonNode props = root.path("properties").path("properties");
        return new AgenticPlatformReportData(
            props.path("battery").asInt(),
            props.path("latitude").decimalValue(),
            props.path("longitude").decimalValue(),
            props.path("stepNumber").asInt(),
            props.path("workMode").asInt(),
            props.has("xAxisDirectionAccelerationValue") ? props.path("xAxisDirectionAccelerationValue").asInt() : null,
            props.has("yAxisDirectionAccelerationValue") ? props.path("yAxisDirectionAccelerationValue").asInt() : null,
            props.has("zAxisDirectionAccelerationValue") ? props.path("zAxisDirectionAccelerationValue").asInt() : null
        );
    }
}
```

### 5.3 stepNumber 增量计算（含边界处理）

中台上报的 `stepNumber` 是**累计值**（单调递增），activity_logs 需要的是**周期增量**。增量计算在 TelemetryIngestionService 内部完成（ingest 流程的分流步骤之一）。

#### 三种边界处理

| 场景 | 检测条件 | 处理 | 写入 activity_logs |
|------|---------|------|-------------------|
| **首次上报**（无历史） | device_telemetry_logs 中无该设备记录 | 只记录基线到 device_telemetry_logs，**不写** activity_logs | ❌ |
| **正常增量** | 当前 > 上次 | delta = 当前 - 上次 | ✅ step_count = delta |
| **回退/重置** | 当前 ≤ 上次（设备重启） | 重置基线为当前值，记录 warn 日志，**丢弃此周期** | ❌ |

#### 计算逻辑

```
last_step = SELECT step_number FROM device_telemetry_logs
            WHERE device_id = ? ORDER BY report_time DESC LIMIT 1

if last_step is null:
    # 首次上报：不写 activity_logs，只记录到 device_telemetry_logs（作为基线）
    skip activity_log
elif current_step > last_step:
    delta = current_step - last_step
    activity_logs.step_count = delta  # 写入增量
else:
    # 设备重启或异常回退
    log.warn("stepNumber regression: last={}, current={}, device={}", last_step, current_step, deviceId)
    skip activity_log  # 丢弃此周期，不写 activity_logs
```

> 查询范围：按 `device_id` 查 `device_telemetry_logs` 的最后一条记录（不是 activity_logs），因为 device_telemetry_logs 存原始累计值，是准确的基线来源。

### 5.4 GPS 坐标处理

中台 `latitude`/`longitude` 的物模型 `specs.scale = 1e-06`，实际值为浮点数（如 `28245800` 表示 `28.2458°`）。

但实测数据显示值为 `0`（设备未定位），需确认：
- 如果 中台返回的是原始整数（需 ×1e-06），还是已转换的浮点数
- 如果是整数：`lat = rawValue * 1e-6`
- 如果是浮点数：直接使用

> PoC 中 中台返回 `latitude: 0`，无法区分。等设备移动到 GPS 信号区后确认。


### 5.5 消息驱动同步设计（方案 3：RocketMQ Dispatcher + Worker）

**架构决策**：采用消息驱动模式替代简单定时轮询。Dispatcher 定时扫描设备清单并分发同步任务到 RocketMQ，Worker 并发消费执行实际数据拉取。支持水平扩展，目标 10000 台设备。

#### 5.5.1 架构

```
AgenticPlatformSyncDispatcher（@Scheduled，每 5min）
  │  查 devices WHERE platform_device_id IS NOT NULL AND status = 'ACTIVE'
  │  按 1000 条分批
  │  批量发送到 RocketMQ topic: device-telemetry-sync
  │  每条消息 = { deviceId, scheduledAt }
  ▼
RocketMQ topic: device-telemetry-sync
  │  consumerGroup: platform-sync-worker
  │  多实例消费 → 自动负载均衡
  ▼
AgenticPlatformSyncWorker（@RocketMQMessageListener，每实例多线程）
  │  收到 { deviceId, scheduledAt }
  │  → AgenticPlatformTelemetrySyncJob.syncDevice(deviceId)
  │      = 拉 report-record/page（按游标）→ 解析 decodeData → 组装 readings → ingest(source=AGENTIC_PLATFORM)
  │  → 成功：ACK
  │  → 失败：RocketMQ 自动重投（默认 16 次指数退避）
  ▼
TelemetryIngestionService.ingest()（§6.3 统一入口）
```

#### 5.5.2 topic 与消息格式

**Topics.java 注册：**

```java
/** 设备遥测同步任务分发（Dispatcher → Worker）。 */
public static final String DEVICE_TELEMETRY_SYNC = "device-telemetry-sync";
```

**消息 DTO：**

```java
public record DeviceTelemetrySyncTask(Long deviceId, Instant scheduledAt) {}
```

序列化为 JSON，单条消息约 60 字节，10000 条 ≈ 600KB，单批发送无压力。

#### 5.5.3 Dispatcher 设计

```java
@Component
@RequiredArgsConstructor
@Slf4j
public class AgenticPlatformSyncDispatcher {

    private final DeviceRepository deviceRepository;
    private final RocketMQTemplate mqTemplate;
    private static final int BATCH_SIZE = 1000;

    @Scheduled(fixedDelay = 300_000)  // 5min
    public void dispatch() {
        int offset = 0;
        int total = 0;
        while (true) {
            List<Long> deviceIds = deviceRepository.findActivePlatformDeviceIds(offset, BATCH_SIZE);
            if (deviceIds.isEmpty()) break;

            Instant scheduledAt = Instant.now();
            List<Message<DeviceTelemetrySyncTask>> messages = deviceIds.stream()
                    .map(id -> MessageBuilder.withPayload(
                            new DeviceTelemetrySyncTask(id, scheduledAt)).build())
                    .toList();

            mqTemplate.syncSend(Topics.DEVICE_TELEMETRY_SYNC, messages);
            total += deviceIds.size();
            offset += BATCH_SIZE;
        }
        log.info("[PlatformSync] dispatched {} device sync tasks", total);
    }
}
```

> Dispatcher 只做"分发任务"，不做实际数据拉取。执行时间 < 1s（10000 条 MQ 发送），不阻塞定时调度。

#### 5.5.4 Worker 设计

```java
@Component
@RocketMQMessageListener(
        topic = "device-telemetry-sync",
        consumerGroup = "platform-sync-worker",
        consumeThreadMax = 20,
        consumeMode = ConsumeMode.CONCURRENTLY
)
@RequiredArgsConstructor
@Slf4j
public class AgenticPlatformSyncWorker implements RocketMQListener<String> {

    private final ObjectMapper objectMapper;
    private final AgenticPlatformTelemetrySyncJob syncJob;

    @Override
    public void onMessage(String message) {
        DeviceTelemetrySyncTask task = objectMapper.readValue(message, DeviceTelemetrySyncTask.class);
        try {
            syncJob.syncDevice(task.deviceId());
        } catch (Exception e) {
            log.error("[PlatformSync] device {} sync failed: {}", task.deviceId(), e.getMessage());
            throw e;  // 触发 RocketMQ 重投
        }
    }
}
```

**syncDevice 方法**（在 AgenticPlatformTelemetrySyncJob 中）：

```java
public void syncDevice(Long deviceId) {
    Device device = deviceRepository.findById(deviceId).orElse(null);
    if (device == null || device.getAgenticPlatformDeviceId() == null) return;

    // 1. 用游标拉取增量数据
    Instant cursor = device.getLastTelemetrySyncedAt();
    int page = 1;
    while (true) {
        ReportRecordPageResp resp = historyClient.queryReportRecords(
                String.valueOf(device.getAgenticPlatformDeviceId()), page, 100);
        if (resp.getData() == null || resp.getData().getRecords().isEmpty()) break;

        for (ReportRecord record : resp.getData().getRecords()) {
            Instant reportTime = parseReportTime(record.getReportTime());
            if (cursor != null && !reportTime.isAfter(cursor)) continue;  // 跳过已同步

            // 2. 解析 decodeData + 顶层字段 → 组装标准 readings Map（§6.2 规范）
            Map<String, Object> readings = AgenticPlatformReportData.toReadings(record);

            // 2a. LIS3DH 加速度换算（§5.6）—— 在数据入口边界完成，下游全部消费换算值
            AgenticPlatformReportData.applyAccelerometerConversion(readings);

            // 3. 统一入口 ingest
            telemetryIngestionService.ingest(
                    deviceId, readings, reportTime, TelemetrySource.AGENTIC_PLATFORM);
        }

        if (resp.getData().getRecords().size() < 100) break;  // 最后一页
        page++;
    }
}
```

#### 5.5.5 容量估算（10000 台目标）

| 参数 | 值 | 说明 |
|------|-----|------|
| 设备总量 | 10,000 | 目标 |
| 上报频率 | 30min/条 | 中台上报间隔 |
| 单设备单次同步耗时 | ~150ms | HTTP RTT ~50ms + JSON 解析 ~5ms + DB 写入 ~95ms |
| 部署实例数 | 3-5 | smart-livestock-server 多实例 |
| 单实例 consumeThreadMax | 20 | RocketMQ 消费线程 |
| 总并发 Worker | 60-100 | 实例数 × consumeThreadMax |
| 全量同步耗时 | 15-25s | 10000 ÷ 100 并发 × 150ms |
| 轮询周期 | 5min (300s) | 远大于同步耗时，余量充足 |
| DB 写入 QPS | ~660 | 10000 条 / 15s（每条 1 行 device_telemetry_logs + 可能 1 行 gps_logs） |

> DB 写入 QPS 660 对 PostgreSQL 无压力（单实例可支撑数千 QPS）。连接池配置 50-80 即可。

#### 5.5.6 游标策略

- **粒度**：每设备游标（`devices.last_telemetry_synced_at` 字段）
- **推进**：ingest() 内部在 source=AGENTIC_PLATFORM 时更新（§6.3 步骤⑥）
- **去重**：Worker 拉取数据时用游标过滤（`reportTime > cursor`），同一设备即使被重复调度也不会重复 ingest
- **首次同步**：cursor 为 null，翻页拉取全部历史数据（分页 100 条/页，自动翻页直到追上）

#### 5.5.7 容错策略

| 场景 | 处理 |
|------|------|
| 中台不可用 | Worker 抛异常 → RocketMQ 自动重投（16 次指数退避，约 4.5h） |
| 单设备持续失败 | 16 次重试后进入死信队列 → 记录 ERROR 日志 → 人工介入 |
| 消息重复投递 | 游标去重，已同步的 reportTime 被 skip，不会重复 ingest |
| DB 写入失败 | 事务回滚，游标不推进 → 下次重试重新拉取 |
| Dispatcher 超时 | 下一轮 5min 自动补偿，不丢设备（所有 ACTIVE 设备每轮都会被分发） |
| Worker 实例宕机 | RocketMQ rebalance，其他实例接管消费 |

#### 5.5.8 并发限流

- **对中台**：consumeThreadMax = 20 就是天然限流。3 实例 × 20 线程 = 60 并发请求，对中台无压力
- **对本地 DB**：ingest() 是 `@Transactional`，每个事务持有一个连接。连接池配 50（每实例），60 并发不会耗尽
- **扩容**：增加 smart-livestock-server 实例数，RocketMQ consumer group 自动 rebalance，吞吐线性增长


### 5.6 加速度计换算（LIS3DH，固件源码 + 规格书 + 实测三方确认）

> 参考：Phase C 对接设计 spec §3.5.1，PoC AccelerometerConverter.java + 12 个单元测试。

**换算位置（方案 B）**：在 **SyncWorker 组装 readings Map 时**完成换算（数据入口边界）。换算一次，所有下游消费者（device_telemetry_logs、TelemetryReceivedEvent → Health 上下文、前端 API）直接消费换算后的值，无需重复换算或跨表查询。

**传感器**: ST LIS3DH 三轴 MEMS 加速度计（规格书见 `docs/reference/C15134_姿态传感器-陀螺仪_LIS3DHTR_规格书_WJ51889.PDF`）

**固件配置**（源码分析确认）:

| 配置项 | 值 | 来源 |
|--------|-----|------|
| 量程 | ±2g | LIS3DH_SCALES[0] = 0.001 |
| 分辨率模式 | Low Power（8-bit，~16mg） | acc.c:411 `lis3dh_low_power` |
| 数据上报 | 原始整数（非 g 值） | acc.c:289 `lis3dh_get_raw_data` |
| 动作阈值 | 512 raw ≈ 32mg | acc.h:18 `DYNAMIC_PRECISION = 512` |
| 高通滤波 | 未启用（数据含重力分量） | 静止合矢量 ≈ 1g 实测确认 |

**数据编码**: LIS3DH 输出为二进制补码 signed int16（左对齐 16-bit 寄存器），中台存为 unsigned uint16。负值（如 -153）在 uint16 中表现为 65383。

**换算公式**:

```python
def blade_accel_to_g(raw: int) -> float:
    signed = raw - 65536 if raw > 32767 else raw
    return signed * 0.004  # ~3.57mg/digit (实测), 4mg/digit (规格书 Normal)
```

> **为什么是 0.004 而不是 1/16384**：固件源码中 LIS3DH 的 16-bit 左对齐寄存器值用 `g = raw / 16384` 换算（±2g 下 1g = 16384）。但中台上报的值不是芯片寄存器原始值——经过解码器处理后降为 ~10-bit 有效精度。实测 92 个静止样本合矢量均值 = 280.5 digits → 反推灵敏度为 3.57mg/digit，接近规格书 Normal 模式的 4mg/digit。

**坐标系**（LIS3DH datasheet 定义）:
- X 轴：平行于芯片长边（引脚 1→16 方向）
- Y 轴：平行于芯片短边（引脚 1→2 方向）
- Z 轴：垂直芯片表面，朝上为正
- 静止正面朝上：AccZ ≈ +1g，AccX ≈ AccY ≈ 0g

**物理含义**: 传感器输出的是视在加速度（比力），包含重力分量。静止时合矢量 ≈ 1g；自由落体时三轴趋近 0g（失重）。

**AccelerometerConverter 工具类**（从 PoC 迁移，8 个方法）:

```java
public class AccelerometerConverter {
    // uint16 → g 值（signed int16 补码 → ×0.004）
    public static double toG(int raw) {
        int signed = raw > 32767 ? raw - 65536 : raw;
        return signed * 0.004;
    }

    // g → m/s²（1g = 9.80665 m/s²）
    public static double toMs2(double g) {
        return g * 9.80665;
    }

    // 三轴合矢量
    public static double magnitudeG(double xG, double yG, double zG) {
        return Math.sqrt(xG * xG + yG * yG + zG * zG);
    }

    // 运动强度 = (magnitude_g - 1) × 100
    public static double motionIntensity(double magnitudeG) {
        return (magnitudeG - 1.0) * 100;
    }

    // 绕 X 轴倾角（需重力分量）
    public static double rollDegrees(double xG, double yG, double zG) {
        return Math.toDegrees(Math.atan2(yG, zG));
    }

    // 绕 Y 轴倾角
    public static double pitchDegrees(double xG, double yG, double zG) {
        return Math.toDegrees(Math.atan2(-xG, Math.sqrt(yG * yG + zG * zG)));
    }

    // 活动分类
    public static String classifyActivity(double magnitudeG) {
        if (magnitudeG < 1.15) return "rest";
        if (magnitudeG < 1.5)  return "light";
        if (magnitudeG < 2.5)  return "active";
        return "intense";
    }

    // 固件动作阈值检测（512 raw ≈ 32mg）
    public static boolean isAboveFirmwareThreshold(int raw) {
        int signed = raw > 32767 ? raw - 65536 : raw;
        return Math.abs(signed) >= 512;
    }
}
```

**在 SyncWorker 中的调用**（`AgenticPlatformReportData.applyAccelerometerConversion`）：

```java
// 在 syncDevice() 组装 readings Map 后调用（§5.5.4 步骤 2a）
public static void applyAccelerometerConversion(Map<String, Object> readings) {
    Integer axRaw = (Integer) readings.get("accelXRaw");
    Integer ayRaw = (Integer) readings.get("accelYRaw");
    Integer azRaw = (Integer) readings.get("accelZRaw");
    if (axRaw == null || ayRaw == null || azRaw == null) return;

    double axG = AccelerometerConverter.toG(axRaw);
    double ayG = AccelerometerConverter.toG(ayRaw);
    double azG = AccelerometerConverter.toG(azRaw);
    double magG = AccelerometerConverter.magnitudeG(axG, ayG, azG);

    // g 值 + 合矢量
    readings.put("accelXG", axG);
    readings.put("accelYG", ayG);
    readings.put("accelZG", azG);
    readings.put("accelMagnitudeG", magG);

    // 运动强度 + 活动分类
    readings.put("motionIntensity", AccelerometerConverter.motionIntensity(magG));
    readings.put("activityClass", AccelerometerConverter.classifyActivity(magG));

    // 倾角（需重力分量，数据满足条件）
    readings.put("rollDegrees", AccelerometerConverter.rollDegrees(axG, ayG, azG));
    readings.put("pitchDegrees", AccelerometerConverter.pitchDegrees(axG, ayG, azG));
}
```

**活动分类**（基于合矢量，数据含重力）:

| 合矢量 | 分类 | 业务含义 |
|--------|------|---------|
| < 1.15g | rest | 静止/休息 |
| 1.15-1.5g | light | 轻微活动（吃草） |
| 1.5-2.5g | active | 活跃行走 |
| > 2.5g | intense | 剧烈运动/冲击/跌倒 |

**验证依据**: 92 个静止样本合矢量均值 = 280.5 digits × 4mg = 1122mg ≈ 1.12g（接近理论重力 1g，偏差来自传感器零点偏移 ±40mg + 微振动噪声）。

**精度限制**: 当前固件用 Low Power 8-bit 模式（~16mg 分辨率），动作阈值 32mg 以下被忽略。反刍咀嚼、头部微摆等细微动作（< 16mg）可能检测不到。固件中有注释掉的 `lis3dh_high_res` 备选（~1mg 分辨率），建议长期切换以支持健康监测场景。

**存储设计**:
- `device_telemetry_logs` 同时存 raw 值（`accel_x_raw` 等 uint16）和换算后 g 值（`accel_x_g` 等），换算值从 readings Map 直接读取（不再在 logDeviceTelemetry 中换算）
- `accel_magnitude_g` 是三轴合矢量，直接可用于活动分类
- `motion_intensity` 是 (magnitude - 1) × 100，对齐现有 activity_logs 的 activity_index 概念
- `activity_class` 是分类标签（rest/light/active/intense）
- `roll_degrees` / `pitch_degrees` 是设备姿态倾角，可用于安装朝向检测和牲畜姿态分析（低头吃草 vs 抬头警戒）
- datagen 合成数据时直接生成 g 值（不生成 raw uint16），raw 列为 null，g 值列正常写入

**对 activity_logs 的影响**:
- 现有 `activity_logs.activity_index` 对应 readings Map 中的 `motionIntensity`
- ingest() 流程中，对 TRACKER 设备直接从 readings 取 `motionIntensity` 写入 activity_logs，无需跨表查询
- `activity_class` / `rollDegrees` / `pitchDegrees` 是新增维度，Health 上下文从 TelemetryReceivedEvent 的 readings 中直接获取，用于行为分析（静止时间占比、活动时段分布、姿态变化等）

---

## 6. Datagen 适配

### 6.1 当前 datagen 数据格式

datagen 通过 `TelemetryIngestionPort.ingest(deviceId, Map<String, Object> readings, recordedAt)` 灌入数据。

当前 readings Map 的 key：
- TRACKER: `batteryLevel`, `latitude`, `longitude`
- CAPSULE: `temperature`, `frequency`, `intensity`, `batteryVoltage`

### 6.2 标准 readings key 规范

所有数据来源（中台轮询 / datagen 合成 / HTTP 直传）必须使用统一的 readings Map key。AgenticPlatformTelemetrySyncJob 在组装 readings 时从 decodeData 解析并映射为标准 key；datagen 在 SynthesisService.generate() 中直接使用标准 key。

**删除 `batteryLevel` 旧 key**（datagen 改造为发送 `battery`），TelemetryIngestionService 不再做 `getOrDefault` 兼容。

| 标准 key | 中台来源 | datagen 来源 | 类型 | 说明 |
|----------|---------|-------------|------|------|
| `battery` | decodeData.properties.properties.battery | 合成生成 | Integer | 电量百分比 |
| `rssi` | report-record 顶层 rssi | 合成生成 | Integer | LoRa 信号强度（dBm） |
| `snr` | report-record 顶层 snr | 合成生成 | String | 信噪比（中台返回 String 如 "12.5"，ingest 内 `toBigDecimal()` 转换后写入 DB `NUMERIC(4,1)`） |
| `gatewayId` | report-record 顶层 reportGateway | 合成生成 | String | 网关 ID |
| `stepNumber` | decodeData.properties.properties.stepNumber | 合成生成 | Integer | 累计步数 |
| `accelXRaw/YRaw/ZRaw` | decodeData.properties.properties.x/y/zAxisDirectionAccelerationValue | 不生成（仅真实设备） | Integer | 三轴加速度原始值（LIS3DH uint16） |
| `accelXG/YG/ZG` | SyncWorker 换算（§5.6） | 合成生成 | Double | 三轴加速度 g 值 |
| `accelMagnitudeG` | SyncWorker 换算（§5.6） | 合成生成 | Double | 三轴合矢量 g 值 |
| `motionIntensity` | SyncWorker 换算（§5.6） | 合成生成 | Double | 运动强度 = (magnitude_g - 1) × 100 |
| `activityClass` | SyncWorker 换算（§5.6） | 合成生成 | String | 活动分类：rest/light/active/intense |
| `rollDegrees` | SyncWorker 换算（§5.6） | 合成生成 | Double | 绕 X 轴倾角（姿态） |
| `pitchDegrees` | SyncWorker 换算（§5.6） | 合成生成 | Double | 绕 Y 轴倾角（姿态） |
| `antiDisassemblyStatus` | decodeData.properties.properties.antiDisassemblyStatus（PoC 实测值为 0，未出现过非 0 值） | 合成生成 | Integer | 防拆卸状态 |
| `latitude` | decodeData.properties.properties.latitude | 合成生成 | BigDecimal | 纬度 |
| `longitude` | decodeData.properties.properties.longitude | 合成生成 | BigDecimal | 经度 |

> 注意：rssi/snr/gatewayId 来自 report-record 的**顶层字段**，不在 decodeData 内。AgenticPlatformTelemetrySyncJob 解析时需同时读取顶层和 decodeData。

### 6.3 TelemetryIngestionService 升级为分流+透传

`ingest()` 签名扩展，新增 `source` 参数，内部按统一流程分流（对齐 §5.1 方案 B）：

```java
public enum TelemetrySource { AGENTIC_PLATFORM, DATAGEN, HTTP }

@Transactional
public void ingest(Long deviceId, Map<String, Object> readings,
                   Instant recordedAt, TelemetrySource source) {
    // 1. 验证设备 + 安装记录（现有逻辑不变）
    Device device = deviceRepository.findById(deviceId)...;
    Installation installation = ...;

    // 2. 更新设备实时状态（快照 → devices 表）
    updateDeviceRuntimeStatus(device, readings);

    // 3. 写入设备运维时序 → device_telemetry_logs
    logDeviceTelemetry(device, readings, recordedAt);

    // 4. GPS 提取 → gps_logs（TRACKER 设备）
    extractAndLogGps(device, readings, recordedAt);

    // 5. 告警检测（仅 AGENTIC_PLATFORM 来源）
    if (source == TelemetrySource.AGENTIC_PLATFORM) {
        detectDeviceAlerts(device, readings);
    }

    // 6. 透传 TelemetryReceivedEvent → RocketMQ → Health 上下文
    TelemetryReceivedEvent event = new TelemetryReceivedEvent(
            device.getId(), livestockId, farmId,
            device.getDeviceType(), readings, recordedAt);
    eventPublisher.publishEvent(event);

    // 7. 推进同步游标（仅 AGENTIC_PLATFORM 来源）
    if (source == TelemetrySource.AGENTIC_PLATFORM) {
        device.setLastTelemetrySyncedAt(Instant.now());
    }
}

// 分流方法：设备实时状态更新（替代旧 updateDeviceRuntimeStatus）
private void updateDeviceRuntimeStatus(Device device, Map<String, Object> readings) {
    Object battery = readings.get("battery");
    if (battery != null) device.setBatteryLevel(toInteger(battery));

    Object rssi = readings.get("rssi");
    if (rssi != null) device.setRssi(toInteger(rssi));

    Object snr = readings.get("snr");
    if (snr != null) device.setSnr(toBigDecimal(snr));

    Object gateway = readings.get("gatewayId");
    if (gateway != null) device.setLastGateway(gateway.toString());

    Object antiDis = readings.get("antiDisassemblyStatus");
    if (antiDis != null) device.setAntiDisassemblyStatus(toInteger(antiDis));

    device.setLastOnlineAt(Instant.now());
}

// 分流方法：设备运维时序写入
private void logDeviceTelemetry(Device device, Map<String, Object> readings, Instant recordedAt) {
    DeviceTelemetryLog log = new DeviceTelemetryLog();
    log.setDeviceId(device.getId());
    log.setTenantId(device.getTenantId());
    log.setBatteryLevel(device.getBatteryLevel());
    log.setRssi(device.getRssi());
    log.setSnr(device.getSnr());
    log.setGatewayId(device.getLastGateway());
    log.setStepNumber(getInteger(readings, "stepNumber"));
    // 加速度：raw + 换算值都从 readings 直接读取（换算在 SyncWorker 边界完成，见 §5.6）
    log.setAccelXRaw(getInteger(readings, "accelXRaw"));
    log.setAccelYRaw(getInteger(readings, "accelYRaw"));
    log.setAccelZRaw(getInteger(readings, "accelZRaw"));
    log.setAccelXG(getBigDecimal(readings, "accelXG"));
    log.setAccelYG(getBigDecimal(readings, "accelYG"));
    log.setAccelZG(getBigDecimal(readings, "accelZG"));
    log.setAccelMagnitudeG(getBigDecimal(readings, "accelMagnitudeG"));
    log.setMotionIntensity(getBigDecimal(readings, "motionIntensity"));
    log.setActivityClass(getString(readings, "activityClass"));
    log.setRollDegrees(getBigDecimal(readings, "rollDegrees"));
    log.setPitchDegrees(getBigDecimal(readings, "pitchDegrees"));
    log.setReportTime(recordedAt);
    deviceTelemetryLogRepository.save(log);
}

// 分流方法：设备告警检测（内联创建，对齐 GpsLogEventConsumer 模式）
private void detectDeviceAlerts(Device device, Map<String, Object> readings) {
    // 防拆卸告警
    Object antiDis = readings.get("antiDisassemblyStatus");
    if (antiDis != null && toInteger(antiDis) != 0) {
        createDeviceAlertIfNotExists(device, AlertType.DEVICE_TAMPER, Severity.CRITICAL,
                "设备防拆卸告警: " + device.getDeviceCode());
    }
    // 低电量告警
    if (device.getBatteryLevel() != null && device.getBatteryLevel() < 20) {
        createDeviceAlertIfNotExists(device, AlertType.DEVICE_LOW_BATTERY, Severity.WARNING,
                "设备低电量: " + device.getBatteryLevel() + "%");
    }
}

// 去重：检查是否已有同类型未处理告警（对齐 GpsLogEventConsumer.createAlertIfNeeded）
private void createDeviceAlertIfNotExists(Device device, AlertType type,
                                           Severity severity, String message) {
    List<Alert> existing = alertRepository.findByDeviceIdAndTypeAndStatus(
            device.getId(), type, AlertStatus.ACTIVE);
    if (!existing.isEmpty()) return;
    Alert alert = new Alert(device.getFarmId(), null, null, device.getId(),
            type, severity, message);
    alertRepository.save(alert);
}
```

> **告警创建模式**：对齐现有 `GpsLogEventConsumer.createAlertIfNeeded()` 的内联模式，不走独立 AlertConsumer。去重逻辑：检查该设备是否有同类型 ACTIVE 告警，有则跳过。

### 6.4 datagen 合成场景增强

SynthesisScenario 的 pattern 新增设备故障场景。需要在 `ScenarioType` 枚举新增 `Category.DEVICE`：

> **ScenarioType 扩展注意**：现有 `DimensionModulation` 是四维参数（tempDelta/motility/activity/distance），不适用于设备故障场景。设备场景的调制维度是 rssi/snr/battery/antiDisassembly。建议为 `Category.DEVICE` 新增 `DeviceDimensionModulation`（或在 ScenarioType 中将 modulation 改为可选 + 新增 deviceModulation 字段），不破坏现有 HEALTH/FENCE 场景的兼容性。

| pattern | ScenarioType | Category | 数据特征 |
|---------|-------------|----------|---------|
| `NORMAL` | 现有 | BASELINE | battery 缓慢下降，rssi 稳定 |
| `DEVICE_LOW_BATTERY` | 新增 | DEVICE | battery 从 100 线性降至 15 |
| `DEVICE_SIGNAL_DEGRADATION` | 新增 | DEVICE | rssi 从 -40 降至 -95，snr 降至 3 |
| `DEVICE_ANTI_DISASSEMBLY` | 新增 | DEVICE | antiDisassemblyStatus 从 0 变为 1 |
| `DEVICE_OFFLINE` | 新增 | DEVICE | 停止数据上报（gap 模拟） |

---

## 7. 实施任务分解

### Phase 3-A：中台对接迁移（Feign Client + 轮询 Job）

| # | 任务 | 说明 | 涉及 |
|---|------|------|------|
| A1 | Feign Client + AccelerometerConverter 迁移 | 从 PoC 模块复制到 smart-livestock-server/iot/infrastructure/client/agenticplatform/（Feign 接口 + DTO + Fallback + Config + OAuth2）。同时迁移 AccelerometerConverter（LIS3DH 换算工具类 + 测试）。增加 Feign 超时/重试 yml 配置。 | OAuth2 + Client + DTO + Fallback + Config + AccelerometerConverter |
| A2 | Device 模型扩展 | 新增 agenticPlatformDeviceId 等字段 + Device.syncAgenticPlatformStatus() + DeviceJpaEntity 映射 + DeviceMapper toDomain/toJpaEntity/toDto + DeviceResponse DTO 新增字段 | Device.java + JPA Entity + Mapper + Repository + DTO |
| A3 | Flyway 迁移 + JPA | devices 表 ALTER + device_telemetry_logs 新建（月分区）+ alerts 表加 device_id 列 + DeviceTelemetryLog JPA Entity + Repository | V{timestamp}__phase3_device_extension.sql + JPA + Repository |
| A4 | 设备注册流程改造 | DeviceApplicationService 新增 中台同步注册 | IoT Application |
| A5a | AgenticPlatformSyncDispatcher | @Scheduled 每 5min 扫描 ACTIVE 设备 → 批量发送同步任务到 RocketMQ | IoT Application + @Scheduled |
| A5b | AgenticPlatformSyncWorker | RocketMQ Consumer → 调 syncDevice() → 拉 report-record + 解析 + ingest(source=AGENTIC_PLATFORM) | IoT Application + @RocketMQMessageListener |
| A5c | AgenticPlatformTelemetrySyncJob.syncDevice() | 单设备同步逻辑：游标 + 分页 + 组装 readings + 调 ingest() | IoT Application |
| A5d | Topics.java + DeviceTelemetrySyncTask DTO | 注册 device-telemetry-sync topic + 消息 DTO | shared/messaging |

### Phase 3-B：设备健康管理

| # | 任务 | 说明 |
|---|------|------|
| B1 | DeviceHealthScoreService | 健康评分计算（5 维度加权） |
| B2 | 设备健康 API | GET /api/v1/devices/{id}/health（健康分 + 趋势） |
| B3 | 防拆卸告警联动 | TelemetryIngestionService 内联创建 DEVICE_TAMPER 告警（去重）+ AlertType 枚举扩展 + alerts 表加 device_id 列 |
| B4 | 低电量告警 | TelemetryIngestionService 内联创建 DEVICE_LOW_BATTERY 告警（去重）|
| B5 | 前端设备健康卡片 | 电量/信号趋势图 + 健康分展示 |

### Phase 3-C：datagen + 数据存储适配

| # | 任务 | 说明 |
|---|------|------|
| C1 | TelemetryIngestionService 升级 | source 参数 + 分流（updateRuntimeStatus/logDeviceTelemetry/extractGps/detectAlerts）+ 透传 TelemetryReceivedEvent |
| C2 | datagen readings 对齐 | 合成数据使用标准 key 规范（§6.2），source=DATAGEN |
| C2a | TelemetryIngestionPort 扩展 | ingest() 加 source 参数（D7），datagen 传入 DATAGEN |
| C3 | stepNumber 增量计算 | 累计值 → 周期增量，写入 activity_logs |
| C4 | datagen 设备故障场景 | 新增 LOW_BATTERY / SIGNAL_DEGRADATION 等 pattern |
| C5 | seed 数据更新 | 设备 seed 数据补充 platform_device_id + 运维指标 |

---

## 8. i18n 与种子数据

### 8.1 新增 ErrorCode

| ErrorCode | 说明 | zh | en |
|-----------|------|----|----|
| `AGENTIC_PLATFORM_DEVICE_NOT_MAPPED` | 设备未在中台注册 | 设备未在第三方平台注册 | Device not registered on platform |
| `AGENTIC_PLATFORM_SERVICE_UNAVAILABLE` | 中台服务不可用 | 设备平台暂时不可用 | Device platform temporarily unavailable |
| `AGENTIC_PLATFORM_REGISTRATION_FAILED` | 中台注册失败 | 设备注册失败 | Device registration failed |
| `AGENTIC_PLATFORM_LICENSE_INVALID` | License 无效 | 设备授权无效 | Device license invalid |
| `DEVICE_ANTI_DISASSEMBLY` | 防拆卸告警 | 设备防拆卸告警 | Device tamper alert |

> **告警模型扩展**：
> - `AlertType` 新增 `DEVICE_TAMPER`（防拆卸，CRITICAL）、`DEVICE_LOW_BATTERY`（低电量，WARNING）
> - `alerts` 表**需要新增 `device_id BIGINT` 列**（现有表无此列，只有 livestock_id 和 fence_id）
> - `AlertJpaEntity` + `AlertMapper` + alerts CHECK 约束同步更新
> - Flyway: `ALTER TABLE alerts ADD COLUMN IF NOT EXISTS device_id BIGINT`

### 8.2 种子数据

设备 seed 需补充 `agentic_platform_device_id` 字段。对于已有 demo 设备，可使用 中台中已有的设备 ID（如 `2072879090955759616` / `2072879090955759618`），使 demo 环境能直接拉取真实 中台 数据。

---

## 9. 风险与约束

| # | 项 | 影响 | 缓解 |
|---|------|------|------|
| 1 | GPS 坐标格式未确认 | scale=1e-06 是否需转换 | 等设备部署到牧场后确认；代码先按浮点值处理 |
| 2 | report-record 软删除行为 | removeDevice 后仍可查到 | getDeviceDetail 仍可查，轮询 Job 需检测设备是否已删除 |
| 3 | 中台 服务可用性 | 轮询失败导致数据中断 | ErrorDecoder + 重试 + 降级（不推进游标） |
| 4 | License 服务未部署 | 设备入网流程 ③④ 无法完整测试 | 先跳过 License 步骤，直接 registerDevice |
| 5 | stepNumber 回退 | 增量计算出现负值 | 丢弃负增量，记录 warn 日志 |

---

## 10. 与其他文档的关系

| 文档 | 关系 |
|------|------|
| [Phase C 中台对接设计（整合版）](2026-07-07-phase-c-blade-device-integration.md) | 前置：PoC 验证的端点契约、OAuth2 流程、服务账号凭据 |
| `docs/product/smart-livestock-prd-v2.3.md` | 上游：PRD §4.13 第三方平台集成 + §6.8 设备管理 + §11 路线图 |
| `docs/superpowers/specs/2026-05-06-mvp-backend-design.md` | 参考：DDD 洋葱架构、限界上下文边界 |
| `docs/superpowers/specs/2026-07-01-livestock-device-management-design.md` | 参考：现有设备管理 CRUD + 业务规则 |
