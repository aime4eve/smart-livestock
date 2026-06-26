# GPS 模拟数据收敛设计规格

> 版本: 1.0 | 日期: 2026-06-26 | 状态: 待实施
> 关联: [datagen 限界上下文设计](./2026-06-26-datagen-context-design.md) §7.2（GpsSimulator 暂不迁移）

## 1. 问题

当前 GPS 模拟数据存在双写和 placeholder 问题：

- **GpsSimulator**（默认关闭）：独立生成围栏感知 GPS 坐标，直接注入 Ranch/Identity 跨上下文仓储，违反洋葱架构
- **TelemetrySimulator**（默认开启）：TRACKER 分支生成写死的长沙中心点坐标 `28.229±0.005, 112.938±0.005`，与围栏无任何关系
- 两个模拟器都汇入同一个 `GpsLogApplicationService.logGps()`，若同时开启会产生坐标冲突
- 默认配置下 GPS 走 placeholder 路径，围栏越界检测虽然在跑，但喂进去的坐标不反映真实围栏关系

## 2. 设计原则

**GPS 数据源不应关心围栏。** 围栏是检测层的概念，GPS 数据源只模拟"牲畜在移动"这一事实。越界与否由 `FenceBreachDetector` 根据围栏几何关系判定，与数据源解耦。

## 3. 方案

废弃 GpsSimulator，GPS 生成统一到 TelemetrySimulator TRACKER 分支，用**随机游走**替代围栏内投点。

### 3.1 为什么不用围栏感知投点

GpsSimulator 的拒绝采样（bbox 投点 → ray-casting 判定 → 最多 100 次 → 质心兜底）有两个问题：

1. **语义矛盾**：GPS 永远生成在围栏内 → 越界检测永不触发 → 检测链路成为死代码
2. **架构违规**：需要在 IoT 侧实现第三份 ray-casting（`Fence.contains()` 和 `containsBuffer()` 已是两份重复）

随机游走不依赖任何围栏几何信息，偶尔会自然走出围栏，让越界检测链路被真实触发。

### 3.2 为什么不用每帧独立投点

每个 tick 独立随机点会导致牲畜在地图上"瞬移"。随机游走用 per-livestock 状态记录当前位置，每次 tick 小步偏移，轨迹连续，符合牲畜真实运动特征。

## 4. 实施步骤

### 4.1 扩展 ACL 数据契约

**文件**: `iot/domain/port/dto/LivestockInfo.java`

`LivestockInfo` record 增加 `lastLatitude` / `lastLongitude` 两个字段，用于初始化随机游走起点。

```java
public record LivestockInfo(Long id, Long farmId, String livestockCode, String gender,
                            BigDecimal lastLatitude, BigDecimal lastLongitude) {}
```

**文件**: `iot/infrastructure/acl/RanchQueryPortImpl.java`

`toLivestockInfo()` 从 `Livestock` 映射 `lastLatitude` / `lastLongitude`。

### 4.2 SimulationState 增加随机游走状态

**文件**: `iot/application/service/TelemetrySimulator.java`

`SimulationState` 内部类增加两个字段：

```java
double currentLat;
double currentLng;
```

`create()` 方法签名扩展，接收 `LivestockInfo` 参数：

- `lastLatitude` / `lastLongitude` 非空 → 用作初始位置
- 为空（新建未上报）→ 回退默认坐标 `28.229, 112.938`，log warn

### 4.3 改写 GPS 生成逻辑

**文件**: `iot/application/service/TelemetrySimulator.java`

`generateTrackerReadings()` 中 GPS 部分替换为：

```java
// Random walk: ~20-50m per tick, bearing randomized
double step = rng.nextDouble(0.0002, 0.0005);
double bearing = rng.nextDouble(0, 2 * Math.PI);
state.currentLat += step * Math.sin(bearing);
state.currentLng += step * Math.cos(bearing);
readings.put("latitude", state.currentLat);
readings.put("longitude", state.currentLng);
```

`generateTelemetry()` 主循环中，在创建 `SimulationState` 前补一次 ACL 查询：

```java
LivestockInfo livestock = ranchQueryPort.findLivestockById(livestockId).orElse(null);
if (livestock == null) continue;
SimulationState state = states.computeIfAbsent(livestockId,
    id -> SimulationState.create(device.getDeviceType(), id, livestock));
```

GPS 生成**不依赖围栏**，不调用 `findFencesByFarmId`。围栏只在检测侧（`GpsLogEventConsumer`）使用。

### 4.4 删除 GpsSimulator

- 删除 `iot/application/service/GpsSimulator.java`
- 删除 `application.yml` 中 `gps.simulator` 配置段（第 29-32 行）

无测试引用 GpsSimulator，删除零风险。

### 4.5 编译验证

`./gradlew compileJava` 通过。

## 5. 数据流（收敛后）

```
TelemetrySimulator（唯一模拟器，默认开启）
  └─ TRACKER 分支：
       └─ SimulationState.currentLat/currentLng 随机游走
       └─ readings["latitude"] / ["longitude"]
       └─ 其余遥测（步数/电量/加速度）不变
         ↓
  TelemetryIngestionService.ingest()
       └─ extractAndLogGps() → gps_logs 落库 → GpsLogUpdatedEvent
         ↓
  GpsLogEventConsumer → FenceBreachDetector → 告警
```

## 6. 与 datagen 上下文的关系

[datagen 设计规格](./2026-06-26-datagen-context-design.md) 计划将 TelemetrySimulator 整体迁移到独立的 datagen 限界上下文。该规格 §7.2 明确写了"GpsSimulator 暂不迁移"，将 GPS 问题搁置。

本方案补上这个空缺。当 datagen 落地时，随机游走逻辑会和其他 reading 生成逻辑一起自然迁移进 `SynthesisService.generate()`，不需要额外工作。

**与 datagen 无冲突**：datagen 当前为纯设计（待评审，无代码），本方案改动的是 IoT 上下文内的 TelemetrySimulator，不影响 datagen 的 ACL 契约设计。

## 7. 范围外（记录待办）

| 项 | 说明 |
|---|---|
| buffer_polygon 为空 | V9/V17 seed 围栏的 buffer_polygon 为 NULL，FENCE_APPROACH 三态塌缩为二态。需独立 backfill 迁移 |
| 前端定时刷新 | RanchController 无 Timer.periodic，越界告警需手动 refresh 才可见。需独立前端任务 |
| TelemetrySimulator inEstrus 性别判定 | `create()` 里有 `// simplified: no gender check`，LivestockInfo 已有 gender，可顺带修但属无关改动 |
