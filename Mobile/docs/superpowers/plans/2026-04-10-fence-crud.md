# 围栏 CRUD 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将"地图"与"围栏"合并为统一的围栏入口，以全屏地图 + 底部抽屉交互实现围栏完整 CRUD，数据在会话期间以内存列表维持状态。

**Architecture:** 新建 FenceItem/FenceState 领域模型，重写 FenceRepository（仅 `loadAll()`）和 FenceController（CRUD + select），围栏页改为 FlutterMap + DraggableScrollableSheet。移除独立的地图模块与围栏新建模块，合并为统一围栏模块。

**Tech Stack:** Flutter 3.x, flutter_riverpod, go_router, flutter_map, latlong2

**真相来源**: Issue 的 **open/closed** 以 GitHub 为准；本文件记录范围说明、依赖与 **关闭后** 的归档信息。

---

## Issue 索引

| 优先级 | Issue | 标题 |
|--------|-------|------|
| P0 | [#10](https://github.com/aime4eve/smart-livestock/issues/10) | 围栏 CRUD 功能重构：合并地图+围栏，实现完整 CRUD |

### 完成记录

| 完成日期 | Issue | PR | 备注 |
|----------|-------|-----|------|

---

## 文件结构

### 新建

| 文件 | 职责 |
|------|------|
| `lib/features/fence/domain/fence_item.dart` | FenceItem 模型 + FenceType 枚举 |
| `lib/features/fence/domain/fence_state.dart` | FenceState 状态模型 |
| `lib/features/pages/fence_form_page.dart` | 新建/编辑围栏表单页 |

### 重写（保留路径，内容全部替换）

| 文件 | 职责 |
|------|------|
| `lib/features/fence/domain/fence_repository.dart` | 仓储接口 `loadAll()` |
| `lib/features/fence/data/mock_fence_repository.dart` | 基于 DemoSeed 的 Mock 实现 |
| `lib/features/fence/data/live_fence_repository.dart` | Live 占位（回退至 Mock） |
| `lib/features/fence/presentation/fence_controller.dart` | CRUD + select Notifier |
| `lib/features/pages/fence_page.dart` | 全屏地图 + DraggableScrollableSheet |

### 修改

| 文件 | 变更 |
|------|------|
| `lib/app/app_route.dart` | 移除 `map`，`fenceCreate` → `fenceForm` |
| `lib/app/demo_shell.dart` | 移除 nav-map，围栏调至第二项，图标改 `Icons.map` |
| `lib/app/app_router.dart` | 移除 map/fenceCreate 路由，添加 fenceForm 路由 |
| `lib/core/models/demo_models.dart` | FencePolygon 增加 type/alarmEnabled/active/areaHectares |
| `lib/core/data/demo_seed.dart` | fencePolygons 补充新字段值 |

### 删除

| 文件 |
|------|
| `lib/features/fence_create/domain/fence_create_repository.dart` |
| `lib/features/fence_create/data/mock_fence_create_repository.dart` |
| `lib/features/fence_create/data/live_fence_create_repository.dart` |
| `lib/features/fence_create/presentation/fence_create_controller.dart` |
| `lib/features/pages/fence_create_page.dart` |
| `lib/features/map/domain/map_repository.dart` |
| `lib/features/map/data/mock_map_repository.dart` |
| `lib/features/map/data/live_map_repository.dart` |
| `lib/features/map/presentation/map_controller.dart` |
| `lib/features/pages/map_page.dart` |

### 测试文件

| 文件 | 动作 |
|------|------|
| `test/widget_smoke_test.dart` | 重写 |
| `test/flow_smoke_test.dart` | 重写 |
| `test/role_visibility_test.dart` | 重写 |
| `test/mock_repository_override_test.dart` | 重写 |
| `test/mock_repository_state_test.dart` | 重写 |
| `test/state_persistence_test.dart` | 重写 |
| `test/app_mode_switch_test.dart` | 重写 |
| `test/highfi/map_fence_highfi_test.dart` | 删除 |
| `test/seed_data_test.dart` | 小改 |

---

## Task 1: FenceItem 与 FenceType 领域模型

**Files:**
- Create: `lib/features/fence/domain/fence_item.dart`

- [ ] **Step 1: 创建 FenceItem 模型**

```dart
import 'dart:math';

import 'package:latlong2/latlong.dart';

enum FenceType { polygon, circle, rectangle }

class FenceItem {
  const FenceItem({
    required this.id,
    required this.name,
    required this.type,
    required this.alarmEnabled,
    required this.active,
    required this.areaHectares,
    required this.livestockCount,
    required this.colorValue,
    required this.points,
  });

  final String id;
  final String name;
  final FenceType type;
  final bool alarmEnabled;
  final bool active;
  final double areaHectares;
  final int livestockCount;
  final int colorValue;
  final List<LatLng> points;

  static const defaultColors = [
    0xFF4C9A5F,
    0xFF4A7F9D,
    0xFFD28A2D,
    0xFF9B59B6,
  ];

  static List<LatLng> defaultPointsForType(FenceType type, LatLng center) {
    const d = 0.001;
    return switch (type) {
      FenceType.rectangle => [
        LatLng(center.latitude + d, center.longitude - d),
        LatLng(center.latitude + d, center.longitude + d),
        LatLng(center.latitude - d, center.longitude + d),
        LatLng(center.latitude - d, center.longitude - d),
      ],
      FenceType.circle => [
        for (var i = 0; i < 12; i++)
          LatLng(
            center.latitude + d * cos(i * pi / 6),
            center.longitude + d * sin(i * pi / 6),
          ),
      ],
      FenceType.polygon => [
        LatLng(center.latitude + d * 1.2, center.longitude),
        LatLng(center.latitude + d * 0.4, center.longitude + d),
        LatLng(center.latitude - d * 0.8, center.longitude + d * 0.6),
        LatLng(center.latitude - d, center.longitude - d * 0.3),
        LatLng(center.latitude - d * 0.2, center.longitude - d),
      ],
    };
  }

  FenceItem copyWith({
    String? id,
    String? name,
    FenceType? type,
    bool? alarmEnabled,
    bool? active,
    double? areaHectares,
    int? livestockCount,
    int? colorValue,
    List<LatLng>? points,
  }) {
    return FenceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      active: active ?? this.active,
      areaHectares: areaHectares ?? this.areaHectares,
      livestockCount: livestockCount ?? this.livestockCount,
      colorValue: colorValue ?? this.colorValue,
      points: points ?? this.points,
    );
  }
}
```

- [ ] **Step 2: 验证静态分析**

Run: `cd Mobile/mobile_app && flutter analyze lib/features/fence/domain/fence_item.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/fence/domain/fence_item.dart
git commit -m "feat(fence): add FenceItem model and FenceType enum"
```

---

## Task 2: FenceState 状态模型

**Files:**
- Create: `lib/features/fence/domain/fence_state.dart`

- [ ] **Step 1: 创建 FenceState 模型**

```dart
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';

class FenceState {
  const FenceState({
    required this.fences,
    this.selectedFenceId,
    required this.viewState,
    this.message,
  });

  final List<FenceItem> fences;
  final String? selectedFenceId;
  final ViewState viewState;
  final String? message;

  FenceItem? get selectedFence {
    if (selectedFenceId == null) return null;
    for (final f in fences) {
      if (f.id == selectedFenceId) return f;
    }
    return null;
  }

  FenceState copyWith({
    List<FenceItem>? fences,
    String? selectedFenceId,
    bool clearSelectedFence = false,
    ViewState? viewState,
    String? message,
  }) {
    return FenceState(
      fences: fences ?? this.fences,
      selectedFenceId:
          clearSelectedFence ? null : (selectedFenceId ?? this.selectedFenceId),
      viewState: viewState ?? this.viewState,
      message: message ?? this.message,
    );
  }
}
```

- [ ] **Step 2: 验证静态分析**

Run: `cd Mobile/mobile_app && flutter analyze lib/features/fence/domain/fence_state.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/fence/domain/fence_state.dart
git commit -m "feat(fence): add FenceState model"
```

---

## Task 3: 扩展 FencePolygon 与 DemoSeed

**Files:**
- Modify: `lib/core/models/demo_models.dart:22-27`
- Modify: `lib/core/data/demo_seed.dart:15-62`

- [ ] **Step 1: 扩展 FencePolygon 字段**

在 `lib/core/models/demo_models.dart` 中，替换 `FencePolygon` 类：

```dart
class FencePolygon {
  const FencePolygon({
    required this.id,
    required this.name,
    required this.points,
    required this.colorValue,
    this.type = 'polygon',
    this.alarmEnabled = true,
    this.active = true,
    this.areaHectares = 1.0,
  });

  final String id;
  final String name;
  final List<LatLng> points;
  final int colorValue;
  final String type;
  final bool alarmEnabled;
  final bool active;
  final double areaHectares;
}
```

- [ ] **Step 2: 更新 DemoSeed.fencePolygons 数据**

在 `lib/core/data/demo_seed.dart` 中，为每个 `FencePolygon` 添加新字段值：

```dart
  static const List<FencePolygon> fencePolygons = [
    FencePolygon(
      id: 'fence_pasture_a',
      name: '放牧A区',
      points: [
        LatLng(28.2340, 112.9400),
        LatLng(28.2340, 112.9440),
        LatLng(28.2305, 112.9440),
        LatLng(28.2305, 112.9400),
      ],
      colorValue: 0xFF4C9A5F,
      type: 'rectangle',
      areaHectares: 15.2,
    ),
    FencePolygon(
      id: 'fence_pasture_b',
      name: '放牧B区',
      points: [
        LatLng(28.2275, 112.9320),
        LatLng(28.2275, 112.9360),
        LatLng(28.2240, 112.9360),
        LatLng(28.2240, 112.9320),
      ],
      colorValue: 0xFF2F6B3B,
      type: 'rectangle',
      areaHectares: 14.8,
    ),
    FencePolygon(
      id: 'fence_rest',
      name: '夜间休息区',
      points: [
        LatLng(28.2295, 112.9380),
        LatLng(28.2295, 112.9400),
        LatLng(28.2280, 112.9400),
        LatLng(28.2280, 112.9380),
      ],
      colorValue: 0xFFD28A2D,
      type: 'rectangle',
      areaHectares: 3.5,
    ),
    FencePolygon(
      id: 'fence_quarantine',
      name: '隔离区',
      points: [
        LatLng(28.2255, 112.9400),
        LatLng(28.2255, 112.9410),
        LatLng(28.2248, 112.9410),
        LatLng(28.2248, 112.9400),
      ],
      colorValue: 0xFFB84040,
      type: 'rectangle',
      areaHectares: 0.8,
    ),
  ];
```

- [ ] **Step 3: 验证静态分析**

Run: `cd Mobile/mobile_app && flutter analyze lib/core/models/demo_models.dart lib/core/data/demo_seed.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/core/models/demo_models.dart lib/core/data/demo_seed.dart
git commit -m "feat(seed): extend FencePolygon with type, alarm, active, area fields"
```

---

## Task 4: FenceRepository 接口与实现

**Files:**
- Rewrite: `lib/features/fence/domain/fence_repository.dart`
- Rewrite: `lib/features/fence/data/mock_fence_repository.dart`
- Rewrite: `lib/features/fence/data/live_fence_repository.dart`

- [ ] **Step 1: 重写 FenceRepository 接口**

替换 `lib/features/fence/domain/fence_repository.dart` 全部内容：

```dart
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';

abstract class FenceRepository {
  List<FenceItem> loadAll();
}
```

- [ ] **Step 2: 重写 MockFenceRepository**

替换 `lib/features/fence/data/mock_fence_repository.dart` 全部内容：

```dart
import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_repository.dart';

class MockFenceRepository implements FenceRepository {
  const MockFenceRepository();

  @override
  List<FenceItem> loadAll() {
    return DemoSeed.fencePolygons.map((fp) {
      final count =
          DemoSeed.livestock.where((l) => l.fenceId == fp.id).length;
      return FenceItem(
        id: fp.id,
        name: fp.name,
        type: _parseType(fp.type),
        alarmEnabled: fp.alarmEnabled,
        active: fp.active,
        areaHectares: fp.areaHectares,
        livestockCount: count,
        colorValue: fp.colorValue,
        points: fp.points,
      );
    }).toList();
  }

  static FenceType _parseType(String type) {
    return switch (type) {
      'rectangle' => FenceType.rectangle,
      'circle' => FenceType.circle,
      _ => FenceType.polygon,
    };
  }
}
```

- [ ] **Step 3: 重写 LiveFenceRepository**

替换 `lib/features/fence/data/live_fence_repository.dart` 全部内容：

```dart
import 'package:smart_livestock_demo/features/fence/data/mock_fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_repository.dart';

class LiveFenceRepository implements FenceRepository {
  const LiveFenceRepository();

  static const MockFenceRepository _fallback = MockFenceRepository();

  @override
  List<FenceItem> loadAll() {
    return _fallback.loadAll();
  }
}
```

- [ ] **Step 4: 验证静态分析**

Run: `cd Mobile/mobile_app && flutter analyze lib/features/fence/`
Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add lib/features/fence/domain/fence_repository.dart lib/features/fence/data/mock_fence_repository.dart lib/features/fence/data/live_fence_repository.dart
git commit -m "feat(fence): rewrite FenceRepository with loadAll() returning FenceItem list"
```

---

## Task 5: FenceController CRUD 控制器

**Files:**
- Rewrite: `lib/features/fence/presentation/fence_controller.dart`

- [ ] **Step 1: 重写 FenceController**

替换 `lib/features/fence/presentation/fence_controller.dart` 全部内容：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/fence/data/live_fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/data/mock_fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_state.dart';

final fenceRepositoryProvider = Provider<FenceRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return const MockFenceRepository();
    case AppMode.live:
      return const LiveFenceRepository();
  }
});

class FenceController extends Notifier<FenceState> {
  @override
  FenceState build() {
    final fences = ref.watch(fenceRepositoryProvider).loadAll();
    return FenceState(
      fences: fences,
      viewState: fences.isEmpty ? ViewState.empty : ViewState.normal,
    );
  }

  void select(String? id) {
    state = state.copyWith(selectedFenceId: id);
  }

  void add(FenceItem item) {
    state = state.copyWith(
      fences: [...state.fences, item],
      viewState: ViewState.normal,
    );
  }

  void update(FenceItem item) {
    state = state.copyWith(
      fences: [
        for (final f in state.fences)
          if (f.id == item.id) item else f,
      ],
    );
  }

  void delete(String id) {
    final newFences = state.fences.where((f) => f.id != id).toList();
    state = FenceState(
      fences: newFences,
      selectedFenceId:
          state.selectedFenceId == id ? null : state.selectedFenceId,
      viewState: newFences.isEmpty ? ViewState.empty : state.viewState,
    );
  }
}

final fenceControllerProvider =
    NotifierProvider<FenceController, FenceState>(FenceController.new);
```

- [ ] **Step 2: 验证静态分析**

Run: `cd Mobile/mobile_app && flutter analyze lib/features/fence/presentation/fence_controller.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/fence/presentation/fence_controller.dart
git commit -m "feat(fence): rewrite FenceController with CRUD and select operations"
```

---

## Task 6: AppRoute 与导航变更

**Files:**
- Modify: `lib/app/app_route.dart`
- Modify: `lib/app/demo_shell.dart`

- [ ] **Step 1: 更新 AppRoute 枚举**

在 `lib/app/app_route.dart` 中：
- 删除 `map('/map', 'map', '地图'),` 行
- 将 `fenceCreate('/fence/create', 'fence-create', '创建围栏'),` 替换为 `fenceForm('/fence/form', 'fence-form', '围栏表单'),`

修改后的枚举值列表（完整）：

```dart
enum AppRoute {
  login('/login', 'login', '登录'),
  twin('/twin', 'twin', '孪生'),
  alerts('/alerts', 'alerts', '告警'),
  mine('/mine', 'mine', '我的'),
  fence('/fence', 'fence', '围栏'),
  admin('/admin', 'admin', '后台'),
  opsAdmin('/ops/admin', 'ops-admin', '运维后台'),
  livestockDetail('/livestock/:id', 'livestock-detail', '牲畜详情'),
  devices('/devices', 'devices', '设备管理'),
  fenceForm('/fence/form', 'fence-form', '围栏表单'),
  stats('/stats', 'stats', '数据统计'),
  twinFever('/twin/fever', 'twin-fever', '发热预警'),
  twinFeverDetail('/twin/fever/:livestockId', 'twin-fever-detail', '发热详情'),
  twinDigestive('/twin/digestive', 'twin-digestive', '消化管理'),
  twinDigestiveDetail(
    '/twin/digestive/:livestockId',
    'twin-digestive-detail',
    '消化详情',
  ),
  twinEstrus('/twin/estrus', 'twin-estrus', '发情识别'),
  twinEstrusDetail(
    '/twin/estrus/:livestockId',
    'twin-estrus-detail',
    '发情详情',
  ),
  twinEpidemic('/twin/epidemic', 'twin-epidemic', '疫病防控');

  const AppRoute(this.path, this.routeName, this.label);

  final String path;
  final String routeName;
  final String label;
}
```

- [ ] **Step 2: 更新 demo_shell 导航项**

在 `lib/app/demo_shell.dart` 的 `_buildBusinessNavItems` 方法中，移除 nav-map 项，将 nav-fence 调至第二位并改用 `Icons.map` 图标。替换整个方法体：

```dart
  List<_NavItem> _buildBusinessNavItems(DemoRole role) {
    final items = <_NavItem>[
      const _NavItem(
        key: Key('nav-twin'),
        icon: Icons.account_tree_outlined,
        label: '孪生',
        route: AppRoute.twin,
      ),
      const _NavItem(
        key: Key('nav-fence'),
        icon: Icons.map,
        label: '围栏',
        route: AppRoute.fence,
      ),
      const _NavItem(
        key: Key('nav-alerts'),
        icon: Icons.warning_amber,
        label: '告警',
        route: AppRoute.alerts,
      ),
      const _NavItem(
        key: Key('nav-mine'),
        icon: Icons.person,
        label: '我的',
        route: AppRoute.mine,
      ),
    ];
    if (role == DemoRole.owner) {
      items.add(
        const _NavItem(
          key: Key('nav-admin'),
          icon: Icons.admin_panel_settings,
          label: '后台',
          route: AppRoute.admin,
        ),
      );
    }
    return items;
  }
```

- [ ] **Step 3: 验证静态分析**

Run: `cd Mobile/mobile_app && flutter analyze lib/app/app_route.dart lib/app/demo_shell.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/app/app_route.dart lib/app/demo_shell.dart
git commit -m "feat(nav): remove map nav, move fence to 2nd position with map icon"
```

---

## Task 7: FencePage 全屏地图 + 底部抽屉

**Files:**
- Rewrite: `lib/features/pages/fence_page.dart`

- [ ] **Step 1: 重写 FencePage**

替换 `lib/features/pages/fence_page.dart` 全部内容：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/map/map_config.dart';
import 'package:smart_livestock_demo/core/mock/mock_config.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/permissions/role_permission.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_state.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';

class FencePage extends ConsumerStatefulWidget {
  const FencePage({super.key});

  @override
  ConsumerState<FencePage> createState() => _FencePageState();
}

class _FencePageState extends ConsumerState<FencePage> {
  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fenceState = ref.watch(fenceControllerProvider);
    final controller = ref.read(fenceControllerProvider.notifier);
    final role = ref.watch(sessionControllerProvider).role!;
    final canManage = RolePermission.canEditFence(role);

    return Scaffold(
      key: const Key('page-fence'),
      appBar: AppBar(title: Text(MockConfig.ranchName)),
      body: _buildBody(context, fenceState, controller, canManage),
    );
  }

  Widget _buildBody(
    BuildContext context,
    FenceState fenceState,
    FenceController controller,
    bool canManage,
  ) {
    switch (fenceState.viewState) {
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.error:
      case ViewState.forbidden:
      case ViewState.offline:
        return Center(
          child: Text(
            fenceState.message ?? '围栏不可用',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      case ViewState.normal:
      case ViewState.empty:
        return _buildMapWithDrawer(context, fenceState, controller, canManage);
    }
  }

  Widget _buildMapWithDrawer(
    BuildContext context,
    FenceState fenceState,
    FenceController controller,
    bool canManage,
  ) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: DemoSeed.mapCenter,
            initialZoom: DemoSeed.defaultZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: MapConfig.tileUrlTemplate,
              userAgentPackageName: 'com.smartlivestock.demo',
              maxZoom: MapConfig.cacheMaxZoom.toDouble(),
            ),
            PolygonLayer(
              polygons: fenceState.fences.map((fence) {
                final color = Color(fence.colorValue);
                final selected = fence.id == fenceState.selectedFenceId;
                return Polygon(
                  points: fence.points,
                  color: color.withValues(alpha: selected ? 0.4 : 0.2),
                  borderColor: color,
                  borderStrokeWidth: selected ? 3.5 : 2.0,
                );
              }).toList(),
            ),
            MarkerLayer(
              markers: [
                for (int i = 0; i < DemoSeed.livestockLocations.length; i++)
                  Marker(
                    point: DemoSeed.livestockLocations[i].toLatLng(),
                    width: 56,
                    height: 56,
                    child: _MapMarker(
                      label: DemoSeed
                          .earTags[i < DemoSeed.earTags.length ? i : 0],
                      isAlert: i == 0,
                    ),
                  ),
              ],
            ),
          ],
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.15,
          minChildSize: 0.15,
          maxChildSize: 0.6,
          snap: true,
          snapSizes: const [0.15, 0.6],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.lg),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '围栏 (${fenceState.fences.length})',
                        key: const Key('fence-drawer-title'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (canManage)
                        IconButton(
                          key: const Key('fence-add'),
                          onPressed: () =>
                              context.push(AppRoute.fenceForm.path),
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: '新建围栏',
                        ),
                    ],
                  ),
                  if (fenceState.fences.isEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(
                        child: Text(
                          '暂无围栏，点击 + 创建',
                          key: const Key('fence-empty-hint'),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    for (final fence in fenceState.fences)
                      _FenceCard(
                        fence: fence,
                        isSelected:
                            fence.id == fenceState.selectedFenceId,
                        canManage: canManage,
                        onTap: () {
                          controller.select(fence.id);
                          _mapController.move(
                            _fenceCenter(fence.points),
                            16.0,
                          );
                        },
                        onEdit: () => context.push(
                          '${AppRoute.fenceForm.path}?id=${fence.id}',
                        ),
                        onDelete: () =>
                            _showDeleteDialog(context, fence, controller),
                      ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  LatLng _fenceCenter(List<LatLng> points) {
    double lat = 0, lng = 0;
    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  void _showDeleteDialog(
    BuildContext context,
    FenceItem fence,
    FenceController controller,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确认删除「${fence.name}」？删除后无法恢复。'),
        actions: [
          TextButton(
            key: const Key('fence-delete-cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            key: const Key('fence-delete-confirm'),
            onPressed: () {
              controller.delete(fence.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text('已删除「${fence.name}」')),
                );
            },
            child: Text('删除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _FenceCard extends StatelessWidget {
  const _FenceCard({
    required this.fence,
    required this.isSelected,
    required this.canManage,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final FenceItem fence;
  final bool isSelected;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('fence-card-${fence.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        side: isSelected
            ? BorderSide(color: Color(fence.colorValue), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(fence.colorValue),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fence.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _StatusLabel(active: fence.active),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${fence.livestockCount}头',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canManage) ...[
                IconButton(
                  key: Key('fence-edit-${fence.id}'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: '编辑',
                ),
                IconButton(
                  key: Key('fence-delete-${fence.id}'),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: '删除',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.textSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        active ? '启用' : '停用',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: active ? AppColors.success : AppColors.textSecondary,
              fontSize: 11,
            ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.label, this.isAlert = false});

  final String label;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final color = isAlert ? AppColors.danger : AppColors.success;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.pets, color: Colors.white, size: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 2),
              ],
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 验证静态分析**

Run: `cd Mobile/mobile_app && flutter analyze lib/features/pages/fence_page.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/pages/fence_page.dart
git commit -m "feat(fence): rewrite FencePage with fullscreen map and draggable drawer"
```

---

## Task 8: FenceFormPage 新建/编辑表单

**Files:**
- Create: `lib/features/pages/fence_form_page.dart`

- [ ] **Step 1: 创建 FenceFormPage**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';

class FenceFormPage extends ConsumerStatefulWidget {
  const FenceFormPage({super.key, this.fenceId});

  final String? fenceId;

  @override
  ConsumerState<FenceFormPage> createState() => _FenceFormPageState();
}

class _FenceFormPageState extends ConsumerState<FenceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  FenceType _type = FenceType.rectangle;
  bool _alarmEnabled = true;
  bool _active = true;
  bool _saving = false;
  bool _initialized = false;

  bool get _isEdit => widget.fenceId != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initForEdit() {
    if (_initialized || !_isEdit) return;
    _initialized = true;
    final fenceState = ref.read(fenceControllerProvider);
    FenceItem? fence;
    for (final f in fenceState.fences) {
      if (f.id == widget.fenceId) {
        fence = f;
        break;
      }
    }
    if (fence == null) return;
    _nameController.text = fence.name;
    _type = fence.type;
    _alarmEnabled = fence.alarmEnabled;
    _active = fence.active;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 500));

    final controller = ref.read(fenceControllerProvider.notifier);
    if (_isEdit) {
      final fenceState = ref.read(fenceControllerProvider);
      FenceItem? existing;
      for (final f in fenceState.fences) {
        if (f.id == widget.fenceId) {
          existing = f;
          break;
        }
      }
      if (existing != null) {
        controller.update(existing.copyWith(
          name: _nameController.text,
          type: _type,
          alarmEnabled: _alarmEnabled,
          active: _active,
        ));
      }
    } else {
      final id = 'fence_${DateTime.now().millisecondsSinceEpoch}';
      final fenceCount = ref.read(fenceControllerProvider).fences.length;
      controller.add(FenceItem(
        id: id,
        name: _nameController.text,
        type: _type,
        alarmEnabled: _alarmEnabled,
        active: _active,
        areaHectares: 1.0,
        livestockCount: 0,
        colorValue:
            FenceItem.defaultColors[fenceCount % FenceItem.defaultColors.length],
        points: FenceItem.defaultPointsForType(_type, DemoSeed.mapCenter),
      ));
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    _initForEdit();
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑围栏' : '新建围栏'),
        leading: IconButton(
          key: const Key('fence-form-back'),
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        key: const Key('page-fence-form'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('fence-form-name'),
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '围栏名称',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入围栏名称' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<FenceType>(
                key: const Key('fence-form-type'),
                value: _type,
                decoration: const InputDecoration(
                  labelText: '围栏类型',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: FenceType.rectangle,
                    child: Text('矩形'),
                  ),
                  DropdownMenuItem(
                    value: FenceType.circle,
                    child: Text('圆形'),
                  ),
                  DropdownMenuItem(
                    value: FenceType.polygon,
                    child: Text('多边形'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '面积：1.0 公顷',
                key: const Key('fence-form-area'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                key: const Key('fence-form-map-placeholder'),
                height: 180,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F2E5), Color(0xFFF8F6F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.lg),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.draw_outlined,
                        size: 32,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '地图选区（占位）',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SwitchListTile(
                key: const Key('fence-form-alarm'),
                contentPadding: EdgeInsets.zero,
                title: const Text('启用告警'),
                value: _alarmEnabled,
                onChanged: (v) => setState(() => _alarmEnabled = v),
              ),
              SwitchListTile(
                key: const Key('fence-form-active'),
                contentPadding: EdgeInsets.zero,
                title: const Text('启用状态'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('fence-form-cancel'),
                      onPressed: () => context.pop(),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      key: const Key('fence-form-save'),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('保存围栏'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 验证静态分析**

Run: `cd Mobile/mobile_app && flutter analyze lib/features/pages/fence_form_page.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/pages/fence_form_page.dart
git commit -m "feat(fence): add FenceFormPage for create and edit"
```

---

## Task 9: AppRouter 路由接线

**Files:**
- Modify: `lib/app/app_router.dart`

- [ ] **Step 1: 更新路由配置**

在 `lib/app/app_router.dart` 中执行以下变更：

**删除 import：**
- `import 'package:smart_livestock_demo/features/pages/fence_create_page.dart';`
- `import 'package:smart_livestock_demo/features/pages/map_page.dart';`

**新增 import：**
- `import 'package:smart_livestock_demo/features/pages/fence_form_page.dart';`

**删除路由（在 ShellRoute 的 routes 数组中）：**

删除 map 路由块：
```dart
          GoRoute(
            path: AppRoute.map.path,
            name: AppRoute.map.routeName,
            builder: (context, state) => const MapPage(),
          ),
```

删除 fenceCreate 路由块：
```dart
          GoRoute(
            path: AppRoute.fenceCreate.path,
            name: AppRoute.fenceCreate.routeName,
            builder: (context, state) => const FenceCreatePage(),
          ),
```

**修改 fence 路由块** — 移除 Consumer 包装，FencePage 不再接收 role 参数：
```dart
          GoRoute(
            path: AppRoute.fence.path,
            name: AppRoute.fence.routeName,
            builder: (context, state) => const FencePage(),
          ),
```

**新增 fenceForm 路由块**（放在 fence 路由下方）：
```dart
          GoRoute(
            path: AppRoute.fenceForm.path,
            name: AppRoute.fenceForm.routeName,
            builder: (context, state) {
              final id = state.uri.queryParameters['id'];
              return FenceFormPage(fenceId: id);
            },
          ),
```

- [ ] **Step 2: 验证静态分析**

Run: `cd Mobile/mobile_app && flutter analyze lib/app/app_router.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/app/app_router.dart
git commit -m "feat(router): replace map and fenceCreate routes with fenceForm"
```

---

## Task 10: 删除废弃文件

**Files:**
- Delete: 10 files across `features/fence_create/`, `features/map/`, `features/pages/`

- [ ] **Step 1: 删除围栏新建模块**

```bash
cd Mobile/mobile_app
rm lib/features/fence_create/domain/fence_create_repository.dart
rm lib/features/fence_create/data/mock_fence_create_repository.dart
rm lib/features/fence_create/data/live_fence_create_repository.dart
rm lib/features/fence_create/presentation/fence_create_controller.dart
rm lib/features/pages/fence_create_page.dart
```

- [ ] **Step 2: 删除地图模块**

```bash
rm lib/features/map/domain/map_repository.dart
rm lib/features/map/data/mock_map_repository.dart
rm lib/features/map/data/live_map_repository.dart
rm lib/features/map/presentation/map_controller.dart
rm lib/features/pages/map_page.dart
```

- [ ] **Step 3: 删除空目录**

```bash
rmdir lib/features/fence_create/domain lib/features/fence_create/data lib/features/fence_create/presentation lib/features/fence_create
rmdir lib/features/map/domain lib/features/map/data lib/features/map/presentation lib/features/map
```

- [ ] **Step 4: 验证无残留引用**

Run: `cd Mobile/mobile_app && grep -r "map_page\|fence_create_page\|map_repository\|map_controller\|fence_create_repository\|fence_create_controller" lib/`
Expected: No output (no remaining references)

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: remove obsolete map and fence_create modules"
```

---

## Task 11: 更新测试套件

**Files:**
- Rewrite: `test/widget_smoke_test.dart`
- Rewrite: `test/flow_smoke_test.dart`
- Rewrite: `test/role_visibility_test.dart`
- Rewrite: `test/mock_repository_override_test.dart`
- Rewrite: `test/mock_repository_state_test.dart`
- Rewrite: `test/state_persistence_test.dart`
- Rewrite: `test/app_mode_switch_test.dart`
- Delete: `test/highfi/map_fence_highfi_test.dart`
- Modify: `test/seed_data_test.dart`

- [ ] **Step 1: 删除 map_fence_highfi_test.dart**

```bash
cd Mobile/mobile_app && rm test/highfi/map_fence_highfi_test.dart
```

- [ ] **Step 2: 重写 widget_smoke_test.dart**

替换 `test/widget_smoke_test.dart` 全部内容：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';

void main() {
  testWidgets('owner 登录后业务导航可到达五页面', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('page-twin')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-fence')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-alerts')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-alerts')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-mine')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-mine')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-admin')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-admin')), findsOneWidget);
  });

  testWidgets('worker 登录后不显示 nav-admin', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-worker')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nav-admin')), findsNothing);
  });

  testWidgets('导航中不存在 nav-map', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nav-map')), findsNothing);
  });

  testWidgets('围栏页底部抽屉标题可见（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fence-drawer-title')), findsOneWidget);
  });

  testWidgets('孪生页高保真组件可见（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('twin-farm-header')), findsOneWidget);
    expect(find.byKey(const Key('twin-metric-alert-pending')), findsOneWidget);
  });
}
```

- [ ] **Step 3: 重写 flow_smoke_test.dart**

替换 `test/flow_smoke_test.dart` 全部内容：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';

void main() {
  testWidgets('流程3：告警 确认→处理→归档（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-alerts')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('alert-confirm')));
    await tester.pump();
    expect(find.byKey(const Key('alert-status-confirmed')), findsOneWidget);

    await tester.tap(find.byKey(const Key('alert-handle')));
    await tester.pump();
    expect(find.byKey(const Key('alert-status-handled')), findsOneWidget);

    await tester.tap(find.byKey(const Key('alert-archive')));
    await tester.pump();
    expect(find.byKey(const Key('alert-status-archived')), findsOneWidget);
  });

  testWidgets('流程3b：告警批量处理给出演示反馈（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-alerts')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('alert-batch')));
    await tester.pumpAndSettle();

    expect(find.text('演示：批量处理待接入'), findsOneWidget);
  });

  testWidgets('流程4a：围栏页显示抽屉标题和围栏卡片（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fence-drawer-title')), findsOneWidget);
    expect(find.byKey(const Key('fence-card-fence_pasture_a')), findsOneWidget);
    expect(find.byKey(const Key('fence-add')), findsOneWidget);
  });

  testWidgets('流程4b：围栏新增跳转表单页再返回（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('fence-add')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-fence-form')), findsOneWidget);
    expect(find.text('新建围栏'), findsOneWidget);

    await tester.tap(find.byKey(const Key('fence-form-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-fence')), findsOneWidget);
  });

  testWidgets('流程4c：围栏删除弹窗确认后移除（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fence-card-fence_pasture_a')), findsOneWidget);

    await tester.tap(find.byKey(const Key('fence-delete-fence_pasture_a')));
    await tester.pumpAndSettle();

    expect(find.text('确认删除'), findsOneWidget);
    expect(find.text('确认删除「放牧A区」？删除后无法恢复。'), findsOneWidget);

    await tester.tap(find.byKey(const Key('fence-delete-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fence-card-fence_pasture_a')), findsNothing);
    expect(find.text('已删除「放牧A区」'), findsOneWidget);
  });

  testWidgets('流程4d：租户 license 调整演示反馈（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-admin')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tenant-license-adjust')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('tenant-license-demo-applied')), findsOneWidget);
  });

  testWidgets('流程1：登录后角色分流（worker 无后台 tab）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-worker')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nav-admin')), findsNothing);
  });

  testWidgets('流程1：ops 直达租户后台', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-ops')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('租户后台占位'), findsOneWidget);
    expect(find.byKey(const Key('nav-alerts')), findsNothing);
  });
}
```

- [ ] **Step 4: 重写 role_visibility_test.dart**

替换 `test/role_visibility_test.dart` 全部内容：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';

void main() {
  testWidgets('高保真登录与后台/我的页面仍保持正确角色边界', (tester) async {
    await tester.pumpWidget(const DemoApp());

    expect(find.byKey(const Key('login-hero-card')), findsOneWidget);

    await tester.tap(find.byKey(const Key('role-ops')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-overview-card')), findsOneWidget);
    expect(find.byKey(const Key('nav-alerts')), findsNothing);
  });

  testWidgets('worker 进入围栏页后不可见编辑/删除按钮', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.tap(find.byKey(const Key('role-worker')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('page-fence')), findsOneWidget);
    expect(find.byKey(const Key('fence-drawer-title')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-fence_pasture_a')), findsNothing);
    expect(find.byKey(const Key('fence-delete-fence_pasture_a')), findsNothing);
    expect(find.byKey(const Key('fence-add')), findsNothing);
  });

  testWidgets('owner 进入围栏页后可见编辑/删除/新增按钮', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('page-fence')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-fence_pasture_a')), findsOneWidget);
    expect(find.byKey(const Key('fence-delete-fence_pasture_a')), findsOneWidget);
    expect(find.byKey(const Key('fence-add')), findsOneWidget);
  });

  testWidgets('owner 可进入我的页并看到高保真个人卡片', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-mine')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mine-profile-card')), findsOneWidget);
  });

  testWidgets('ops 登录后进入租户后台且不显示围栏元素', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.tap(find.byKey(const Key('role-ops')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('租户后台占位'), findsOneWidget);
    expect(find.byKey(const Key('nav-fence')), findsNothing);
    expect(find.byKey(const Key('page-fence')), findsNothing);
  });

  test('ops 角色枚举存在', () {
    expect(DemoRole.values, contains(DemoRole.ops));
  });
}
```

