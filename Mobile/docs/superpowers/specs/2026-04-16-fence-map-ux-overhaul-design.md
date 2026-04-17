# 围栏地图交互体验重构设计

> 日期: 2026-04-16
> 状态: Approved
> 范围: Mobile/mobile_app — fence_page + fence_edit_toolbar + app_colors

## 背景

当前围栏地图存在两类体验问题：

1. **浏览态选中围栏困难**：命中检测仅用射线法判断"点是否在多边形内部"，点击边界附近无法选中；选中反馈仅靠透明度变化（alpha 0.2→0.4），用户难以确认是否选中。
2. **编辑态地图白屏且无法缩放**：`FenceEditOverlay` 使用独立 FlutterMap + `AppColors.surface` 固体背景遮盖瓦片；拖点/平移工具下 `InteractiveFlag.none` 完全禁用地图手势。

此外还发现：重叠围栏总是选中列表第一个（无智能排序），编辑态 AppBar 消失导致用户失去上下文。

## 设计目标

- 统一浏览态/编辑态为单一 FlutterMap 实例，消除双 MapController 的视角同步问题
- 围栏边界外扩 40px 命中容差，小围栏和手指操作更友好
- 选中围栏呼吸动画反馈，视觉区分明确
- 重叠围栏弹出候选列表
- 编辑态始终允许双指缩放/平移；单指在拖点/平移工具下操作顶点或平移围栏，在插点/删点工具下平移地图
- 编辑态保留迷你标题条显示上下文

## 架构

### 单一地图实例

合并为一个 `FlutterMap` + 一个 `MapController`，通过 mode overlay 切换交互层。

```
Scaffold
├── AppBar（浏览态显示 / 编辑态改为迷你标题条）
└── Stack
    ├── FlutterMap（单一实例，始终存在）
    │   ├── TileLayer（始终可见）
    │   ├── PolygonLayer（围栏渲染，根据状态决定样式）
    │   ├── PolylineLayer（轨迹）
    │   └── MarkerLayer（牲畜点位 + 编辑态顶点手柄）
    ├── 浏览态 Overlay
    │   ├── 抽屉面板
    │   ├── 菜单按钮
    │   └── "编辑边界" FAB
    ├── 编辑态 Overlay
    │   ├── 顶点拖拽手势层（Listener）
    │   ├── 平移命中区域（translate 工具时）
    │   └── FenceEditToolbar
    └── 选中反馈动画层（呼吸动画）
```

核心变化：
- 删除 `_editMapController`，只用一个 `_mapController`
- 删除 `FenceEditOverlay` 整个 Widget
- 编辑态的顶点手柄、边中点标记直接作为 MarkerLayer 的内容加入主地图
- 编辑工具切换只改变手势层行为，不切换地图实例

### 统一手势路由

FlutterMap 始终保持 `InteractiveFlag.all`，通过 `Listener` 监听原始指针事件区分单指/双指。

手势路由规则：

| 手势 | 浏览态 | 编辑态（拖点） | 编辑态（平移） | 编辑态（插点/删点） |
|------|--------|-----------------|-----------------|---------------------|
| 单指点击 | 选中围栏 / 取消选中 | 命中顶点→开始拖拽 | 命中多边形内→开始平移围栏 | 插点：找最近边插入；删点：命中顶点→删除 |
| 单指拖动 | 平移地图 | 命中顶点→移动顶点；未命中→平移地图 | 命中多边形内→平移围栏；未命中→平移地图 | 平移地图 |
| 双指捏合 | 缩放地图 | 缩放地图（第二指落下时自动结束顶点拖拽） | 缩放地图（第二指落下时自动结束围栏平移） | 缩放地图 |

实现方式：
- FlutterMap 上层包裹 `Listener`，追踪 `PointerDown`/`PointerUp` 计数
- 检测到 2+ 指针时设置 `_isMultiTouch = true`，忽略单指手势逻辑，让 FlutterMap 原生处理双指缩放
- 所有指针抬起后重置状态
- 编辑态单指拖拽通过 `GestureDetector`（顶点手柄上）和 `Listener`（平移命中区域）实现

关键细节：拖顶点期间用户第二指落下 → 立即结束当前顶点拖拽（`onPanEnd`），双指缩放正常生效。

## 选中体验

### 命中检测

命中检测在 presentation 层（`fence_page.dart`）执行，依赖 `MapController.camera` 将 LatLng 转为屏幕坐标后计算距离。domain 层的 `fence_polygon_contains.dart` 保持不变。

两层命中判定：

1. **边界容差命中**（屏幕空间）：将多边形顶点转为屏幕坐标，计算点击位置到每条边的最短距离，任一边距离 < 40px 算命中。此计算在 presentation 层完成，因为依赖地图投影上下文（`MapController.camera.latLngToScreenPoint`）
2. **内部命中**（地理空间）：复用现有 `fencePolygonContainsLatLng` 射线法

命中后按面积升序排列候选围栏（小围栏优先），返回所有命中围栏列表。

### 重叠围栏

- 1 个命中 → 直接选中
- 2+ 个命中 → 弹出 BottomSheet 候选列表，每项显示围栏名称、颜色标识、牲畜数量，点击即选中
- 数据来源：候选项展示的牲畜数量直接取自 `FenceItem.livestockCount`（`FenceState.fences` 中已有），无需额外 provider 或状态变更

