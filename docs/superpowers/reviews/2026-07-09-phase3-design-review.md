# Phase 3 实施设计 — 评审报告

**被评审文档**: `docs/superpowers/specs/2026-07-08-phase3-blade-integration-device-health-spec.md`
**评审日期**: 2026-07-09
**核实范围**: devices 表结构、TelemetryIngestionService、分区表语法、ScenarioType 枚举、Blade Feign Client、RocketMQ 消费者、ErrorCode 枚举、ActivityLog 模型

---

## 一、总体评价

设计覆盖了三个主题（设备模型扩展、blade 入网旅程、datagen 适配），整体方向正确，与 PoC 成果衔接清晰。**两个阻塞性问题需要修正后进入实施**。

---

## 二、严重问题（需修正后实施）

### 🔴 1. 防拆卸告警无去重 + 事件机制与现有架构不一致

**核实事实**：
- 项目中**不存在独立的 AlertConsumer**。告警创建由 `GpsLogEventConsumer`（监听 `gps-log-updated`）直接调用 `AlertRepository.save()`，Health 上下文通过 `RanchCommandPort` ACL 端口同步创建告警
- 现有 `AlertType` 枚举没有 `DEVICE_TAMPER` 或 `ANTI_DISASSEMBLY` 类型
- Topics.java 中没有 `device.anti-disassembly` 或 `device.low_battery` topic

**问题**：
1. 文档说"发布 `device.anti-disassembly` 事件 → AlertConsumer 接收"，但现有架构是消费者内联创建告警，不走独立 AlertConsumer
2. 每次轮询都检测 `antiDisassemblyStatus ≠ 0`，如果设备持续处于防拆卸状态，每 5 分钟产生一条重复告警

**建议**：
- 新增 `AlertType.DEVICE_TAMPER`（对齐现有枚举命名风格，不用 ANTI_DISASSEMBLY）
- 在 BladeTelemetrySyncJob 中内联创建告警（对齐现有 `GpsLogEventConsumer` 模式），或通过发布事件由新的 Consumer 处理，但不要假设存在独立 AlertConsumer
- 去重：只在该设备当前无未处理 DEVICE_TAMPER 告警时创建新告警
- 在 Topics.java 注册新 topic

### 🔴 2. BladeTelemetrySyncJob 核心设计缺失

**核实事实**：
- `BladeHistoryDataClient.queryReportRecords(deviceId, current, size)` 已存在（hkt-blade-device-docking 模块），按 deviceId + 分页查询
- 文档只描述了数据流图（§5.1）和任务名（A5），没有游标策略、分页大小、错误重试、并发控制的任何细节

**必须补充的决策**：

| 决策点 | 选项 | 影响 |
|--------|------|------|
| 游标粒度 | 全局游标 vs 每设备游标 | 决定 `last_telemetry_synced_at` 是字段还是独立表 |
| 分页大小 | 100/500/1000 条 | 影响轮询延迟 |
| 重试策略 | 固定间隔 vs 指数退避 vs 跳过 | 决定 blade 不可用时的数据完整性 |
| 并发模型 | 串行轮询 vs 每设备并行 | 10 台设备 × 5 分钟 vs 100 台 × 30 分钟完全不同 |
| 时区处理 | blade 返回的 reportTime 时区 | 影响游标推进正确性 |

**建议**：在 §5 中增加 §5.5 小节覆盖以上五点。

---

## 三、架构决策：数据流入口（已决策 ✓）

### 方案 B：TelemetryIngestionService 为唯一入口

**决策**：BladeTelemetrySyncJob 不直接写 device_telemetry_logs 或更新 devices 快照，而是通过 `TelemetryIngestionService.ingest()` 统一入站。TelemetryIngestionService 从当前的"透传模式"升级为"分流+透传模式"。

**数据流（修正后）**：
```
blade report-record/page（每 30min 一条）
    ↓
BladeTelemetrySyncJob（定时轮询）
    ↓ 解析 decodeData，组装 readings Map
    ↓
TelemetryIngestionService.ingest(deviceId, readings, recordedAt, source=BLADE)
    ↓
    ├─ ① updateDeviceRuntimeStatus（rssi/snr/gateway/battery/antiDisassembly）
    ├─ ② logDeviceTelemetry → device_telemetry_logs（运维指标时序）
    ├─ ③ extractAndLogGps → gps_logs（GPS 定位）
    ├─ ④ 防拆卸/低电量告警检测 → RocketMQ 事件
    ├─ ⑤ publishEvent(TelemetryReceivedEvent) → 透传 readings
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
    （同上流程，source 可用于区分行为）
```

**配套设计要求**：