- [ ] **Step 5: 重写 mock_repository_override_test.dart**

替换 `test/mock_repository_override_test.dart` 全部内容：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/dashboard/domain/dashboard_repository.dart';
import 'package:smart_livestock_demo/features/dashboard/presentation/dashboard_controller.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('Dashboard 可通过仓储 override 注入自定义指标', (tester) async {
    await tester.pumpWidget(
      DemoApp(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(
            const _FakeDashboardRepository(),
          ),
        ],
      ),
    );

    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    final ctx = tester.element(find.byKey(const Key('page-twin')));
    GoRouter.of(ctx).go('/dashboard');
    await tester.pumpAndSettle();

    expect(find.text('自定义指标'), findsOneWidget);
    expect(find.text('999'), findsOneWidget);
  });

  testWidgets('Fence 可通过仓储 override 注入自定义围栏列表', (tester) async {
    await tester.pumpWidget(
      DemoApp(
        overrides: [
          fenceRepositoryProvider.overrideWithValue(
            const _FakeFenceRepository(),
          ),
        ],
      ),
    );

    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();

    expect(find.text('测试围栏'), findsOneWidget);
  });
}

class _FakeDashboardRepository implements DashboardRepository {
  const _FakeDashboardRepository();

  @override
  DashboardViewData load(ViewState viewState) {
    return const DashboardViewData(
      viewState: ViewState.normal,
      metrics: [
        DashboardMetric(
          widgetKey: 'dashboard-metric-custom',
          title: '自定义指标',
          value: '999',
        ),
      ],
    );
  }
}

