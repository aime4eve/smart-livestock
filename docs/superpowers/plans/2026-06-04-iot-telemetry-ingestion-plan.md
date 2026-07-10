# IoT 遥测数据采集 + 健康模拟器 实施计划

> 日期: 2026-06-04（评审修订版）
> 设计规格: `docs/superpowers/specs/2026-06-03-iot-telemetry-ingestion-design.md`
> 预估工时: ~21.5h
> 任务编号与设计规格 §9 完全一致

---

## 实施顺序

任务按依赖关系排列，共 14 个 Task，分 5 批交付。

### Batch 1: 数据基础修正（先修地基）

> 修正坐标体系和清理错误设备类型，后续所有功能依赖正确的种子数据。

**Task 1: V25 迁移 — 修正 Farm 1 坐标 + 清理 ACCELEROMETER + DeviceType 枚举移除**
- 上下文: DB Migration + IoT (Java)
- 验证: 部署后 `SELECT latitude, longitude FROM farms WHERE id=1` 返回 `(28.229, 112.938)`；`./gradlew compileJava` 通过
- 步骤:
  1. 新建 `V25__fix_farm1_coords_and_remove_accelerometer.sql`:
     - UPDATE farms SET latitude=28.229, longitude=112.938 WHERE id=1
     - UPDATE devices SET status='DECOMMISSIONED' WHERE device_type='ACCELEROMETER'
     - ALTER TABLE devices 收窄 CHECK 约束移除 ACCELEROMETER
  2. DeviceType.java 移除 ACCELEROMETER
  3. OpenDeviceRegisterController 注释更新
- 产出: V25 迁移文件 + DeviceType.java 变更

### Batch 2: IoT 遥测链路核心（数据写入管道）

> 建立 IoT → Health 的完整遥测数据管道。

**Task 2: SensorTelemetryReceivedEvent 领域事件**
- 上下文: IoT
- 验证: 编译通过
- 步骤:
  1. 创建 `iot/domain/event/SensorTelemetryReceivedEvent.java`
  2. 字段: deviceId, livestockId, farmId, telemetryType, temperature, motilityFrequency, motilityIntensity, activityIndex, stepCount, distanceMeters, recordedAt
- 产出: SensorTelemetryReceivedEvent.java

**Task 3: TelemetryIngestionService**
- 上下文: IoT
- 验证: 单元测试验证事件发布
- 步骤:
  1. 创建 `iot/application/TelemetryIngestionService.java`
  2. ingest(deviceId, payload): 验证设备+安装 → 解析 livestockId/farmId → 发布事件
  3. 跨上下文依赖: InstallationRepository (IoT), LivestockRepository (Ranch，已有先例)
  4. 写单元测试
- 产出: TelemetryIngestionService.java + 测试

**Task 4: TelemetryController (App API)**
- 上下文: IoT
- 验证: `./gradlew compileJava` 通过
- 步骤:
  1. 创建 `iot/interfaces/TelemetryController.java`
  2. POST `/api/v1/farms/{farmId}/telemetry`（独立 Controller，不嵌套在 DeviceController 下）
  3. body 中包含 deviceId + readings 数组
  4. JWT 认证，验证 farm 归属
  5. 调用 TelemetryIngestionService
- 产出: TelemetryController.java

**Task 5: Topics 常量 + SpringEventPublisher 桥接**
- 上下文: Shared
- 验证: 编译通过
- 步骤:
  1. Topics.java 新增 `SENSOR_TELEMETRY_RECEIVED`
  2. SpringEventPublisher.java 新增 `onSensorTelemetryReceived` 桥接方法
- 产出: Topics.java, SpringEventPublisher.java 变更

### Batch 3: Health 消费端 + 分析管线

> Health 上下文消费遥测事件，写入时序表并驱动分析。

**Task 6: SensorTelemetryEventHandler**
- 上下文: Health
- 验证: 编译通过
- 步骤:
  1. 创建 `health/infrastructure/event/SensorTelemetryEventHandler.java`
  2. @EventListener → 调用 HealthApplicationService.processTelemetry()
- 产出: SensorTelemetryEventHandler.java

**Task 7: HealthApplicationService.processTelemetry()**
- 上下文: Health
- 验证: 单元测试验证时序数据写入 + Snapshot 更新
- 步骤:
  1. 新增 processTelemetry() 方法
  2. ingestTemperature(): 写 temperature_logs + FeverAnalysisService 评估
  3. ingestMotility(): 写 rumen_motility_logs + DigestiveAnalysisService 评估
  4. ingestActivity(): 写 activity_logs（区分 CAPSULE/TRACKER 来源）
  5. refreshSnapshot(): 更新 HealthSnapshot + EstrusScore
  6. 写单元测试
- 产出: HealthApplicationService.java 变更 + 测试

