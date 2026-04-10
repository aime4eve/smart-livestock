# 围栏 CRUD 功能优化设计

> **版本**: v1.0
> **日期**: 2026-04-10
> **状态**: 待实施
> **范围**: Mobile App — 围栏模块重构（合并地图+围栏，完整 CRUD）

---

## 一、目标

将底部导航的"地图"和"围栏"合并为统一的"围栏"入口，以全屏地图 + 底部抽屉的交互模式实现围栏的完整 CRUD（新建、编辑、删除、列表），数据在会话期间以内存列表维持状态。

## 二、需求摘要

| 项目 | 决策 |
|------|------|
| 范围 | 完整 CRUD：列表 + 新建 + 编辑 + 删除 |
| 字段 | 基础字段：名称、类型、状态、告警开关、面积 |
| 状态持久化 | 内存状态：会话期间 CRUD 实时反映，刷新后重置 |
| 删除确认 | AlertDialog 弹窗确认 |
| 页面布局 | 全屏地图 + DraggableScrollableSheet 底部抽屉 |

## 三、导航变更

### 3.1 底部导航

**变更前**: 孪生 | 地图 | 告警 | 我的 | 围栏 | (后台)

**变更后**: 孪生 | 围栏 | 告警 | 我的 | (后台)

- 移除 `nav-map` 导航项
- "围栏"导航项位置调整为第二个（原"地图"位置）
- 图标改为 `Icons.map`（继承原地图图标，因为围栏页现在包含地图）

### 3.2 路由变更

| 变更 | 旧路由 | 新路由 |
|------|--------|--------|
| 移除 | `/map` | — |
| 移除 | `/fence/create` | — |
| 新增 | — | `/fence/form` (新建) |
| 新增 | — | `/fence/form?id=xxx` (编辑) |
| 保留 | `/fence` | `/fence` |

`AppRoute` 枚举变更：
- 移除 `map`
- `fenceCreate` 改名为 `fenceForm`，path 改为 `/fence/form`

## 四、围栏页面设计（`/fence`）

### 4.1 布局

```
┌──────────────────────────┐
│  AppBar: 牧场名称         │
├──────────────────────────┤
│                          │
│      全屏 FlutterMap     │
│   （围栏多边形 + 牲畜标记）  │
│                          │
│                          │
├──────────── ▬ ───────────┤
│  DraggableScrollable     │
│  ┌────────────────────┐  │
│  │ 围栏 (4)    [+新建] │  │
│  │                    │  │
│  │ 放牧A区  启用  25头  │  │
│  │ 放牧B区  启用  18头  │  │
│  │ 夜间休息区 启用 4头   │  │
│  │ 隔离区   启用  3头   │  │
│  └────────────────────┘  │
└──────────────────────────┘
```

### 4.2 地图层（继承现有 map_page 能力）

- TileLayer: OpenStreetMap 瓦片
- PolygonLayer: 围栏多边形，选中时高亮（增大透明度 + 加粗边框）
- MarkerLayer: 牲畜位置标记
- 保留缩放/平移手势

### 4.3 底部抽屉（DraggableScrollableSheet）

**收起状态**：显示标题栏"围栏 (N)" + 新建按钮

**展开状态**：围栏卡片列表，每张卡片包含：
- 围栏名称
- 状态标签（启用/停用）
- 牲畜数量
- 操作按钮：编辑（→ `/fence/form?id=xxx`）、删除（→ AlertDialog）

**交互**：
- 点击卡片 → 地图定位到该围栏中心，高亮多边形
- 点击编辑按钮 → 跳转编辑表单
- 点击删除按钮 → AlertDialog 确认 → 从列表和地图移除

### 4.4 ViewState 处理

| ViewState | 表现 |
|-----------|------|
| loading | 地图区域显示 CircularProgressIndicator |
| normal | 全屏地图 + 底部抽屉 |
| empty | 地图 + 抽屉显示空状态"暂无围栏，点击 + 创建" |
| error | 地图不可用提示 + 围栏列表回退（继承现有 map 错误态策略） |
| offline | 离线提示 + 显示缓存围栏列表 |
| forbidden | 权限不足提示 |

## 五、围栏表单页设计（`/fence/form`）

### 5.1 模式区分

- URL 无 `id` 参数 → 新建模式，AppBar 标题"新建围栏"，空表单
- URL 有 `id` 参数 → 编辑模式，AppBar 标题"编辑围栏"，预填数据

### 5.2 表单字段

| 字段 | 控件 | 说明 |
|------|------|------|
| 名称 | TextField | 必填 |
| 类型 | DropdownButtonFormField | 矩形/圆形/多边形 |
| 面积 | 只读 Text | 显示当前面积（公顷） |
| 地图选区 | Container 占位 | 仍为占位（地图绘制围栏待 MVP） |
| 启用告警 | Switch | 默认开启 |
| 状态 | Switch | 启用/停用，默认启用 |

### 5.3 新建围栏的默认值

由于地图绘制仍为占位，新建围栏时使用预设默认值：
- `points`: 以牧场中心为基准，生成小范围矩形/圆形/多边形顶点
- `colorValue`: 从预定义颜色列表中按顺序取色（绿、蓝、橙、紫循环）
- `areaHectares`: 默认 1.0 公顷
- `livestockCount`: 默认 0

