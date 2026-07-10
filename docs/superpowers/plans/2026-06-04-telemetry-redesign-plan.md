# Telemetry 通用遥测管道重构 实施计划

> 日期: 2026-06-04
> 设计规格: `docs/superpowers/specs/2026-06-04-telemetry-redesign-spec.md`
> 跨域解耦规格: `docs/superpowers/specs/2026-06-04-cross-context-decoupling-design.md`
> 协议依据:
>   - `docs/LoRaWAN 牛羊追踪器上行 Payload 解析协议定义.md`
>   - `docs/LoRa WAN瘤胃胶囊上行Payload解析协议定义.md`

---

## 设计约束

所有跨限界上下文通信必须遵循解耦规格：
- **事件**：走 RocketMQ pub/sub（非 @EventListener）
- **查询**：走 ACL 端口（非直接引用其他上下文 Repository）
- 验证标准：每个上下文 domain 层零跨域 import

---

## 依赖关系

```
R1a (事件模型) → R1b (管道重构 + ACL) → R1c (Health Consumer + ACL)
                                         ↓
                                    R2a (仿真器 + ACL) → R2b (配置)
                                                            ↓
                                                       R3 (验证+清理)
```

---

### Batch R1: 事件模型 + 管道 + Health 消费端

**Task R1a: TelemetryReceivedEvent + 清理旧事件**
- 上下文: IoT + Shared
- 步骤:
  1. 创建 `iot/domain/event/TelemetryReceivedEvent.java`
     - 字段: `deviceId`, `livestockId`, `farmId`, `deviceType` (DeviceType), `readings` (Map<String,Object>), `recordedAt`
  2. 删除 `iot/domain/event/SensorTelemetryReceivedEvent.java`
  3. `Topics.java`: `SENSOR_TELEMETRY_RECEIVED` → `TELEMETRY_RECEIVED`
  4. `SpringEventPublisher`: 方法改为 `onTelemetryReceived(TelemetryReceivedEvent)`
- 验证: 编译（此时 Health 端仍引用旧事件，R1c 修复）
- 产出: 3 文件变更 + 1 删除

**Task R1b: TelemetryIngestionService 重构为通用管道 + IoT ACL 端口**
- 上下文: IoT
- 步骤:
  1. 新建 ACL 端口:
     - `iot/domain/port/RanchQueryPort.java` (接口)
     - `iot/domain/port/dto/LivestockInfo.java` (record: id, farmId, livestockCode, gender)
     - `iot/infrastructure/acl/RanchQueryPortImpl.java` (进程内实现)
  2. 重构 TelemetryIngestionService:
     - 删除 `LivestockRepository` 跨域引用，改用 `RanchQueryPort`
     - 移除 `buildEvent()` 中 DeviceType 分支逻辑
     - 透传 readings Map 构建 TelemetryReceivedEvent
     - 新增设备运维更新: 从 readings 提取 `batteryLevel`/`batteryVoltage` → `device.updateRuntimeStatus()`
     - 新增 GPS 提取: TRACKER readings 含 `latitude`/`longitude` → `GpsLogApplicationService.logGps()`（同上下文，无需 ACL）
     - 注入 `GpsLogApplicationService`
     - `ingest()` 改为 `@Transactional`（读写）
  3. 更新 `TelemetryIngestionServiceTest`（6 个测试适配新签名，Mock RanchQueryPort）
- 验证: 单元测试通过 + `rg "import com.smartlivestock.ranch" iot/domain/` 零结果
- 产出: TelemetryIngestionService.java + ACL 端口 3 文件 + 测试

**Task R1c: Health RocketMQ Consumer + Health ACL 端口**
- 上下文: Health
- 步骤:
  1. 新建 ACL 端口:
     - `health/domain/port/RanchQueryPort.java` (接口: findLivestockById)
     - `health/domain/port/RanchCommandPort.java` (接口: createAlert)
     - `health/domain/port/dto/LivestockInfo.java` (record: id, farmId, livestockCode, gender)
     - `health/domain/port/dto/AlertInfo.java` (record: farmId, livestockId, type, severity, message)
     - `health/infrastructure/acl/RanchQueryPortImpl.java` (进程内实现)
     - `health/infrastructure/acl/RanchCommandPortImpl.java` (进程内实现)
  2. 新建 RocketMQ Consumer:
     - `health/infrastructure/mq/TelemetryEventConsumer.java`
     - `@RocketMQMessageListener(topic = "telemetry-received", consumerGroup = "health-telemetry-consumer")`
     - 反序列化 JSON → TelemetryReceivedEvent → 调 HealthApplicationService
  3. 删除 `health/infrastructure/event/SensorTelemetryEventHandler.java`
  4. 修改 `HealthApplicationService.processTelemetry()`:
     - 签名改为 `(deviceId, livestockId, farmId, deviceType, readings, recordedAt)`
     - 删除 Ranch `LivestockRepository` / `AlertRepository` 跨域引用
     - 注入 `RanchQueryPort` + `RanchCommandPort`
     - CAPSULE: `temperatures` 展开为 7 条 TemperatureLog，`gastricMotility` /100000
     - TRACKER: `stepCount` / `distanceMeters` → ActivityLog
  5. 更新 `HealthApplicationServiceTelemetryTest`（7 个测试，Mock ACL 端口）
