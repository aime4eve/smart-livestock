# GPS 抖动治理实施方案 — 评审意见

- **评审对象**: `docs/superpowers/plans/2026-07-13-gps-jitter-governance-plan.md`
- **评审日期**: 2026-07-13
- **关联工单**: NIX-9
- **评审方法**: 对照 `smart-livestock-server/` 代码库实际现状逐条核查

---

## 总体评价

方案的整体架构方向正确——建立独立的数据治理层（`GpsGovernanceService`）位于围栏检测上游，用"位移门控 + 加速度计辅助 + 中值滤波"替代纯单点检测，符合需求 §5.1 的目标。Task 依赖图清晰，File Map 基本合理。

**但存在 3 个阻塞性问题（阻拦项）和若干重要问题，必须修订后方可实施。** 核心原因是方案对现有数据流的假设与代码实际现状存在严重脱节，尤其是**加速度计数据无法到达治理管道**这一架构级断裂。

---

## 阻塞性问题（BLOCKER — 不解决无法实施）

### B1. 加速度计数据无法到达治理管道

**方案假设**: `GpsGovernanceService.evaluate()` 的签名包含 `motionIntensity` 和 `stepNumber` 参数，Layer 3 "灰色地带加速度计辅助判断"依赖这两个值。

**代码事实**:
- `GpsLogUpdatedEvent`（触发围栏检测的事件）**只有 4 个字段**：`deviceId, latitude, longitude, recordedAt`（文件 `iot/domain/event/GpsLogUpdatedEvent.java` L13-16）。
- `GpsLogEventConsumer.onMessage()` **只解析 GPS 三个字段**（`deviceId/latitude/longitude`），不解析加速度计/步数（L51-55）。
- 加速度计数据（`motion_intensity, stepNumber, accelMagnitudeG`）存储在 **`device_telemetry_logs` 表**，走 **`TelemetryReceivedEvent`**（topic `telemetry-received`），与围栏检测消费的 `gps-log-updated` 是**两条完全独立的事件链路**。
- `gps_logs` 表**不含任何加速度计字段**（V3 迁移，仅 `id/device_id/latitude/longitude/accuracy/recorded_at/created_at`）。

**影响**: 方案的 Task 3（GpsGovernanceService）、Task 6（GpsLogEventConsumer 改造）中的 `motionIntensity` 和 `stepNumber` 参数**永远是 null**。Layer 3 的"加速度计辅助判断"形同虚设——当 `motionIntensity == null && stepNumber == null` 时，`accelSuggestsMove` 恒为 false，灰色地带永远不确认移动。

**修复建议**: 方案需新增一个 Task 明确加速度计数据的获取路径，三选一：
1. **扩展 GpsLogUpdatedEvent**（推荐）：在事件中捎带加速度计快照。因为 `TelemetryIngestionService.ingest()` 内 `extractAndLogGps()` 和 `logDeviceTelemetry()` 在同一事务中执行，GPS 和加速度计来自同一份 `readings`，组装时天然对齐。
2. **治理服务跨表查询**：GpsLogEventConsumer 通过 IoTQueryPort 查询 `device_telemetry_logs` 最近一条加速度计记录（按 `report_time` 降序取 top-1）。缺点：每次围栏检测多一次 DB 查询。
3. **合并到同一事件**：将 `gps-log-updated` 和 `telemetry-received` 在消费侧合并。缺点：跨 topic 时序对齐复杂。

---

### B2. DeviceCalibration 的关联字段与代码实际不一致

**方案假设**: Task 1 中 `DeviceCalibrationRepository` 提供 `findByEui(String eui)` 和 `findByDeviceId(Long)`，`DeviceCalibration` 模型有 `eui` 字段。

**代码事实**:
- `Device` 领域模型的 EUI 字段名是 **`devEui`**（`iot/domain/model/Device.java` L24-43），getter 是 `getDevEui()`，DB 列是 `dev_eui`。**不是 `eui`**。
- `Device` **不直接持有 `livestockId`**。关联链路是 `Device → Installation → Livestock`（`Installation` 中间实体，`deviceId + livestockId`，`isActive() = removedAt == null`）。
- `dev_eui` 列**无 UNIQUE 约束且可空**（V3 迁移 L16）。用 EUI 作为标定参数的关联键需先确保唯一性。