| # | 设计要求 | 影响范围 |
|---|---------|---------|
| D1 | `ingest()` 签名新增 `source` 参数（枚举：BLADE / DATAGEN / HTTP），区分数据来源 | TelemetryIngestionService 接口 |
| D2 | BladeTelemetrySyncJob 组装 readings Map 时使用与 datagen 一致的字段名（见下方 §四.4） | BladeTelemetrySyncJob |
| D3 | `logDeviceTelemetry()` 在 source=DATAGEN 时也写入（datagen 的运维指标同步归档） | TelemetryIngestionService |
| D4 | 告警检测（防拆卸/低电量）仅在 source=BLADE 时触发（datagen 模拟的数据不产生真实告警） | TelemetryIngestionService |
| D5 | 文档 §5.1 数据流图需要更新为以上流程，删除 BladeTelemetrySyncJob 中的分流步骤 | 设计文档 |
| D6 | datagen 的 `SynthesisService.generate()` 需要发送规范化的 readings（统一字段名） | SynthesisService |
| D7 | BladeTelemetrySyncJob 需要引用 `TelemetryIngestionService`，因此必须迁移到 smart-livestock-server 模块内（见 §四.3） | 模块结构 |

---

## 四、中等问题（建议实施前解决）

### 🟡 3. Blade Feign Client 需从独立模块迁移到 smart-livestock-server

**核实事实**：Blade Feign Client（`BladeDeviceServiceClient`, `BladeHistoryDataClient`, `BladeLicenseClient`）存在于独立模块 `business-platform/hkt-blade-device-docking/`，不在 `smart-livestock-server/` 中。任务 A1 说"从 PoC 迁移到 smart-livestock-server/iot/infrastructure/client/feign/"。

**方案 B 下的额外约束**：BladeTelemetrySyncJob 需调用 `TelemetryIngestionService`（在 smart-livestock-server 的 IoT 上下文中），因此 BladeTelemetrySyncJob + Blade Feign Client 都必须纳入 smart-livestock-server 模块。

**建议**：在 smart-livestock-server 内新增 `iot/infrastructure/client/blade/` 目录，从 PoC 模块复制 Feign 接口 + DTO + Fallback + Config。BladeTelemetrySyncJob 作为 `@Component` 放在 `iot/application/` 下。

### 🟡 4. 字段名映射策略：必须统一

**核实事实**：
- 现有 `updateDeviceRuntimeStatus` 用 `readings.get("batteryLevel")`
- 文档 §6.3 改为 `readings.getOrDefault("battery", readings.get("batteryLevel"))` — 兼容双字段名
- 文档 §6.2 datagen 同时发送 `"batteryLevel"` 和 `"battery"` 两个 key

**方案 B 下的影响**：BladeTelemetrySyncJob 和 datagen 通过同一个 `TelemetryIngestionService.ingest()` 入站，readings Map 的 key 必须一致，否则 Service 内部需要大量 `getOrDefault` 兼容代码。

**建议**：定义一份**标准 readings key 规范**，所有来源（blade/datagen/HTTP）统一使用：

| 标准 key | blade 来源 | datagen 来源 | 类型 | 说明 |
|----------|-----------|-------------|------|------|
| `battery` | decodeData.properties.properties.battery | 合成生成 | Integer | 电量百分比 |
| `rssi` | blade API 顶层字段（待确认） | 合成生成 | Integer | LoRa 信号强度 |
| `snr` | blade API 顶层字段（待确认） | 合成生成 | BigDecimal | 信噪比 |
| `gatewayId` | blade API 顶层字段（待确认） | 合成生成 | String | 网关 ID |
| `stepNumber` | decodeData.properties.properties.stepNumber | 合成生成 | Integer | 累计步数 |
| `accelX/Y/Z` | decodeData.properties.properties.x/y/zAxisDirectionAccelerationValue | 合成生成 | Integer | 三轴加速度 |
| `antiDisassemblyStatus` | blade API 顶层字段（待确认） | 合成生成 | Integer | 防拆卸状态 |
| `latitude` | decodeData.properties.properties.latitude | 合成生成 | BigDecimal | 纬度 |
| `longitude` | decodeData.properties.properties.longitude | 合成生成 | BigDecimal | 经度 |

> 删除 `batteryLevel` 兼容逻辑。datagen 改造为发送 `battery`（不是 `batteryLevel`）。

### 🟡 5. stepNumber 增量计算边界情况

**核实事实**：`activity_logs.step_count` 是**增量值**（`HealthApplicationService` 对 24h 内的 step_count 做 SUM 验证）。

**文档 §5.3 遗漏**：
- 首次上报行为：全量写入 activity_logs 会灌入异常大的步数值
- 设备重启：累计值可能从 0 重新开始
- 查询范围：应按 `device_id` 查上次 stepNumber（文档只说"查最后一条"）

**建议**：
```
首次（无历史）→ 只记录基线到 device_telemetry_logs，不写 activity_logs
正常增量     → delta = 当前 - 上次，写入 activity_logs
回退（重置）  → 检测到当前 < 上次，记录新基线，丢弃此周期
```

### 🟡 6. decodeData 字段覆盖不全

**文档 §5.2 的 `BladeReportData`** 只有 battery/latitude/longitude/stepNumber/workMode/accelX/Y/Z，但 §1.3 的 blade 真实数据维度还有 rssi/snr/lastGateway/antiDisassemblyStatus。需要确认这些运维指标是来自 `report-record/page` 的 decodeData 还是 `getDeviceDetailWithTelemetry`。