### Batch 4: 模拟器 + GPS 修正

> 建立模拟数据源，修正现有 GPS 链路。

**Task 8: TelemetrySimulator (CAPSULE + TRACKER)**
- 上下文: IoT
- 验证: 启用后数据库中写入新时序数据
- 步骤:
  1. 创建 `iot/application/service/TelemetrySimulator.java`
  2. @ConditionalOnProperty + @Scheduled
  3. 查活跃安装，按设备类型分支生成数据
  4. CAPSULE: temperature + motility + activity_index
  5. TRACKER: step_count + distance_meters
  6. 全部调用 TelemetryIngestionService
- 产出: TelemetrySimulator.java

**Task 9: 修正 GpsLogApplicationService 发布 GpsLogUpdatedEvent**
- 上下文: IoT
- 验证: GPS 日志写入后 GpsLogEventHandler 被触发
- 步骤:
  1. 在 GpsLogApplicationService.logGps() 保存后，通过 ApplicationEventPublisher 发布 GpsLogUpdatedEvent
  2. 注意: logGps 需要 @Transactional 改为读写事务
- 产出: GpsLogApplicationService.java 变更

**Task 10: 修正 GpsSimulator — 按围栏区域生成轨迹**
- 上下文: IoT
- 验证: GPS 轨迹在围栏内 + 围栏越界告警正确触发
- 步骤:
  1. GpsSimulator 注入 FenceRepository（跨上下文只读）和 LivestockRepository（已有先例）
  2. 对每个 Installation: 通过 livestock → farmId → fences 获取围栏
  3. 在围栏多边形内生成随机点（bounding box 采样 + point-in-polygon 拒绝法）
  4. 无围栏时 fallback 到 farm 中心 + 小偏移
  5. 注意: @Transactional 不能标记为 readOnly（需要写 GPS 日志）
- 产出: GpsSimulator.java 变更

**Task 11: 配置参数 application.yml**
- 上下文: Config
- 验证: application.yml 包含完整配置段
- 步骤:
  1. 新增 telemetry.simulator 配置段（CAPSULE + TRACKER 参数）
  2. 修正 gps.simulator.center-lat/lng 为围栏中心 (28.229, 112.938)
- 产出: application.yml 变更

### Batch 5: 前端对接 + 端到端验证

> 前端展示真实数据，全链路验证。

**Task 12: 前端 TwinOverview 对接 health/overview**
- 上下文: Flutter
- 验证: TwinOverviewPage 显示实时场景摘要（发热/消化/发情/疫病）
- 步骤:
  1. 新增 HealthOverview Repository + Controller (Riverpod)
  2. 调用 GET /farms/{farmId}/health/overview
  3. 用 sceneSummary 替换硬编码场景卡片
  4. 显示 pendingTasks
  5. 空状态兜底
- 产出: Flutter 代码变更

**Task 13: 前端 StatsPage 实现**
- 上下文: Flutter
- 验证: StatsPage 显示 7 天/30 天统计图表
- 步骤:
  1. StatsRepository 改为异步 API 调用
  2. 新增 StatsApiRepository 聚合多个 API
  3. 时间范围选择器
  4. 图表: 健康率、告警数、设备在线率
  5. 空状态兜底
- 产出: Flutter 代码变更

**Task 14: 部署 + 端到端验证**
- 上下文: Test + Deploy
- 验证:
  - 部署后模拟器启用 (`telemetry.simulator.enabled=true`)
  - 等待 30 分钟让模拟器积累足够时序数据（温度 30min 采样间隔，需等待至少 1~2 个采样周期）
  - GET /health/overview 返回非空 sceneSummary
  - TwinOverviewPage 显示实时数据
  - GPS 轨迹在围栏内
  - 围栏越界告警正确触发（偶尔因随机偏移）
  - StatsPage 显示图表
- 步骤:
  1. bootJar + rsync + docker compose build + up
  2. 开启模拟器配置
  3. 等待 30 分钟数据积累
  4. 前端 Live 模式连接验证
  5. 逐页面检查
- 产出: 验证报告

---

## 风险与缓解

| 风险 | 缓解 |
|------|------|
| 围栏多边形内随机点算法复杂度 | 用 bounding box 采样 + point-in-polygon 拒绝法，简单可靠 |
| 模拟器大量写入导致分区表空间增长 | 30 天自动清理（可后续加 partition management job） |
| FenceRepository 跨上下文注入 | 已有先例（Health 注入 Ranch LivestockRepository，IoT InstallationController 注入 Ranch LivestockRepository） |
| 种子数据时间线过旧 | 模拟器启动后持续写入新数据；首次部署需等待 ~30 分钟积累数据，前端空状态兜底 |
| 首次部署验证等待时间长 | 验证步骤明确标注等待 30 分钟而非 5 分钟 |