### 视觉反馈

| 状态 | 填充色 | 边框 | 动画 |
|------|--------|------|------|
| 无选中（默认） | alpha 0.15 | 原色，宽度 2.0 | 无 |
| 有选中 + 未选中 | alpha 0.08 | 原色 alpha 0.4，宽度 1.5 | 无 |
| 选中 | alpha 0.35 | 原色，宽度 3.5 | 呼吸动画：边框宽度 3.0↔4.5，填充 alpha 0.3↔0.4，周期 1.5s |

呼吸动画通过 `AnimationController(vsync, repeat, reverse)` + `AnimatedBuilder` 驱动。仅在浏览态生效（编辑态有顶点手柄标识）。

### 取消选中

点击地图空白区域（无任何围栏命中）时取消选中，和现有行为一致。

## 编辑态视觉与上下文

### 地图可见性

单一 FlutterMap 实例下 `TileLayer` 始终存在，不再有 `AppColors.surface` 固体背景遮盖问题。

### 迷你标题条

编辑态在地图顶部叠加半透明标题条：

```
┌────────────────────────────────────────────┐
│ ← 编辑围栏：东区牧场          [撤销] [重做] │  ← 半透明黑背景，高度 48px
├────────────────────────────────────────────┤
│              地图区域                       │
├────────────────────────────────────────────┤
│  [拖点] [插点] [删点] [平移]  │  [保存]    │  ← FenceEditToolbar（底部）
└────────────────────────────────────────────┘
```

- 背景：`AppColors.overlayDark`（半透明深色，需在 `app_colors.dart` 新增 token）
- 左侧：返回箭头 + 围栏名称
- 右侧：撤销/重做按钮（从底部工具栏移到顶部）
- 底部工具栏只保留工具选择 + 保存/退出

### 未保存确认

保持现有 `FenceUnsavedDialog` 行为不变。

## 文件变更

### 修改

| 文件 | 变更类型 | 说明 |
|------|----------|------|
| `lib/features/pages/fence_page.dart` | 重写 | 单一 FlutterMap + 模式 overlay，删除双 MapController，新增呼吸动画、屏幕空间命中检测（含边界容差）、候选列表 BottomSheet |
| `lib/features/fence/presentation/widgets/fence_edit_toolbar.dart` | 修改 | 移除撤销/重做按钮（移到顶部标题条），调整布局 |
| `lib/core/theme/app_colors.dart` | 修改 | 新增 `AppColors.overlayDark` token（半透明深色，用于编辑态迷你标题条背景） |

### 删除

| 文件 | 说明 |
|------|------|
| `lib/features/fence/presentation/widgets/fence_edit_overlay.dart` | 不再需要独立地图 Widget |

### 不变

- `fence_controller.dart` — 状态管理和业务逻辑保持不变
- `fence_state.dart` — 状态模型保持不变
- `fence_edit_session.dart` — 编辑会话保持不变
- `fence_edit_operations.dart` — 纯函数操作保持不变
- `fence_form_page.dart` — 新建围栏的绘制页面独立，不受影响
- `fence_analytics.dart` — 埋点逻辑保持不变
- 所有 `domain/` 和 `data/` 层代码不变

## 测试影响

现有测试文件需要更新，与验收标准逐条映射：

| 验收标准 | 测试文件 | 测试内容 |
|----------|----------|----------|
| 1. 浏览态围栏边界 40px 内选中 + 呼吸动画 | `fence_map_tap_highlight_test.dart` | 边界容差命中、面积优先排序、呼吸动画 alpha 值 |
| 2. 重叠围栏候选列表 | `fence_map_tap_highlight_test.dart` 新增用例 | 2+ 围栏命中时弹出 BottomSheet，点击候选项选中对应围栏 |
| 3. 编辑态地图可见 | `fence_edit_test.dart` 或新建 | 编辑态下 TileLayer 存在、无固体背景遮盖 |
| 4. 编辑态双指缩放 | `fence_edit_test.dart` 新增用例 | 各工具模式下双指捏合触发地图缩放 |
| 5. 多指中断操作 | `fence_edit_test.dart` 新增用例 | 拖顶点或平移围栏期间第二指落下→操作结束、缩放生效 |
| 6. 迷你标题条 | `fence_edit_test.dart` 新增用例 | 标题条包含围栏名称、撤销/重做按钮可点击 |
| 7-8. analyze + test | CI | 无新增警告，全部通过 |

所有新增 UI 元素必须包含 `Key('descriptive-id')` 以支持测试定位。引用 `FenceEditOverlay` key 的已有测试需更新为新的 key 引用。

## 验收标准

1. 浏览态点击围栏附近（40px 内）可选中，有呼吸动画
2. 重叠围栏点击弹出候选列表 BottomSheet
3. 编辑态背景地图正常显示，无白屏
4. 编辑态所有工具下双指可缩放/平移地图
5. 拖顶点或平移围栏时单指操作，第二指落下自动结束当前操作并进入缩放
6. 迷你标题条显示围栏名称和撤销/重做
7. `flutter analyze` 无新增警告
8. `flutter test` 全部通过