class _FakeFenceRepository implements FenceRepository {
  const _FakeFenceRepository();

  @override
  List<FenceItem> loadAll() {
    return [
      FenceItem(
        id: 'fake-fence-1',
        name: '测试围栏',
        type: FenceType.rectangle,
        alarmEnabled: true,
        active: true,
        areaHectares: 5.0,
        livestockCount: 10,
        colorValue: 0xFF4C9A5F,
        points: const [
          LatLng(28.230, 112.940),
          LatLng(28.230, 112.944),
          LatLng(28.234, 112.944),
          LatLng(28.234, 112.940),
        ],
      ),
    ];
  }
}
```

- [ ] **Step 6: 重写 mock_repository_state_test.dart**

替换 `test/mock_repository_state_test.dart` 全部内容：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/admin/data/mock_admin_repository.dart';
import 'package:smart_livestock_demo/features/alerts/data/mock_alerts_repository.dart';
import 'package:smart_livestock_demo/features/alerts/domain/alerts_repository.dart';
import 'package:smart_livestock_demo/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:smart_livestock_demo/features/fence/data/mock_fence_repository.dart';
import 'package:smart_livestock_demo/features/mine/data/mock_mine_repository.dart';

void main() {
  test('Dashboard mock repository 支持全部 ViewState', () {
    const repository = MockDashboardRepository();

    for (final state in ViewState.values) {
      final data = repository.load(state);
      expect(data.viewState, state);
      expect(data.metrics, isNotEmpty);
    }
  });

  test('Fence mock repository 返回包含牲畜统计的围栏列表', () {
    const repository = MockFenceRepository();
    final fences = repository.loadAll();

    expect(fences.length, 4);
    expect(fences[0].name, '放牧A区');
    expect(fences[0].livestockCount, 25);
    expect(fences[1].name, '放牧B区');
    expect(fences[1].livestockCount, 18);
    expect(fences[2].name, '夜间休息区');
    expect(fences[2].livestockCount, 4);
    expect(fences[3].name, '隔离区');
    expect(fences[3].livestockCount, 3);
  });

  test('Alerts mock repository 保留角色与阶段', () {
    const repository = MockAlertsRepository();

    for (final state in ViewState.values) {
      final data = repository.load(
        viewState: state,
        role: DemoRole.owner,
        stage: AlertStage.handled,
      );
      expect(data.viewState, state);
      expect(data.role, DemoRole.owner);
      expect(data.stage, AlertStage.handled);
    }
  });

  test('Admin 与 Mine mock repository 支持全部 ViewState', () {
    const adminRepository = MockAdminRepository();
    const mineRepository = MockMineRepository();

    for (final state in ViewState.values) {
      expect(
        adminRepository
            .load(viewState: state, licenseAdjusted: true)
            .viewState,
        state,
      );
      expect(mineRepository.load(state).viewState, state);
    }
  });
}
```