**修复建议**:
- `DeviceCalibration` 字段从 `eui` 改为 `devEui`，与 `Device.devEui` 对齐。
- 若方案要"部署自适应微调"（§4.3），需说明标定参数的归属是设备级（`deviceId`）还是牲畜级（`livestockId`）。当前方案隐含设备级，但牛/设备多对一关系（一头牛换设备、一个设备换牛）会影响历史数据的一致性。建议明确以 `deviceId` 为主键关联。

---

### B3. 冷却期查询方法不存在

**方案假设**: Task 5 和 Task 6 的 `createAlertWithCooldown()` 调用 `alertRepository.findLatestBreachAlert(livestockId, fenceId)`，返回 `Optional<Alert>`。

**代码事实**: `AlertRepository`（`ranch/domain/repository/AlertRepository.java`，共 17 行）**不存在** `findLatestBreachAlert` 或任何按时间排序取 top-1 的查询。现有方法全部返回 `List`：
```
save, findById, findByFarmId, findByFarmIdAndStatus,
findByLivestockIdAndTypeAndStatus, findByDeviceIdAndTypeAndStatus
```
现有去重逻辑是"语义去重"——每个 (livestock + fence + type) 只保留一条 ACTIVE 告警（`createAlertIfNeeded` L153-171），**不存在时间窗口冷却**。

**影响**: 方案 Task 5 提到"AlertRepository 新增冷却期查询"，但 Task 5 的标题只写了 MODIFY `AlertRepository.java`，没有展开 Step 内容。这是方案中唯一的占位任务——Self-Review 声称"无 TBD/TODO"，但 Task 5 实际上是空的。

**修复建议**: Task 5 需补充完整内容，包括：
- `AlertRepository` 新增方法签名（`Optional<Alert> findLatestResolved(Long livestockId, Long fenceId)`）
- JPA Repository 实现（`@Query` + `ORDER BY resolvedAt DESC LIMIT 1`）
- 单元测试

---

## 重要问题（IMPORTANT — 影响实施质量和正确性）

### I1. AccelerometerConverter 在两个仓库重复，Task 7 只改了一半

**代码事实**: `AccelerometerConverter` 在两个仓库逐字节重复存在：
- `smart-livestock-server/` 的 `com.smartlivestock.iot.infrastructure.client.agenticplatform.util`
- `business-platform/hkt-blade-device-docking/` 的 `com.smartlivestock.docking.util`

方案 Task 7 只修改 business-platform 版本。**server 版本不会被同步修改**，导致同一算法在两个仓库分叉。

**修复建议**: Task 7 应同时修改两个仓库的 `classifyActivity`，或在 File Map 中明确标注两处都需要改。

---

### I2. Task 6 的 GpsLogEventConsumer 改造代码不完整

**方案现状**: Task 6 只给了 `onMessage` 的核心片段和一个 `createAlertWithCooldown` 方法，但：
- 原始 `GpsLogEventConsumer` 有 6 个依赖注入，改造后新增 `GpsGovernanceService, PositionStateCache, DeviceCalibrationRepository` 共 9 个。方案未展示完整构造器。
- 原有 `createAlertIfNeeded` 被 `createAlertWithCooldown` 替代，但 `autoResolveFenceAlerts` 和 `autoResolveOppositeTypeAlerts` 的调用关系是否保留不明确。
- 治理管道是"包裹"现有围栏检测还是"替换"——方案的伪代码逻辑（`pos.isPositionConfirmed()` → 是否进入围栏检测）是包裹模式，但实际围栏检测用了 `fence.contains(governedPos)` 直接替代了 `FenceBreachDetector`，`FenceBreachDetector` 被绕过了。

**修复建议**: Task 6 应给出完整的 `onMessage` 方法实现，明确哪些原始逻辑保留、哪些替换。

