# Demo 数据与场景全面增强设计

**日期**: 2026-04-09
**状态**: 已落地（部分）
**复核日期**: 2026-04-09
**方案**: 混合方案（静态种子 + 运行时生成）

---

## 背景与目标

当前 Demo 仅有 3 头牛、2 个围栏、少量时序数据，数据规模不足以支撑客户演示和路演。需要将数据增强到接近真实中型牧场运营水平，同时保持 Demo 的可靠性和可复现性。

**目标受众**: 客户演示/路演
**数据规模**: 50 头牛、4 个围栏、1 周时序数据
**质量优先**: 视觉效果突出、数据真实可信

---

## ID 体系设计

升级前 Demo 曾混用两套 ID；**当前实现**已统一为下列体系，确保跨模块导航（告警 → 牛只详情 → 孪生详情）可正确链接：

| ID 类型 | 格式 | 示例 | 用途 |
|---------|------|------|------|
| `earTag` | `SL-2024-NNN` | `SL-2024-001` | 牛只标识，地图标记、告警关联 |
| `livestockId` | 4 位数字字符串 | `0001` ~ `0050` | 孪生模块查找，路由参数 `/livestock/:id` |
| `deviceId` | `DEV-TYPE-NNN` | `DEV-GPS-001` | 设备标识 |

每头牛同时拥有 `earTag` 和 `livestockId`，通过 `earTag` → `livestockId` 映射表关联。地图和告警通过 `earTag` 引用牛只，孪生模块通过 `livestockId` 查找。牛只详情页同时持有两个 ID，可跳转到孪生详情。

---

## 数据分层策略

| 层 | 数据类型 | 生成方式 | 存储 |
|---|---------|---------|------|
| 确定性层 | 牛只列表、围栏边界、设备清单、告警列表、用户信息 | 静态种子文件 | `demo_seed.dart` / `seed.js` |
| 动态层 | GPS 轨迹、温度曲线、蠕动数据、发情评分趋势 | 运行时算法生成（固定随机种子） | Mock Repository 内的生成器 |

**设计原则**:
- 客户演示路径上的核心数据（牛只身份、围栏、告警）必须是确定性的，保证每次演示一致
- 时序数据（温度、蠕动、GPS）用算法生成，增加数据丰富度和真实感
- 所有生成器使用固定随机种子（`seed: 42`），确保每次应用启动数据一致
- 前后端数据保持对齐

---

## 确定性层数据设计

### 牛只（50 头）

| 属性 | 说明 |
|------|------|
| `earTag` | `SL-2024-001` ~ `SL-2024-050` |
| `livestockId` | `0001` ~ `0050`（与 earTag 一一对应） |
| 品种 | 西门塔尔（20）、安格斯（15）、利木赞（15） |
| 年龄 | 1.5-6 岁，正态分布 |
| 体重 | 350-650 kg，按品种分档 |
| 健康状态 | healthy（43）、watch（4）、abnormal（3） |
| `fenceId` | 所属围栏 ID，通过 GPS 位置推导（牛只在哪个围栏内就属于哪个围栏） |

### 围栏（4 个）

| 围栏 ID | 名称 | 类型 | 面积（亩） | 说明 |
|---------|------|------|----------|------|
| `fence_pasture_a` | 放牧A区 | 放牧 | ~200 | 东北区域，平坦草地 |
| `fence_pasture_b` | 放牧B区 | 放牧 | ~180 | 西南区域，含小溪 |
| `fence_rest` | 夜间休息区 | 休息 | ~30 | 中部，牛舍附近 |
| `fence_quarantine` | 隔离区 | 隔离 | ~10 | 南角，围栏加强 |

围栏坐标数据格式：Dart 端使用 `LatLng(lat, lng)` 元组，JS 端使用 `[lng, lat]` 数组（经度在前），解析时需要反转顺序。

### 设备（100 个）