- [ ] **Step 7: 重写 state_persistence_test.dart**

替换 `test/state_persistence_test.dart` 全部内容：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';

void main() {
  testWidgets('围栏选中状态在路由切换后保持', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();

    final fenceCtx = tester.element(find.byKey(const Key('page-fence')));
    ProviderScope.containerOf(fenceCtx)
        .read(fenceControllerProvider.notifier)
        .select('fence_pasture_a');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-alerts')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();

    final state = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('page-fence'))),
    ).read(fenceControllerProvider);
    expect(state.selectedFenceId, 'fence_pasture_a');
  });
}
```

- [ ] **Step 8: 重写 app_mode_switch_test.dart**

替换 `test/app_mode_switch_test.dart` 全部内容：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/features/dashboard/presentation/dashboard_controller.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';

void main() {
  test('AppMode.live 下仓储 provider 切换到 live 实现', () {
    final container = ProviderContainer(
      overrides: [
        appModeProvider.overrideWithValue(AppMode.live),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(dashboardRepositoryProvider).runtimeType.toString(),
      contains('Live'),
    );
    expect(
      container.read(fenceRepositoryProvider).runtimeType.toString(),
      contains('Live'),
    );
  });
}
```

- [ ] **Step 9: 更新 seed_data_test.dart**

