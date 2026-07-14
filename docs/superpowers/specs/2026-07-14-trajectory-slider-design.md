# 牲畜移动轨迹 — 时间滑动条设计规格

> 日期: 2026-07-14
> 状态: 待确认
> 关联工单: [NIX-11](https://linear.app/nix-agentic/issue/NIX-11/增强移动轨迹操作体验)
> 高保真原型: `visualizations/nix-11-trajectory-prototype.html`

---

## 1. 背景与目标

### 1.1 当前问题

`trajectory_sheet.dart` 用三个按钮（24小时 / 7天 / 30天）选择时间范围，点击后一次性绘制完整静态折线。用户无法：
- 按时间顺序查看牲畜移动过程
- 定位到某个具体时间点的位置
- 回放移动轨迹动画

### 1.2 目标

取消三按钮分时段查看，改为**时间滑动条**方式按 GPS 采集时间点动态展示轨迹。

| 维度 | 旧 | 新 |
|------|----|----|
| 范围选择 | 三按钮，互斥 | 折叠式范围选择器（默认 24h），可选 24h/7d/30d/自定义 |
| 交互 | 点按钮 → 静态折线 | 拖滑动条 scrub + 播放/暂停/变速 |
| 展示 | 一次性全部画出 | 按时间点逐步生长，当前位置脉冲标记 |

### 1.3 设计原则

- **纯前端改动**：后端 API（`GET /livestock/{id}/gps-logs?startTime&endTime&sampleSize`）不变，前端改用滑动条消费同一接口
- **范围可切换**：默认最近 24h，但保留 24h/7d/30d/自定义切换入口，避免长周期数据挤垮滑动条
- **数据采样自适应**：采样上限根据 GPS 上报周期动态计算，而非固定值（详见第 3 节）
- **地图复用**：继续使用 FlutterMap + SmartTileProvider 三级降级 + WGS-84/GCJ-02 坐标转换，不动地图基础设施

---

## 2. 范围设计（方案 C）

### 2.1 范围选择器

顶部右上角折叠式下拉，默认显示「最近24小时」，点击展开：

| 选项 | 时间跨度 |
|------|---------|
| 最近 24 小时 | now - 24h → now |
| 最近 7 天 | now - 7d → now |
| 最近 30 天 | now - 30d → now |
| 自定义日期 | 用户选择起止日期 |

- 切换范围后，滑动条重建，自动定位到**最新数据点**（最右端）

### 2.2 为什么不做成全量历史（方案 A）

牲畜积累数月数据后，点数可达上万。单根滑动条无法精确定位单点，且后端需返回海量数据。固定上限采样 + 可切换范围是体验和数据的平衡。

### 2.3 自定义日期

弹出日期选择器（Flutter `showDateRangePicker`），选择起止日期后请求该范围数据。

---

## 3. 动态采样策略（核心设计）

### 3.1 问题

GPS 设备上报周期是可变参数（当前 30 分钟/次，未来可能 5 分钟/次）。如果采样上限固定为某个值（如 500），在不同周期下效果差异巨大：

| 上报周期 | 24h 点数 | 7d 点数 | 30d 点数 |
|---------|---------|--------|---------|
| 30 min（当前） | 48 | 336 | 1,440 |
| 5 min（未来） | 288 | 2,016 | 8,640 |

固定 500 上限在 30min 周期下只有 30d 才触发采样，但在 5min 周期下 7d 就严重降采样（2016→500，损失 75%）。

### 3.2 方案：基于上报周期动态计算采样上限

**采样上限 = 滑动条舒适交互上限（固定物理约束）**

滑动条舒适上限与上报周期无关，它是基于手机屏幕宽度和手指拖动精度的物理约束：

```
滑动条舒适上限 = 500 点
```

手机滑动条宽度约 350px，500 点 = 每点 0.7px，已接近手指拖动精度的极限。超过 500 点后滑动条过于密集，无法精确定位单个 GPS 点。

**采样触发条件 = 预期点数 > 舒适上限**

```
预期点数 = 时间范围时长 / 上报周期
```

| 判断 | sampleSize 参数 | 行为 |
|------|----------------|------|
| 预期点数 ≤ 500 | 不传 sampleSize | 后端返回全量数据，无信息损失 |
| 预期点数 > 500 | sampleSize = 500 | 后端等间隔采样到 500 点 |

后端 `sampleByDeviceAndTimeRange` 已支持：当 total ≤ sampleSize 时返回全量，否则按 stride 采样。所以即使预估有误差，传 sampleSize=500 也安全。

### 3.3 上报周期配置

上报周期作为前端常量配置，便于未来调整：

```dart
/// GPS device report interval. Used to estimate expected point count
/// and decide whether server-side sampling is needed.
/// Current: 30 min. Future: may change to 5 min.
const Duration _gpsReportInterval = Duration(minutes: 30);
```

当上报周期变更时，只需修改此常量，采样策略自动适配。

### 3.4 各范围 × 各周期的采样行为

| 范围 | 30min 周期 | | 5min 周期 | |
|------|-----------|---|-----------|---|
| | 预期点数 | 采样？ | 预期点数 | 采样？ |
| 24h | 48 | 否（全量） | 288 | 否（全量） |
| 7d | 336 | 否（全量） | 2,016 | 是（→500） |
| 30d | 1,440 | 是（→500） | 8,640 | 是（→500） |

### 3.5 实现伪代码

```dart
int? computeSampleSize(Duration rangeDuration) {
  final expectedPoints = rangeDuration.inSeconds ~/ _gpsReportInterval.inSeconds;
  if (expectedPoints <= _maxSliderPoints) {
    return null; // no sampling needed, request full data
  }
  return _maxSliderPoints; // server samples to 500
}
```

---

## 4. UI 组件结构

### 4.1 容器约束：Bottom Sheet

移动轨迹通过 `showModalBottomSheet` 从牲畜详情页底部弹出：

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (ctx) => _TrajectorySheet(livestockId: livestockId),
);
// Sheet 高度 = MediaQuery.of(context).size.height * 0.75
```

**空间预算（以 iPhone 844pt 屏幕为例，sheet = 633pt）：**

| 区域 | 高度预算 | 说明 |
|------|---------|------|
| 头部行（标题+牲畜+范围+关闭） | ~44pt | 合并成单行，最大化地图空间 |
| 地图区域 | **flex 自适应（~290pt）** | 占据所有剩余空间，是视觉主体 |
| 滑动条+当前时间 | ~72pt | 时间显示内联到滑动条上方 |
| 播放控制+变速 | ~52pt | 单行紧凑布局 |
| 统计卡片 | ~52pt | 三列紧凑卡片 |
| **合计非地图** | **~220pt** | |
| **地图可用** | **~413pt**（633 - 220） | |

> 关键设计：非地图区域压缩到最小（~220pt），让地图在 75% 屏高的 sheet 内仍占约 65% 空间。

### 4.2 整体布局（紧凑版，适配 Bottom Sheet）

```
┌──────────────────────────────────┐
│          drag handle             │  6pt
├──────────────────────────────────┤
│ 移动轨迹  #A001·GPS-3201 [24h▾] ✕│  44pt — 单行头部
├──────────────────────────────────┤
│                                  │
│           地图区域                │  flex 自适应
│        (脉冲标记+轨迹)            │  ~290pt+
│                           🎯 ⤢   │
│                                  │
├──────────────────────────────────┤
│          当前 14:32:08           │  18pt — 内联时间
│   ──────●──────────────          │  28pt — 滑动条
│   08:00              14:32       │  14pt — 标签
├──────────────────────────────────┤
│  ⏮  ▶  ⏭   1x 2x 4x 8x         │  52pt — 控制+变速
├──────────────────────────────────┤
│  轨迹点   移动距离   活动范围     │  52pt — 统计
│  48/48    2.3km     0.8km²      │
└──────────────────────────────────┘
```

### 4.3 紧凑化措施

与全屏原型对比的紧凑化调整：

| 元素 | 全屏版 | Sheet 版 | 节省 |
|------|--------|---------|------|
| 头部 | 标题栏 + 牲畜信息行 = 2 行 | 合并成 1 行（标题+牲畜摘要+范围+关闭） | ~40pt |
| 时间显示 | 独立居中大字行 | 内联到滑动条上方小字 | ~30pt |
| 按钮/卡片尺寸 | 标准 padding | 减小 padding/字号 | ~20pt |
| 地图 padding | 40px | 30px | 略增可视面积 |

### 4.4 组件树

```
TrajectorySheet (ConsumerStatefulWidget, height = 75% screen)
├── _HeaderRow (单行：标题 + 牲畜摘要 + 范围选择器 + 关闭)
│   └── _RangeSelector (折叠下拉)
├── FlutterMap (flex: 1，占据剩余空间)
│   ├── TileLayer (SmartTileProvider)
│   ├── PolylineLayer (已走轨迹 + 最近 trail)
│   └── MarkerLayer (起点标记 + 当前脉冲标记)
├── _SliderSection (当前时间 + 滑动条 + 起止标签)
├── _PlaybackControls (播放/暂停/跳转 + 变速)
└── _StatsRow (三列紧凑统计卡片)
```

---

## 5. 交互规格

### 5.1 滑动条（核心）

| 属性 | 规格 |
|------|------|
| 范围 | 0 ~ (当前范围数据点数 - 1) |
| 刻度 | 每个 step 对应一个 GPS 采集点 |
| 拖动 | 拖动时轨迹实时增长/收缩，脉冲标记移动到对应位置 |
| 填充 | 已走过部分用 `primary→accent` 渐变色填充 |
| 标签 | 起止时间标签：24h 显示「时:分」，多天显示「月/日 时:分」 |

### 5.2 播放/暂停

| 操作 | 行为 |
|------|------|
| 点击 ▶ | 从当前位置开始自动播放，每 tick 前进一个 GPS 点，轨迹逐点增长，脉冲标记移动，地图跟随 |
| 点击 ⏸ | 暂停播放 |
| 播放结束 | 到达最新点后自动暂停 |
| 到尾点再点 ▶ | 回到起点重新播放 |

### 5.3 变速

| 倍速 | tick 间隔 |
|------|----------|
| 1x | 300ms / 点 |
| 2x | 150ms / 点 |
| 4x | 75ms / 点 |
| 8x | ~38ms / 点（下限 50ms） |

变速时如正在播放，立即用新速度继续播放。

### 5.4 跳转按钮

| 按钮 | 行为 |
|------|------|
| ⏮ (skip start) | 暂停 + 回到第一个 GPS 点 |
| ⏭ (skip end) | 暂停 + 跳到最后一个 GPS 点 |

### 5.5 地图跟随

| 控件 | 行为 |
|------|------|
| 🎯 (跟随，默认开) | 播放/拖动滑动条时地图自动 panTo 到当前标记位置 |
| ⤢ (全览) | 地图 fitBounds 到当前范围全部 GPS 点 |

跟随关闭后，地图不再自动平移，用户可自由拖动/缩放。重新开启后立即回到当前标记。

### 5.6 范围切换

- 切换范围时暂停播放 + 显示加载指示器
- 数据加载完成后重建滑动条，定位到最新点
- 起止时间标签更新为新范围

---

## 6. 数据流

### 6.1 加载流程

```
用户打开 TrajectorySheet
  → 默认范围 = 24h
  → 预期点数 = 24h / 上报周期(30min) = 48
  → 48 ≤ 500，不传 sampleSize
  → 调用后端 GET /livestock/{id}/gps-logs?startTime={now-24h}&endTime={now}
  → 获得全量 GPS 点列表
  → 滑动条 max = points.length - 1
  → currentIdx 定位到最后一个点（展示完整轨迹）
  → fitBounds 全览