| 类型 | 数量 | 格式 | 状态分布 |
|------|------|------|---------|
| GPS 追踪器 | 50 | `DEV-GPS-001` ~ `DEV-GPS-050` | online(42), offline(4), lowBattery(4) |
| 瘤胃胶囊 | 30 | `DEV-RC-001` ~ `DEV-RC-030` | online(26), offline(2), lowBattery(2) |
| 加速度计 | 20 | `DEV-ACC-001` ~ `DEV-ACC-020` | online(17), offline(2), lowBattery(1) |

设备通过 `boundEarTag` 字段关联牛只。GPS 1:1 绑定，胶囊绑定 30 头牛（与孪生数据对应）。

### 告警（15-20 条）

告警数据需要重构。当前 `AlertsRepository` 接口和 `AlertsViewData` 模型不支持告警列表。需要先扩展模型和接口，再填充数据。

**模型扩展**:
```dart
class AlertItem {
  final String id;
  final String title;       // '越界 · SL-2024-003'
  final String subtitle;    // '2026-04-08 10:12'
  final String priority;    // 'P0' | 'P1' | 'P2'
  final String type;        // 'geofence' | 'fever' | 'offline' | 'lowbattery' | 'behavior'
  final String stage;       // 'pending' | 'acknowledged' | 'handled' | 'archived'
  final String earTag;      // 关联牛只
  final String? livestockId;// 关联孪生 ID（体温/消化类告警）
}
```

**告警分布**:

| 级别 | 类型 | 数量 | 状态分布 |
|------|------|------|---------|
| P0 紧急 | 越界、高热 | 4 | pending 1, acknowledged 1, handled 2 |
| P1 重要 | 设备离线、低电量 | 5 | pending 2, acknowledged 1, handled 2 |
| P2 一般 | 异常行为、围栏接近 | 5 | pending 1, handled 3, archived 1 |
| 已归档 | 各类型 | 4 | 全部 archived |

### 孪生基线数据（30 头有胶囊牛）

30 头牛是 50 头牛的子集（`livestockId` `0001` ~ `0030`），这些牛安装了瘤胃胶囊。

- 基础体温基线：38.0-39.5°C，按品种微调
- 消化健康等级：正常（25）、轻度异常（3）、中度异常（2）
- 发情状态：非发情期（27）、发情期（3，对应 `livestockId` `0012`、`0024`、`0028`）

### 看板与统计指标

看板展示**当前牧区**（50 头牛）的统计，而非企业级全局数据。

| 指标 | 值 | 说明 |
|------|------|------|
| 牲畜总数 | 50 | 当前牧区 |
| 在线设备 | 85 | 100 台中 85 台在线 (85%) |
| 今日告警 | 8 | 当日新增告警数 |
| 健康率 | 92% | 50 头中 healthy 43 + watch 4 = 94%，取近期 7 天均值 |

孪生概览页保持企业级展示视角（展示多牧区汇总数据），但添加"当前牧区"筛选标注。

---

## 动态层生成器设计

### 文件结构

```
lib/core/data/generators/
├── gps_trajectory_generator.dart
├── temperature_generator.dart
├── motility_generator.dart
└── estrus_score_generator.dart
```

### 通用接口

```dart
abstract class TimeSeriesGenerator<T> {
  List<T> generate({
    required DateTime start,
    required DateTime end,
    required Duration interval,
    Map<String, dynamic>? params,
  });
}
```

所有生成器使用固定随机种子（`Random(42)`），确保每次应用启动数据一致。

### GPS 轨迹生成器

**输入参数**:
- `fenceBoundary`: 围栏多边形顶点列表
- `anchorPoints`: 关键地点（饮水点、喂食点、围栏入口）
- `behaviorSchedule`: 行为时间表（放牧/饮水/休息时段）

**行为模式**:
- **放牧** (6:00-18:00): 缓慢随机游走，速度 0.5-2 km/h，确保轨迹在围栏内
- **饮水/进食**: 向最近锚点移动 → 停留 15-30 分钟 → 恢复放牧
- **休息** (18:00-6:00): 在夜间休息区内小幅移动，半径 <50m