- 验证: 单元测试通过 + `rg "import com.smartlivestock.ranch" health/domain/` 零结果
- 产出: TelemetryEventConsumer + ACL 端口 6 文件 + HealthApplicationService + 测试 + 1 删除

### Batch R2: TelemetrySimulator 重写 + ACL

**Task R2a: SimulationState + TRACKER/CAPSULE 数据生成 + IoT ACL 扩展**
- 上下文: IoT
- 步骤:
  1. 扩展 IoT ACL 端口（R1b 只建了 RanchQueryPort）:
     - `iot/domain/port/RanchQueryPort` 新增 `findFencesByFarmId` 方法
     - `iot/domain/port/dto/FenceInfo.java` (record: id, name, coordinates)
     - `iot/domain/port/IdentityQueryPort.java` (接口: findFarmById)
     - `iot/domain/port/dto/FarmInfo.java` (record: id, centerLat, centerLng)
     - `iot/infrastructure/acl/IdentityQueryPortImpl.java`
     - `RanchQueryPortImpl` 补充 findFencesByFarmId 实现
  2. 重写 `TelemetrySimulator.java`:
     - 删除 `FarmRepository`, `FenceRepository`, `LivestockRepository` 跨域引用
     - 注入 `RanchQueryPort`, `IdentityQueryPort`（已通过 R1b 部分建立）
     - 内部类 `SimulationState`，`ConcurrentHashMap<Long, SimulationState>` 按 livestockId 维护
     - TRACKER 生成:
       - `latitude`/`longitude`: 通过 RanchQueryPort 获取围栏，围栏内随机点
       - `stepCount`: 白天 800–2500, 夜间 50–300, 发情 ×2.5
       - `accelX/Y/Z`: 基于活动量的合理值
       - `batteryLevel`: 缓慢衰减 (0-100)
     - CAPSULE 生成:
       - `temperatures`: 7 个温度点（基线 + 6 delta），围绕个体基线
       - `gastricMotility`: u32 原始值，围绕基线 ±噪声
       - `accelX/Y/Z`: u8 合理值
       - `batteryVoltage`: 2800~3600 mV
     - 昼夜节律: hourFactor(6-20=1.0, 其余=0.2)
     - 异常模拟: 5% abnormalTemp, 3% abnormalMotility, 5% 雌性 inEstrus
  3. InstallationController 也改用 RanchQueryPort（替代直接引用 LivestockRepository）
- 验证: `compileJava` 通过 + `rg "import com.smartlivestock.ranch" iot/domain/` 零结果 + `rg "import com.smartlivestock.identity" iot/domain/` 零结果
- 产出: TelemetrySimulator.java 完整重写 + ACL 扩展 4 文件 + InstallationController 修改

**Task R2b: application.yml 配置调整**
- 步骤:
  1. `gps.simulator.enabled` 默认改为 `false`
  2. 保留 gps.simulator 配置段
  3. telemetry.simulator.enabled 保持 `true`
- 产出: application.yml

### Batch R3: 验证 + 清理

**Task R3a: 编译 + 全量单元测试**
- 验证: compileJava 成功, 332+ 单元测试通过

**Task R3b: 清理旧引用 + 跨域 import 零验证**
- 步骤:
  1. 确认 `SensorTelemetryReceivedEvent.java` 已删除
  2. 确认 `SensorTelemetryEventHandler.java` 已删除
  3. `rg "SensorTelemetryReceivedEvent" src/main/` 零引用
  4. `rg "sensor_telemetry_received" src/main/` 零引用
  5. **跨域 import 零验证**（domain 层不含跨域 import）:
     - `rg "import com.smartlivestock.ranch" iot/domain/` 零结果
     - `rg "import com.smartlivestock.identity" iot/domain/` 零结果
     - `rg "import com.smartlivestock.iot" health/domain/` 零结果
     - `rg "import com.smartlivestock.ranch" health/domain/` 零结果
  6. 允许 infrastructure 层有跨域 import（ACL 实现类需要调用其他上下文 Repository）

---

## 风险与缓解

| 风险 | 缓解 |
|------|------|
| gastricMotility 单位未定义，映射到 frequency 有损 | 用 /100000 临时映射，待协议明确后修正 |
| CAPSULE 7 温度点展开增加 TemperatureLog 写入量 | 单次 7 条，30min 间隔，可接受 |
| GPS 重复生成（两个 Simulator 同时运行） | gps.simulator.enabled 默认 false |
| readings key 拼写不一致 | spec 定义 key 表，代码中统一 |
| RocketMQ Consumer 单体内与 Producer 同进程 | 正常行为——RocketMQ 支持同进程 pub/sub |
| TelemetryEventConsumer 反序列化事件 JSON | 事件类实现 Serializable，ObjectMapper 处理 |
| ACL 端口实现类在 infrastructure 层引用其他上下文 | 预期行为——只有 domain 层要求零跨域 import |