---

### I3. GpsGovernanceState 的 buffer 中值滤波实现缺失

**代码事实**: 方案 Task 3 的 `GpsGovernanceState` 定义了 `pushToBuffer` 和 `isBufferReady`，但 `GpsGovernanceService.evaluate()` 中调用了 `state.getBufferMedianLat()` 和 `state.getBufferMedianLon()`——这两个方法在 `GpsGovernanceState` 的类定义中**没有实现**。

**修复建议**: `GpsGovernanceState` 需补充中值计算方法。注意：经纬度是二维空间，分别对 lat 和 lon 取一维中值在几何上不严谨（中值的坐标点可能不在实际数据点中），但对于去除抖动足够用，需在注释中说明这个取舍。

---

### I4. Redis 治理状态的并发竞态风险

**问题**: `GpsGovernanceService.evaluate()` 直接 mutate `GpsGovernanceState`（`pushToBuffer`, `setConfirmedPosition`），然后 `positionStateCache.saveState()`。在 RocketMQ 并发消费或多实例部署场景下，同一 livestock 的两条 GPS 消息可能**同时读取同一 state → 各自 mutate → 后写覆盖先写**，导致 buffer 丢点或确认位置回退。

**修复建议**:
- 方案需说明消费并发度策略（RocketMQ consumerGroup 默认并发消费）。
- 考虑用 Redis 原子操作（Lua 脚本）或乐观锁（CAS on `updatedAt`），或将同一 livestock 的消息路由到同一消费队列。

---

## 设计建议（SUGGESTION — 不阻塞但建议采纳）

### S1. buffer 窗口大小硬编码为 5

`GpsGovernanceState` 的 buffer 上限硬编码为 5。在 30 分钟采样间隔下，5 个点 = 2.5 小时窗口。如果牛在 2 小时内从 A 移动到 B 再返回，中值仍指向 A 附近，导致"确认位置"滞后。建议窗口大小设为可配置参数，或考虑时间加权（最近点权重更高）。

### S2. FallbackCalibration 的保守默认值过松

`FallbackCalibration.GPS_JITTER_RADIUS = 142m` 意味着未标定设备的位移确认阈值默认 142m。牛在围栏边界附近走动 100m 完全正常，但系统会把它判为"抖动"而不触发告警。这与需求 §8.2 "真实越界不遗漏"存在张力。建议冷启动阶段用更紧的默认值（如 50m），牺牲少量误报换取不漏报，待标定完成后切换到设备参数。

### S3. 治理输出的"位置确认"语义与围栏检测的交互需明确

方案中 `GovernedPosition.isPositionConfirmed()` 为 false 时跳过围栏检测。但牛确实在围栏外（真实越界），只是位移在抖动范围内——此时不触发告警是正确的，但当牛回到围栏内时 `autoResolveFenceAlerts` 也不会被调用（因为 pos 未确认就不走围栏检测分支）。方案的伪代码中对此有处理（"位置回到围栏内 → 仍需解除告警"），但逻辑嵌套在 `!pos.isPositionConfirmed()` 分支内，需确保解除逻辑不遗漏。

---

## 结论

| 维度 | 评价 |
|------|------|
| 架构方向 | ✅ 正确——治理层位于围栏检测上游 |
| Task 分解 | ✅ 清晰——15 个 Task，依赖图合理 |
| 代码事实对齐 | ❌ **3 个 BLOCKER**——加速度计数据流断裂、字段名不一致、冷却期查询缺失 |
| 完整性 | ⚠️ Task 5 为空壳、Task 6 不完整 |
| 向后兼容 | ✅ §6.4 有考虑——非 blade 来源和未标定设备有 fallback |

**建议**: 修订方案，解决 B1-B3 三个阻塞性问题后，再启动实施。

---

## 附：PoC 数据核查（2026-07-13 补充）

> 数据来源：`business-platform/hkt-blade-device-docking/scripts/20260713.txt`（blade 平台 7 台设备的实际遥测输出）

### blade 物模型证实：GPS + 加速度计是同一条记录的字段