**输出**: `List<GeoPoint>`，每小时 1 个点（7 天 ≈ 168 点/牛）

**异常注入**: 1-2 头牛偶尔接近围栏边界（触发越界告警）

**按需生成**: 地图视图同时显示 50 头牛当前位置标记，但轨迹数据仅在选中单头牛时生成（168 点/牛），避免一次性生成所有牛的轨迹。

### 温度曲线生成器

**输入参数**:
- `baselineTemp`: 基础体温 (38.0-39.5°C)
- `abnormalEvents`: 异常事件列表（时间点 + 持续时长 + 峰值温度）

**生成规则**:
- 基础体温 + 昼夜波动（白天高 0.2°C，夜间低 0.1°C）
- 随机噪声 ±0.1°C（模拟测量误差）
- 异常注入：指定时间点温度突升 1-2°C，持续 6-24 小时后回落

**输出**: `List<TemperatureRecord>`，每 30 分钟 1 个点（7 天 ≈ 336 点/牛）

### 蠕动数据生成器

**输入参数**:
- `healthLevel`: 消化健康等级（正常/轻度/中度异常）
- `feedingSchedule`: 喂食时间表

**生成规则**:
- 进食时段 (6-8, 17-19): 3-5 次/分，蠕动活跃
- 反刍时段 (9-12, 20-23): 1-2 次/分，规律
- 休息时段 (13-16, 0-5): 0.3-0.8 次/分，低频
- 异常牛：整体蠕动降低 30-50%，或出现不规则间隔

**输出**: `List<MotilityRecord>`，每 30 分钟 1 个点（7 天 ≈ 336 点/牛）

### 发情评分生成器

**输入参数**:
- `inEstrus`: 是否当前处于发情期
- `cycleDay`: 当前处于 21 天周期的第几天
- `estrusPeakDay`: 发情高峰日

**生成规则**:
- 非发情期 (day 1-16, day 21): 评分 10-30，小幅波动
- 发情前期 (day 17-18): 评分缓升至 50-60
- 发情高峰 (day 19-20): 评分骤升至 80-100
- 加入 ±5 的随机波动

**输出**: `List<EstrusScore>`，每天 1 个点（7 天 ≈ 7 点/牛）

---

## 改动范围

### 新增文件

| 文件 | 说明 |
|------|------|
| `lib/core/data/generators/gps_trajectory_generator.dart` | GPS 轨迹生成器 |
| `lib/core/data/generators/temperature_generator.dart` | 温度曲线生成器 |
| `lib/core/data/generators/motility_generator.dart` | 蠕动数据生成器 |
| `lib/core/data/generators/estrus_score_generator.dart` | 发情评分生成器 |

### 模型/接口扩展（前置改动）

| 文件 | 改动内容 |
|------|---------|
| `lib/core/models/demo_models.dart` | 新增 `AlertItem` 模型，`LivestockDetail` 添加 `fenceId`、`livestockId` 字段 |
| `lib/features/alerts/domain/alerts_repository.dart` | 接口扩展，支持返回告警列表 |
| `lib/features/map/domain/map_repository.dart` | 接口确保支持按牛只 ID 获取轨迹 |

### 种子数据扩展

| 文件 | 改动内容 |
|------|---------|
| `lib/core/data/demo_seed.dart` | 扩展牛只到 50 头（含 earTag + livestockId 映射）、设备到 100 个、围栏到 4 个、看板指标更新 |
| `lib/core/data/twin_seed.dart` | 扩展孪生基线数据到 30 头牛、使用新的 livestockId 体系、增加异常样本 |
| `backend/data/seed.js` | 后端种子数据同步扩展：50 头牛、100 个设备、4 个围栏、20 条告警、更新看板指标 |
| `backend/data/twin_seed.js` | 后端孪生种子同步扩展：30 头孪生牛、每类 8-12 条记录、7 天时序数据点 |
| `backend/routes/map.js` | 支持 `range` 参数过滤轨迹数据（24h/7d/30d） |

### Mock Repository 改动