---

## 与跨域解耦规格的关系

本计划是 `2026-06-04-cross-context-decoupling-design.md` 的**第一个实施子集**，覆盖 IoT + Health 两个上下文的解耦。其余上下文（Identity、Commerce、Ranch、Platform）的解耦将在单独的计划中实施。

---

## 执行上下文：3 份 Plan × 2 份 Spec 交叉比对

### 文件清单

| 类型 | 文件 | 说明 |
|------|------|------|
| Spec 1 | `2026-06-04-telemetry-redesign-spec.md` | 遥测管道重构设计 |
| Spec 2 | `2026-06-04-cross-context-decoupling-design.md` | 跨域解耦设计 |
| Plan A（旧） | `2026-06-04-iot-telemetry-ingestion-plan.md` | 旧版 14 Task 计划，T1-T11 已实现 |
| Plan B（本文件） | `2026-06-04-telemetry-redesign-plan.md` | 遥测重构（R1-R3），替换旧 Plan T2-T8/T11 |
| Plan C | `2026-06-04-cross-context-decoupling-plan.md` | 跨域解耦（D1-D7） |

### Plan A（旧）任务状态

| 旧 Task | 内容 | 代码已存在 | 本 Plan 覆盖 | 说明 |
|---------|------|-----------|-------------|------|
| T1 | V25 迁移（坐标+ACCELEROMETER清理） | ✅ | — | 已完成，无需重复 |
| T2 | SensorTelemetryReceivedEvent | ✅ | R1a 替换为 TelemetryReceivedEvent | — |
| T3 | TelemetryIngestionService | ✅ | R1b 重构 | — |
| T4 | TelemetryController | ✅ | — | HTTP API 契约不变 |
| T5 | Topics + SpringEventPublisher | ✅ | R1a 更新 | — |
| T6 | SensorTelemetryEventHandler | ✅ | R1c 删除→RocketMQ Consumer | — |
| T7 | HealthApplicationService.processTelemetry | ✅ | R1c 重构 | — |
| T8 | TelemetrySimulator | ✅ | R2a 重写 | — |
| T9 | GpsLogApplicationService 发布事件 | ✅ | — | 已完成 |
| T10 | GpsSimulator 围栏感知 | ✅ | — | 保留，默认关闭 |
| T11 | application.yml | ✅ | R2b 调整 | — |
| **T12** | **前端 TwinOverview 对接** | **❌** | **❌** | **Gap：移至 Phase 3** |
| **T13** | **前端 StatsPage 实现** | **❌** | **❌** | **Gap：移至 Phase 3** |
| **T14** | **部署 + E2E 验证** | **❌** | **❌** | **Gap：移至 Phase 3** |

### Spec 覆盖矩阵

**Spec 1（Telemetry Redesign）**：

| Spec 章节 | Plan B (R1-R3) | Plan C (D1-D7) |
|-----------|---------------|----------------|
| §1 真实设备数据模型 | ✅ R1a, R1b | — |
| §2 架构设计（数据流） | ✅ R1a→R1c 全链路 | — |
| §3 TelemetrySimulator | ✅ R2a | — |
| §4 Health 消费端 | ✅ R1c | — |
| §5 变更范围 | ✅ 全部 | — |
| §2.4 跨域通信 | ✅ R1b (ACL), R1c (RocketMQ) | ✅ D2-D6 (其余上下文) |

**Spec 2（Cross-Context Decoupling）**：

| Spec 章节 | Plan B (R1-R3) | Plan C (D1-D7) |
|-----------|---------------|----------------|
| §3 RocketMQ Consumer 补齐 | ✅ R1c (Health Consumer) | ✅ D2 (Ranch), D5 (Platform) |
| §4 ACL 查询端口 | ✅ R1b (IoT→Ranch), R1c (Health→Ranch) | ✅ D2-D6 |
| §5 Commerce 事件桥接 | — | ✅ D1 |
| §6 变更范围 | ✅ IoT + Health 部分 | ✅ 其余全部 |

### 全局执行顺序

```
Phase 1: Plan B（本文件）— Telemetry Redesign (R1→R2→R3)
  │  重构 IoT + Health 两个上下文的遥测管道
  │  同时引入 ACL + RocketMQ（作为解耦的起点）
  ↓
Phase 2: Plan C — Cross-Context Decoupling (D1→D2→D3→D4→D5→D6→D7)
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

T1-T11 已全部在代码中实现，且将被 Plan B 重构覆盖。**Plan A 归档，不再执行。** 仅保留 T12-T14 移至 Phase 3。
