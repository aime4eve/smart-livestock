# Demo 数据与场景全面增强设计

**日期**: 2026-04-09
**状态**: Draft
**方案**: 混合方案（静态种子 + 运行时生成）

---

## 背景与目标

当前 Demo 仅有 3 头牛、2 个围栏、少量时序数据，数据规模不足以支撑客户演示和路演。需要将数据增强到接近真实中型牧场运营水平，同时保持 Demo 的可靠性和可复现性。

**目标受众**: 客户演示/路演
**数据规模**: 50 头牛、4 个围栏、1 周时序数据
**质量优先**: 视觉效果突出、数据真实可信

---

## 数据分层策略

| 层 | 数据类型 | 生成方式 | 存储 |
|---|---------|---------|------|
| 确定性层 | 牛只列表、围栏边界、设备清单、告警模板、用户信息 | 静态种子文件 | `demo_seed.dart` / `seed.js` |
| 动态层 | GPS 轨迹、温度曲线、蠕动数据、发情评分趋势 | 运行时算法生成 | Mock Repository 内的生成器 |

**设计原则**:
- 客户演示路径上的核心数据（牛只身份、围栏、告警）必须是确定性的，保证每次演示一致
- 时序数据（温度、蠕动、GPS）用算法生成，增加数据丰富度和真实感
- 前后端数据保持对齐

---

## 确定性层数据设计

### 牛只（50 头）

| 属性 | 说明 |
|------|------|
| 耳标号 | `SL-2024-001` ~ `SL-2024-050` |
| 品种 | 西门塔尔（20）、安格斯（15）、利木赞（15） |
| 年龄 | 1.5-6 岁，正态分布 |
| 体重 | 350-650 kg，按品种分档 |
| 健康状态 | healthy（43）、watch（4）、abnormal（3） |
| 围栏归属 | 放牧A区（18）、放牧B区（16）、夜间休息区（全部）、隔离区（3 头异常牛） |

### 围栏（4 个）

| 围栏 | 类型 | 面积（亩） | 说明 |
|------|------|----------|------|
| 放牧A区 | 放牧 | ~200 | 东北区域，平坦草地 |
| 放牧B区 | 放牧 | ~180 | 西南区域，含小溪 |
| 夜间休息区 | 休息 | ~30 | 中部，牛舍附近 |
| 隔离区 | 隔离 | ~10 | 南角，围栏加强 |

### 设备（100 个）

- GPS 追踪器 50 个（1:1 挂载牛只）
- 瘤胃胶囊 30 个（安装在 30 头牛体内）
- 加速度计 20 个
- 状态分布：online（85）、offline（8）、lowBattery（7）

### 告警（15-20 条）

| 级别 | 类型 | 数量 | 状态分布 |
|------|------|------|---------|
| P0 紧急 | 越界、高热 | 4 | pending 1, acknowledged 1, handled 2 |
| P1 重要 | 设备离线、低电量 | 5 | pending 2, acknowledged 1, handled 2 |
| P2 一般 | 异常行为、围栏接近 | 5 | pending 1, handled 3, archived 1 |
| 已归档 | 各类型 | 4 | 全部 archived |

### 孪生基线数据（30 头有胶囊牛）

- 基础体温基线：38.0-39.5°C，按品种微调
- 消化健康等级：正常（25）、轻度异常（3）、中度异常（2）
- 发情状态：非发情期（27）、发情期（3）

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

### 修改文件

| 文件 | 改动内容 |
|------|---------|
| `lib/core/data/demo_seed.dart` | 扩展牛只到 50 头、设备到 100 个、围栏到 4 个、告警到 20 条、看板指标更新 |
| `lib/core/data/twin_seed.dart` | 扩展孪生基线数据到 30 头牛、增加异常样本 |
| `backend/data/seed.js` | 后端种子数据同步扩展 |
| `backend/data/twin_seed.js` | 后端孪生种子同步扩展 |
| `mock_map_repository.dart` | GPS 轨迹从生成器获取 |
| `mock_fever_repository.dart` | 温度曲线从生成器获取 |
| `mock_digestive_repository.dart` | 蠕动数据从生成器获取 |
| `mock_estrus_repository.dart` | 发情评分从生成器获取 |
| `mock_livestock_repository.dart` | 关联更多牛只数据 |
| `mock_dashboard_repository.dart` | 看板指标更新 |
| `mock_alerts_repository.dart` | 告警数据扩展 |
| `mock_stats_repository.dart` | 统计数据扩展 |
| 对应 `live_*_repository.dart` | 确保新字段从 ApiCache 正确映射 |

---

## 性能考虑

- GPS: 50 牛 × 7 天 × 24 点/天 = 8400 点 → 内存可接受
- 温度: 30 牛 × 7 天 × 48 点/天 = 10080 点 → 图表降采样显示
- 蠕动: 30 牛 × 7 天 × 48 点/天 = 10080 点 → 图表降采样显示
- 发情: 30 牛 × 7 天 × 1 点/天 = 210 点 → 无压力

**缓存策略**: 生成器在首次调用时计算并缓存结果，后续访问直接返回缓存。不使用持久化存储。

---

## 前后端数据对齐

种子数据从单一数据源生成，同时输出 Dart 和 JS 格式，确保 Mock 和 Live 模式数据一致。

具体做法：编写一个 Dart 脚本（`tools/generate_seeds.dart`），从统一的数据定义生成 `demo_seed.dart` 和 `seed.js` 的对应部分。时序数据生成器仅存在于 Flutter 端（Mock 模式），Live 模式下后端返回服务端生成的数据。

---

## 不在范围内

- UI/UX 改动（本次仅增强数据层）
- 真实后端实现
- 性能优化（除非数据量导致明显卡顿）
- 新增功能模块