| 文件 | 改动内容 |
|------|---------|
| `mock_alerts_repository.dart` | 重构：返回真实告警列表（从种子数据 + AlertItem 模型） |
| `mock_map_repository.dart` | GPS 轨迹从生成器获取（按需生成） |
| `mock_fever_repository.dart` | 温度曲线从生成器获取 |
| `mock_digestive_repository.dart` | 蠕动数据从生成器获取 |
| `mock_estrus_repository.dart` | 发情评分从生成器获取 |
| `mock_livestock_repository.dart` | 关联更多牛只数据，支持 livestockId 查找 |
| `mock_dashboard_repository.dart` | 看板指标更新为 50 头规模 |
| `mock_stats_repository.dart` | 统计数据扩展 |
| `mock_twin_overview_repository.dart` | 孪生概览数据更新 |

### Live Repository 改动

| 文件 | 改动内容 |
|------|---------|
| `live_map_repository.dart` | 修复：不再硬编码引用 `DemoSeed`，改为正确解析 ApiCache 中的轨迹数据 |
| 其他 `live_*_repository.dart` | 确保新字段（livestockId、fenceId）从 ApiCache 正确映射 |

### Mock 配置

| 文件 | 改动内容 |
|------|---------|
| `core/mock/mock_scenarios.dart` | 更新场景中的牛只/设备引用为新 ID 体系 |

---

## 测试影响

以下测试文件引用了种子数据，需要同步更新：

| 测试文件 | 影响点 |
|---------|--------|
| `test/mock_repository_state_test.dart` | 引用 `DemoSeed.dashboardMetrics`、`earTags`，需适配新数据量 |
| `test/mock_repository_override_test.dart` | 硬编码 `'耳标-002'`、`'耳标-X'`，需改为新 earTag 格式 |
| `test/role_visibility_test.dart` | 可能引用角色相关种子数据 |
| `test/flow_smoke_test.dart` | 端到端流程测试，需覆盖新数据路径 |
| `test/highfi/map_fence_highfi_test.dart` | 围栏相关测试，需适配 4 个围栏 |

---

## 性能考虑

- GPS 当前位置: 50 个标记点 → 地图一次性加载，无压力
- GPS 轨迹: 按需生成，选中牛只才生成 168 点 → 无压力
- 温度: 30 牛 × 7 天 × 48 点/天 = 10080 点 → 图表降采样显示（取每小时均值 = 5040 点）
- 蠕动: 30 牛 × 7 天 × 48 点/天 = 10080 点 → 图表降采样显示
- 发情: 30 牛 × 7 天 × 1 点/天 = 210 点 → 无压力

**缓存策略**: 生成器在首次调用时计算并缓存结果，后续访问直接返回缓存。不使用持久化存储。

---

## 前后端数据对齐

采用**手动同步 + 检查清单**方式，不引入构建脚本。原因：生成器仅在 Flutter 端使用，确定性种子数据量可控。

**同步检查清单**:
1. `demo_seed.dart` 中的牛只/围栏/设备数量与 `seed.js` 一致
2. `twin_seed.dart` 中的 livestockId 与 `twin_seed.js` 一致
3. 告警类型和数量前后端一致
4. 看板指标数值前后端一致
5. 坐标顺序：Dart `LatLng(lat, lng)` vs JS `[lng, lat]`

Live 模式下，Mock Server 返回种子数据（确定性），Flutter 端 Live Repository 从 ApiCache 解析。时序数据生成器仅存在于 Flutter Mock Repository 中。

**已知差异（已接受，需在迭代中显式处理或文档化）**:
- `seed.js` **不导出** 100 台设备明细；设备清单与绑定关系以 `demo_seed.dart` 为准。若 Live 模式需要设备 CRUD 与 Dart 完全一致，需扩展后端种子与路由。
- `twin_seed.js` 中体温/蠕动等为 **稀疏占位序列**；与 Flutter `TwinSeed` + 生成器的 **高密度时序** 不一致。Mock 模式演示以客户端为准；Live 模式以 API 返回为准。
- 图表 **降采样**（见下文「性能考虑」）在实现层 **尚未统一落实**；若大图卡顿再补。