在 `test/seed_data_test.dart` 中，在 `'DemoSeed has 4 fences'` 测试之后添加新测试：

```dart
  test('FencePolygon 包含扩展字段', () {
    for (final f in DemoSeed.fencePolygons) {
      expect(f.type, isNotEmpty);
      expect(f.areaHectares, greaterThan(0));
    }
  });
```

- [ ] **Step 10: 运行测试验证**

Run: `cd Mobile/mobile_app && flutter test`
Expected: All tests pass

- [ ] **Step 11: Commit**

```bash
cd Mobile/mobile_app
git add -A
git commit -m "test: update all tests for fence CRUD refactoring"
```

---

## Task 12: 最终验证

- [ ] **Step 1: 静态分析**

Run: `cd Mobile/mobile_app && flutter analyze`
Expected: No issues found

- [ ] **Step 2: 全量测试**

Run: `cd Mobile/mobile_app && flutter test`
Expected: All tests pass

- [ ] **Step 3: 检查无遗留引用**

Run: `cd Mobile/mobile_app && grep -r "MapPage\|FenceCreatePage\|map_controller\|fence_create_controller\|MapViewData\|FenceViewData\|MapRepository\|FenceCreateRepository\|nav-map\|page-map\|fence-create-" lib/ test/`
Expected: No output