### 5.4 保存流程

1. 点击"保存围栏" → controller.save()
2. 模拟 500ms 延迟（Future.delayed）
3. 新建：生成 `fence_` + 时间戳作为 id → 添加到内存列表
4. 编辑：按 id 替换内存列表中的项
5. `context.pop()` 返回围栏页，列表自动刷新

## 六、删除流程

```
点击围栏卡片删除按钮
  → showDialog: AlertDialog
    标题: "确认删除"
    内容: "确认删除「{围栏名称}」？删除后无法恢复。"
    操作: [取消] [删除]
  → 点击删除
    → controller.delete(id)
    → 列表移除
    → 地图移除多边形
    → SnackBar "已删除「{围栏名称}」"
```

## 七、数据模型

### 7.1 FenceItem

```dart
class FenceItem {
  final String id;
  final String name;
  final FenceType type;       // FenceType enum: polygon, circle, rectangle
  final bool alarmEnabled;
  final bool active;
  final double areaHectares;
  final int livestockCount;
  final int colorValue;
  final List<LatLng> points;  // LatLng from latlong2 package (flutter_map 依赖)
}

enum FenceType { polygon, circle, rectangle }
```

### 7.2 FenceState（Controller 状态）

```dart
class FenceState {
  final List<FenceItem> fences;
  final String? selectedFenceId;
  final ViewState viewState;
  final String? message;
}
```

### 7.3 DemoSeed.fencePolygons 扩展

现有 `FencePolygon` 模型增加字段以匹配 `FenceItem`：

| 新增字段 | 类型 | 默认值 |
|----------|------|--------|
| type | String | 'polygon' |
| alarmEnabled | bool | true |
| active | bool | true |
| areaHectares | double | 按多边形面积估算 |
| livestockCount | int | 从 `_generateLivestock` 按 fenceId 统计 |

## 八、Controller API

```dart
class FenceController extends Notifier<FenceState> {
  FenceState build();                    // 从 repository 加载初始列表
  void select(String? id);              // 选中围栏（地图高亮）
  void add(FenceItem item);             // 新建
  void update(FenceItem item);          // 编辑
  void delete(String id);               // 删除
}
```

Repository 接口简化为：

```dart
abstract class FenceRepository {
  List<FenceItem> loadAll();            // 加载所有围栏
}
```

## 九、文件变更清单

### 新建文件

| 文件 | 说明 |
|------|------|
| `features/fence/domain/fence_item.dart` | FenceItem 模型 |
| `features/fence/domain/fence_state.dart` | FenceState 模型 |
| `features/pages/fence_form_page.dart` | 新建/编辑表单页 |

### 重写文件

| 文件 | 说明 |
|------|------|
| `features/fence/domain/fence_repository.dart` | 新接口（返回 List<FenceItem>） |
| `features/fence/data/mock_fence_repository.dart` | 基于 DemoSeed 实现 |
| `features/fence/data/live_fence_repository.dart` | 占位 |
| `features/fence/presentation/fence_controller.dart` | CRUD + select |
| `features/pages/fence_page.dart` | 全屏地图 + DraggableScrollableSheet |

### 修改文件

| 文件 | 变更 |
|------|------|
| `app/app_route.dart` | 移除 `map`，`fenceCreate` → `fenceForm` |
| `app/app_router.dart` | 更新路由配置 |
| `app/demo_shell.dart` | 移除 nav-map，调整围栏位置和图标 |
| `core/models/demo_models.dart` | FencePolygon 增加字段 |
| `core/data/demo_seed.dart` | fencePolygons 补充新字段数据 |

### 删除文件

| 文件 | 说明 |
|------|------|
| `features/fence_create/domain/fence_create_repository.dart` | 废弃 |
| `features/fence_create/data/mock_fence_create_repository.dart` | 废弃 |
| `features/fence_create/data/live_fence_create_repository.dart` | 废弃 |
| `features/fence_create/presentation/fence_create_controller.dart` | 废弃 |
| `features/pages/fence_create_page.dart` | 废弃 |
| `features/map/domain/map_repository.dart` | 废弃 |
| `features/map/data/mock_map_repository.dart` | 废弃 |
| `features/map/data/live_map_repository.dart` | 废弃 |
| `features/map/presentation/map_controller.dart` | 废弃 |
| `features/pages/map_page.dart` | 废弃 |

## 十、测试影响

现有测试中涉及 `nav-map`、`page-map`、`fence-create-*` 等 Key 的用例需更新：
- `nav-map` → 移除相关断言
- `page-map` → 移除或替换为 `page-fence` 地图断言
- `fence-create-*` → 替换为 `fence-form-*`
- 新增围栏 CRUD 相关测试用例

## 十一、不在范围内

- 地图上绘制围栏（地图选区仍为占位，待 MVP 阶段实现）
- 围栏时间策略配置
- 围栏功能类型（进入/离开/区域限制）细分
- 轨迹回放功能（原 map 页的轨迹筛选控件不迁移）
- 牲畜筛选控件（原 map 页的动物筛选/时间范围控件不迁移）