---

## 实现偏差（相对本文初稿）

| 主题 | 设计描述 | 当前实现 |
|------|----------|----------|
| 通用接口 | `TimeSeriesGenerator<T>` 抽象类 | 各生成器独立实现，未抽公共抽象 |
| GPS 行为 | 锚点、行为时间表、饮水/休息区、越界异常注入 | 围栏包围盒内随机游走 + 昼夜步长差异；无锚点与显式越界注入 |
| GPS 缓存 | 按牛只缓存轨迹 | ~~已修复~~：`GpsTrajectoryGenerator` 缓存键含 **围栏指纹 + start/end**（PR [#9](https://github.com/aime4eve/smart-livestock/pull/9) / Issue [#2](https://github.com/aime4eve/smart-livestock/issues/2)） |
| 孪生概览 | 企业级汇总 + 「当前牧区」标注 | 数据层未强制；**UI 标注未做**（见「不在范围内」） |

---

## 不在范围内

- UI/UX 改动（本次仅增强数据层）；**孪生概览「当前牧区」筛选/标注**归入后续 UI 迭代
- 真实后端实现
- 性能优化（除非数据量导致明显卡顿）；**图表降采样**若未触发卡顿可延后
- 新增功能模块
- `tools/generate_seeds.dart` 构建脚本（改用手动同步 + 检查清单）

---

## 下一步开发任务（建议）

已在 GitHub 拆分为独立 Issue，并在仓库内维护执行计划：

- **Issue 列表与执行计划**: [plans/2026-04-09-demo-data-followups.md](../plans/2026-04-09-demo-data-followups.md)
- **P0** — ~~[#2](https://github.com/aime4eve/smart-livestock/issues/2) GPS 轨迹缓存键~~ **已完成**（PR [#9](https://github.com/aime4eve/smart-livestock/pull/9)）
- **P1** — [#3](https://github.com/aime4eve/smart-livestock/issues/3) 孪生体温/蠕动图表降采样；[#4](https://github.com/aime4eve/smart-livestock/issues/4) GPS 行为逼真度（可选）
- **P2** — [#5](https://github.com/aime4eve/smart-livestock/issues/5) Live 孪生时序对齐；[#6](https://github.com/aime4eve/smart-livestock/issues/6) 后端设备种子；[#7](https://github.com/aime4eve/smart-livestock/issues/7) 孪生概览「当前牧区」UI
- **P3** — [#8](https://github.com/aime4eve/smart-livestock/issues/8) `TimeSeriesGenerator` 抽象（可选）

（以下为原始条目备忘，与 Issue 一一对应。）

1. **P0 — GPS 轨迹缓存键**：~~同上~~ → **#2** ✅（PR [#9](https://github.com/aime4eve/smart-livestock/pull/9)）
2. **P1 — 图表降采样**：在孪生体温/蠕动图表数据绑定前，对长序列做按小时均值或固定上限点数抽样，与设计文档「性能考虑」对齐；真机验证后再定阈值。→ **#3**
3. **P1 — GPS 行为逼真度（可选）**：按设计补充锚点、休息区 `fence_rest`、接近边界采样等，仅影响 Mock 演示路径。→ **#4**
4. **P2 — Live 孪生时序对齐**：若产品要求 Live 与 Mock 曲线一致，扩展 `twin_seed.js` 与 twin 相关 API，或约定「Live 为简化曲线」并在 UI 提示。→ **#5**
5. **P2 — 后端设备种子**：若设备管理页在 Live 模式需与 `demo_seed` 100 台设备一致，在 `seed.js` 增加 devices 导出及对应路由。→ **#6**
6. **P2 — UI**：孪生概览增加「当前牧区」与 Demo 牧区（50 头）上下文说明，与 `TwinOverviewStats` 企业级数字并存。→ **#7**
7. **P3 — 重构**：可选抽取 `TimeSeriesGenerator<T>`，统一生成器参数与缓存策略。→ **#8**