**建议**：在文档中增加"blade API 字段映射表"，明确每个 smart-livestock 字段的 blade 数据来源。

---

## 五、轻微问题

### 🟢 7. 告警模型扩展未对齐

需要新增的枚举/表变更：
- `AlertType` 新增 `DEVICE_TAMPER`（防拆卸）、`DEVICE_LOW_BATTERY`（低电量）
- `Severity` 中防拆卸 = CRITICAL，低电量 = WARNING
- 确认告警是否需要关联 `device_id`（现有 `alerts` 表已有 `device_id` 列，可直接复用）

### 🟢 8. ScenarioType 扩展方式

`ScenarioType` 枚举当前有 BASELINE/HEALTH/FENCE 三个 category。文档 §6.5 新增的 4 个 DEVICE_* pattern 需要新增 `Category.DEVICE`。注意 `ScenarioType` 枚举携带 `DimensionModulation`（tempDelta 等），设备场景的 modulation 维度完全不同，可能需要重构为更灵活的 pattern 模型。

### 🟢 9. 任务分解遗漏

| 遗漏 | 位置 |
|------|------|
| DeviceJpaEntity 新增 7 字段的 JPA 映射 | A2 应包含 |
| DeviceMapper 更新 toDomain/toJpaEntity/toDto | A2 应包含 |
| DeviceResponse DTO 新增字段 | A2 应包含 |
| Topics.java 注册新 topic | A5 应包含 |
| RocketMQ Consumer/Topic 注册 | B3/B4 应包含 |
| device_telemetry_logs JPA Entity + Repository | A3/C1 应包含 |
| Feign Client 超时/重试 yml 配置 | A1 应包含 |
| AlertType 枚举扩展 | B3 应包含 |
| ~~TelemetryIngestionService 签名改造（source 参数）~~ | —（方案 B 新增，文档 §6.3 需补充） |
| ~~datagen SynthesisService 字段名统一改造~~ | —（方案 B 新增，见 D6） |
| ~~BladeTelemetrySyncJob readings 组装规范~~ | —（方案 B 新增，见 D2） |

### 🟢 10. `health_score` feature key 命名冲突

现有订阅系统已有 `health_score` feature key（牲畜健康评分，见 V31 seed），文档设计的"设备健康评分"是新概念但名字相似。建议命名为 `device_health_score` 避免混淆。

---

## 六、代码核实确认（文档 vs 实际）

| 文档声明 | 代码核实 | 结论 |
|---------|---------|------|
| devices 表结构（9 字段） | V3 实际 10 字段 + CHECK 约束 | ✅ 一致（省略审计字段合理） |
| DeviceStatus: INVENTORY/ACTIVE/OFFLINE/DECOMMISSIONED | 代码一致 | ✅ |
| DeviceType: EAR_TAG/TRACKER/CAPSULE | V25 后一致 | ✅ |
| updateDeviceRuntimeStatus 方法 | 已存在，仅处理 batteryLevel | ✅ 待扩展 |
| readings Map 透传 | 确认透传 | ✅ 方案 B 升级为"分流+透传" |
| activity_logs.step_count = 增量 | SUM 运算确认 | ✅ |
| ErrorCode 无 BLADE_* | 确认不存在 | ✅ 需新增 |
| GpsLog DECIMAL(10,7) | 一致 | ✅ |
| device_telemetry_logs 表 | 不存在 | ✅ 需新建 |
| DeviceHealthScore | 不存在 | ✅ 需新建 |
| Blade Feign Client | 独立模块中 | ✅ 需迁移到 smart-livestock-server |
| 分区表 PRIMARY KEY 含分区键 | temperature_logs 等一致 | ✅ |

---

## 七、总结

**已决策**：数据流入口采用**方案 B**（TelemetryIngestionService 唯一入口），BladeTelemetrySyncJob 通过 `ingest()` 入站，不直写 DB。详见 §三 配套设计要求 D1–D7。

**可以进入实施的先决条件**（阻塞项）：
1. ✅ 修正防拆卸告警去重 + 对齐现有告警创建模式
2. ✅ 补充 BladeTelemetrySyncJob 详细设计（游标/分页/重试/并发/时区）
3. ✅ 文档中落实方案 B 的配套设计（D1–D7），更新 §5.1 数据流图

**强烈建议实施前解决**：
4. Blade Feign Client 迁移策略明确化
5. 标准 readings key 规范定义（统一 blade/datagen/HTTP 三种来源的字段名）
6. stepNumber 边界情况处理
7. decodeData 字段来源完整确认

整体是一份**方向正确、结构清晰但执行细节不足**的设计文档。核心架构决策已确定（方案 B），防拆卸告警和 SyncJob 设计细节需要在文档中修正；实施细节（字段映射规范、边界情况）可在实施过程中细化，但建议至少给出明确的设计原则。