PoC 输出末尾的 Thing Model（Step 7）定义了 CATTLE_TRACKER 设备类型的全部属性：

```
latitude / longitude / stepNumber          ← 定位 + 步数
xAxisDirectionAccelerationValue / Y / Z    ← 加速度计三轴
battery / software / hardware / workMode   ← 设备运行状态
```

这些属性属于**同一个物模型**。Step 6 的历史数据验证了这一点——每条 uplink 记录的格式是：

```
ReportTime              Lat    Lon Step |  AccX(g)  AccY(g)  AccZ(g)  |Mag|   Roll  Pitch Activity
07/13/2026 17:18:51  28.246612 112.851544   98 |   -1.228   -0.816   -0.408 1.530g -116.6d  53.4d   active
```

**同一条记录、同一个时间戳，同时携带 GPS 坐标和加速度计三轴数据。**

### 对 B1 BLOCKER 的修正

**原评审表述**：加速度计数据"走另一条事件链路（`TelemetryReceivedEvent`），与围栏检测消费的 `gps-log-updated` 是两条完全独立的事件链路"。

**修正后的表述**：blade 原始数据中 GPS 与加速度计**天然对齐**（同一 uplink 记录的字段）。问题出在系统的 `TelemetryIngestionService.ingest()` 在入库时**主动拆分**了这份天然对齐的数据：
- `extractAndLogGps()` → 只取 lat/lon → 写 `gps_logs` → 发 `GpsLogUpdatedEvent`（仅 4 字段）
- `logDeviceTelemetry()` → 写全字段到 `device_telemetry_logs`

**B1 BLOCKER 结论：依然成立。** `GpsLogUpdatedEvent` 确实不含加速度计数据，围栏检测链路拿不到 `motionIntensity`/`stepNumber`。

**但 PoC 数据强化了修复建议 1 的可行性**：既然 blade 端 GPS 和加速度计天然在同一条 `readings` 中，且 `extractAndLogGps()` 和 `logDeviceTelemetry()` 在 `ingest()` 的同一事务中处理同一份 `readings`，那么**扩展 `GpsLogUpdatedEvent` 捎带加速度计快照是最自然的方案**——只需在组装事件时从同一份 `readings` 中取出加速度计字段，无需跨表查询或跨 topic 时序对齐。

### 对 B2 BLOCKER 的确认

PoC 数据确认了 EUI 的真实格式：`00956906000285d8`（16 字符 hex 前缀 + 设备 ID）。代码中 `Device.devEui` 字段、`dev_eui VARCHAR(16)` DB 列与此一致。方案中的 `eui` 命名不匹配问题**不变**。

### 对 B3 BLOCKER 的确认

B3 是纯代码层面问题（`AlertRepository` 缺少冷却期查询方法），PoC 数据不影响其判断。**不变**。

### PoC 数据的额外发现

1. **GPS 定位失败时加速度计仍上报**：设备 8ea6 的大量记录 `Lat=0 Lon=0` 但加速度计有数据。说明设备端 GPS 和加速度计是独立采集的，但 blade 平台在一条 uplink 中统一上报。`extractAndLogGps()` 需要处理 `lat=0, lon=0` 的情况（无效 GPS 不应写入 `gps_logs` 或不应触发围栏检测）。

2. **采样间隔可变**：Thing Model 定义了 `fixedReportInterval`、`segment1ReportInterval`、`idleReportInterval` 等多种上报间隔配置，说明设备支持分时段/分状态的不同上报频率。当前方案按 30 分钟固定间隔设计，但实际数据中间隔在 28-31 分钟之间波动（且有重复上报，如 `07/13 09:48:48` 和 `09:49:02` 仅差 14 秒）。

3. **加速度计静止判别改进方向得到验证**：设备 85d8（100 条记录，Stationary: 99 samples, mean|mag|=0.988g）的数据证实 `motion_intensity` 连续值比 `activity_class` 离散分类更有参考价值——其 1 条 active 样本的 |mag|=1.530g 明显偏离静止均值 0.988g，阈值区分度足够。