```

### 6.2 范围切换流程（以 30d 为例）

```
用户选择 30d
  → 暂停播放
  → 显示加载中
  → 预期点数 = 30d / 上报周期(30min) = 1440
  → 1440 > 500，传 sampleSize=500
  → 调用后端 GET /livestock/{id}/gps-logs?startTime={now-30d}&endTime={now}&sampleSize=500
  → 后端等间隔采样到 ≤500 点
  → 重建滑动条
  → currentIdx 定位到最后一个点
  → fitBounds 全览
  → 隐藏加载中
```

### 6.3 后端 API（无改动）

现有端点完全满足需求：

```
GET /api/v1/farms/{farmId}/livestock/{livestockId}/gps-logs
  ?startTime=2026-07-13T14:00:00Z
  &endTime=2026-07-14T14:00:00Z
  &sampleSize=500    ← 可选，前端按需传入

响应:
{
  "items": [
    { "id": 1, "deviceId": 5, "latitude": 28.228, "longitude": 112.938,
      "accuracy": 5.0, "recordedAt": "2026-07-13T14:15:00Z" },
    ...
  ],
  "total": 480
}
```

前端按 `recordedAt` 升序排列（如未排序则前端排序），滑动条 index 对应点的时间。

---

## 7. 状态管理

### 7.1 State 字段

```dart
class _TrajectorySheetState extends ConsumerState<...> {
  // 范围
  TrajectoryRange _range = TrajectoryRange.h24;  // h24 / d7 / d30 / custom
  DateTimeRange? _customRange;