- [ ] **Step 4: 确认 Key 完整性**

关键 Key 对照表：

| Key | 位置 |
|-----|------|
| `page-fence` | FencePage Scaffold |
| `page-fence-form` | FenceFormPage ScrollView |
| `fence-drawer-title` | 抽屉标题 "围栏 (N)" |
| `fence-add` | 新建按钮 |
| `fence-card-{id}` | 围栏卡片 |
| `fence-edit-{id}` | 编辑按钮 |
| `fence-delete-{id}` | 删除按钮 |
| `fence-delete-cancel` | 删除弹窗取消 |
| `fence-delete-confirm` | 删除弹窗确认 |
| `fence-empty-hint` | 空状态提示 |
| `fence-form-back` | 表单返回 |
| `fence-form-name` | 名称输入 |
| `fence-form-type` | 类型下拉 |
| `fence-form-area` | 面积文本 |
| `fence-form-map-placeholder` | 地图选区占位 |
| `fence-form-alarm` | 告警开关 |
| `fence-form-active` | 状态开关 |
| `fence-form-cancel` | 取消按钮 |
| `fence-form-save` | 保存按钮 |
| `nav-fence` | 导航项（第二位，Icons.map） |

- [ ] **Step 5: 最终 Commit**

```bash
cd Mobile/mobile_app
git add -A
git commit -m "feat(fence): complete fence CRUD with map+drawer, form, delete dialog"
```