  // 数据
  List<_GpsPoint> _points = [];     // 当前范围的 GPS 点（按时间升序）
  bool _loading = true;

  // 播放
  int _currentIdx = 0;              // 滑动条当前位置（0 ~ _points.length-1）
  bool _playing = false;
  int _speed = 1;                   // 1 / 2 / 4 / 8
  Timer? _playTimer;

  // 地图
  SmartTileProvider? _tileProvider;
  final _mapController = MapController();
  bool _followMode = true;
  bool _lastTransformed = false;
  LatLngBounds? _lastBounds;

  // 采样配置
  static const Duration _gpsReportInterval = Duration(minutes: 30);
  static const int _maxSliderPoints = 500;
}
```

### 7.2 不使用 Riverpod Provider

轨迹播放是高度瞬时交互（Timer 驱动的逐帧更新），放入 Riverpod Provider 会引入不必要的重建开销。保持 `_TrajectorySheetState` 内部管理，与当前实现一致。

---

## 8. 坐标转换

复用现有逻辑，不变：

```dart
var latLngs = _points.map((p) => LatLng(p.lat, p.lng)).toList();
final shouldTransform = _tileProvider?.shouldTransformCoordinates() ?? false;
if (shouldTransform) {
  latLngs = CoordTransform.wgs84ToGcj02All(latLngs);
}
```

滑动条更新时，visible 部分的 latLngs 子集也要做同样转换。

---

## 9. 国际化（i18n）

### 9.1 新增 ARB key

| Key | 中文 | 英文 |
|-----|------|------|
| `livestockTrajectoryCurrentTime` | 当前定位时间 | Current Position Time |
| `livestockTrajectoryRange24h` | 最近24小时 | Last 24h |
| `livestockTrajectoryRange7d` | 最近7天 | Last 7d |
| `livestockTrajectoryRange30d` | 最近30天 | Last 30d |
| `livestockTrajectoryRangeCustom` | 自定义日期 | Custom Date |
| `livestockTrajectoryFollow` | 跟随 | Follow |
| `livestockTrajectoryFitAll` | 全览 | Fit All |
| `livestockTrajectoryPointUnit` | 点 | pts |
| `livestockTrajectoryAccuracy` | 精度 | Accuracy |
| `livestockTrajectoryLoading` | 加载轨迹数据… | Loading trajectory… |
| `livestockTrajectoryPlay` | 播放 | Play |
| `livestockTrajectoryPause` | 暂停 | Pause |

### 9.2 废弃 key（移除）

| Key | 原因 |
|-----|------|
| `livestockRange24h` | 替换为 `livestockTrajectoryRange24h` |
| `livestockRange7d` | 替换为 `livestockTrajectoryRange7d` |
| `livestockRange30d` | 替换为 `livestockTrajectoryRange30d` |

### 9.3 保留 key

`livestockTrajectoryTitle`、`livestockTrajectoryPoints`、`livestockTrajectoryDistance`、`livestockTrajectoryRange`（活动范围）、`livestockTrajectoryEmpty`、`livestockTrajectoryNoGps` 全部保留复用。

---

## 10. 边界情况

| 场景 | 处理 |
|------|------|
| 无 GPS 设备绑定 | 显示 `livestockTrajectoryNoGps`，不显示滑动条 |
| 有设备但无数据 | 显示 `livestockTrajectoryEmpty`，不显示滑动条 |
| 仅 1 个 GPS 点 | 滑动条不可拖（max=0），地图居中显示该点，播放/拖动禁用 |
| 范围内数据 > 舒适上限 | 根据 §3 动态计算 sampleSize，后端采样 |
| 自定义日期范围为空 | 回退提示 `livestockTrajectoryEmpty` |
| tile 源切换（OSM↔高德） | 坐标转换重算 + 重新 fitBounds（现有逻辑不变） |
| 播放中切换范围 | 立即暂停 → 加载新范围数据 |
| 播放中拖动滑动条 | 立即暂停，跳到拖动位置 |

---

## 11. 统计计算

复用现有 `downsample` / `totalPathDistance` / `_calcArea` 工具函数，统计基于**当前可见部分**（0 ~ currentIdx）而非全量数据：

- **轨迹点**：`currentIdx + 1` / 总数
- **移动距离**：可见点的累计 haversine 距离
- **活动范围**：可见点的经纬度外接矩形面积

---

## 12. 改动范围

| 文件 | 改动类型 | 说明 |
|------|---------|------|
| `trajectory_sheet.dart` | **重写** | 核心改动：移除三按钮，新增滑动条+播放+范围选择器+动态采样 |
| `app_zh.arb` / `app_en.arb` | 增删 key | 新增滑动条相关 key，废弃旧三按钮 key |
| `app_localizations*.dart` | 自动生成 | `flutter gen-l10n` 重新生成 |

后端、数据模型、API 接口、地图基础设施**均不改动**。

---

## 13. 验收标准

- [ ] 移除 24h/7d/30d 三按钮，替换为滑动条
- [ ] 滑动条拖动时轨迹实时增长/收缩，脉冲标记移动
- [ ] 播放按钮可自动播放轨迹动画
- [ ] 支持 1x/2x/4x/8x 变速
- [ ] 范围选择器可切换 24h/7d/30d/自定义，切换后滑动条重建
- [ ] 切换范围时显示加载指示器
- [ ] 采样上限根据上报周期动态计算（§3）
- [ ] 跟随模式开关 + 全览按钮正常工作
- [ ] 统计数据随滑动条实时更新
- [ ] 无 GPS 设备 / 无数据时正确显示空状态
- [ ] tile 源切换时坐标转换正常
- [ ] 中英文 i18n 完整同步
- [ ] `flutter analyze` 无新增 warning
- [ ] `flutter build web` 编译通过
