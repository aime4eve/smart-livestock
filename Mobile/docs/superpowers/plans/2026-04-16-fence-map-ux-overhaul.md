# 围栏地图交互体验重构 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 统一浏览态/编辑态为单一 FlutterMap，升级命中检测容差和选中动画，改善编辑态手势和上下文体验

**Architecture:** 删除 `FenceEditOverlay`（独立地图实例），将编辑态的顶点手柄/平移手势层直接嵌入主地图的 MarkerLayer/Stack。通过 `Listener` 追踪指针数量实现多指缩放与单指编辑操作共存。新增屏幕空间命中检测（40px 边界容差）、呼吸动画、重叠候选列表、迷你标题条。

**Tech Stack:** Flutter, flutter_map, flutter_riverpod, latlong2

---

## Issue 索引

| 优先级 | Issue | 标题 |
|--------|-------|------|
| P0 | #24 | 围栏地图交互体验重构 |

## 完成记录

| 完成日期 | Issue | PR | 备注 |
|----------|-------|----|------|
| 2026-04-17 | #24 | #25 | 9 个 Task 全部完成，单一 FlutterMap 架构落地 |

---

## File Structure

### New Files
| File | Responsibility |
|------|---------------|
| `lib/features/fence/presentation/fence_hit_detection.dart` | 屏幕空间命中检测：边界容差 + 内部射线法 + 面积排序 |
| `lib/features/fence/presentation/widgets/fence_candidate_sheet.dart` | 重叠围栏候选列表 BottomSheet |
| `lib/features/fence/presentation/widgets/fence_mini_title_bar.dart` | 编辑态迷你标题条（围栏名称 + 撤销/重做） |
| `test/features/fence/fence_hit_detection_test.dart` | 命中检测单元测试 |

### Modified Files
| File | Change |
|------|--------|
| `lib/core/theme/app_colors.dart` | 新增 `overlayDark` token |
| `lib/features/fence/presentation/widgets/fence_edit_toolbar.dart` | 移除撤销/重做按钮（移到迷你标题条） |
| `lib/features/pages/fence_page.dart` | 重写：单一 FlutterMap + 呼吸动画 + 新命中检测 + 编辑态内联 + 多指手势路由 |
| `test/features/fence/fence_map_tap_highlight_test.dart` | 更新高亮 alpha 值 + 新增命中容差/候选列表用例 |
| `test/features/fence/fence_edit_overlay_test.dart` | 重写为 `fence_edit_ui_test.dart`（不再依赖独立 overlay） |
| `test/features/fence/fence_page_mode_switch_test.dart` | 替换 `fence-edit-overlay` key 引用为新 key |

### Deleted Files
| File | Reason |
|------|--------|
| `lib/features/fence/presentation/widgets/fence_edit_overlay.dart` | 不再需要独立地图 Widget |

---

## Task 1: Add `AppColors.overlayDark` Theme Token

**Files:**
- Modify: `lib/core/theme/app_colors.dart:1-22`
- Test: `test/features/fence/fence_hit_detection_test.dart` (later task)

- [x] **Step 1: Add the token**

Open `Mobile/mobile_app/lib/core/theme/app_colors.dart` and add after the `info` line:

```dart
static const Color overlayDark = Color(0xB3000000);
```

Full file after edit:

```dart
import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF2F6B3B);
  static const Color primaryDark = Color(0xFF244F2D);
  static const Color primarySoft = Color(0xFFE3F0E4);
  static const Color accent = Color(0xFF8BA95A);

  static const Color surface = Color(0xFFF8F6F0);
  static const Color surfaceAlt = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFD7D2C6);

  static const Color textPrimary = Color(0xFF263126);
  static const Color textSecondary = Color(0xFF617061);

  static const Color success = Color(0xFF4C9A5F);
  static const Color warning = Color(0xFFD28A2D);
  static const Color danger = Color(0xFFC2564B);
  static const Color info = Color(0xFF4A7F9D);

  static const Color overlayDark = Color(0xB3000000);
}
```

`0xB3` ≈ 70% opacity black, 用于编辑态迷你标题条半透明深色背景。

- [x] **Step 2: Run analyze to verify**

Run: `cd Mobile/mobile_app && flutter analyze`
Expected: No new warnings.

- [x] **Step 3: Commit**

```bash
cd Mobile/mobile_app
git add lib/core/theme/app_colors.dart
git commit -m "feat(theme): add AppColors.overlayDark for edit mode title bar"
```

---

## Task 2: Create Hit Detection Utility with Tests

**Files:**
- Create: `lib/features/fence/presentation/fence_hit_detection.dart`
- Create: `test/features/fence/fence_hit_detection_test.dart`

- [x] **Step 1: Write the failing tests**

Create `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart`:

```dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_hit_detection.dart';

Offset _identityProject(LatLng ll) => Offset(ll.longitude, ll.latitude);

FenceItem _makeFence(String id, List<LatLng> points, {double area = 1.0}) =>
    FenceItem(
      id: id,
      name: id,
      type: FenceType.polygon,
      alarmEnabled: false,
      active: true,
      areaHectares: area,
      livestockCount: 0,
      colorValue: 0xFF4C9A5F,
      points: points,
    );

void main() {
  group('distanceToSegment', () {
    test('点在线段上投影距离为 0', () {
      expect(
        distanceToSegment(
          const Offset(5, 0),
          const Offset(0, 0),
          const Offset(10, 0),
        ),
        closeTo(0, 0.001),
      );
    });

    test('点到线段端点的距离', () {
      expect(
        distanceToSegment(
          const Offset(0, 3),
          const Offset(0, 0),
          const Offset(10, 0),
        ),
        closeTo(3, 0.001),
      );
    });

    test('点到线段外延的距离取端点', () {
      expect(
        distanceToSegment(
          const Offset(-3, 0),
          const Offset(0, 0),
          const Offset(10, 0),
        ),
        closeTo(3, 0.001),
      );
    });
  });

  group('isPointNearPolygonBoundary', () {
    final square = [
      const Offset(0, 0),
      const Offset(100, 0),
      const Offset(100, 100),
      const Offset(0, 100),
    ];

    test('点在边界上命中', () {
      expect(
        isPointNearPolygonBoundary(const Offset(50, 0), square, 40),
        isTrue,
      );
    });

    test('点在 40px 内命中', () {
      expect(
        isPointNearPolygonBoundary(const Offset(50, 30), square, 40),
        isTrue,
      );
    });

    test('点在 40px 外未命中', () {
      expect(
        isPointNearPolygonBoundary(const Offset(50, 50), square, 40),
        isFalse,
      );
    });

    test('少于 2 个点返回 false', () {
      expect(
        isPointNearPolygonBoundary(const Offset(0, 0), [const Offset(0, 0)], 40),
        isFalse,
      );
    });
  });

  group('detectFenceHits', () {
    final smallFence = _makeFence(
      'small',
      const [LatLng(0, 0), LatLng(0, 10), LatLng(10, 10), LatLng(10, 0)],
      area: 1.0,
    );
    final largeFence = _makeFence(
      'large',
      const [LatLng(-50, -50), LatLng(-50, 150), LatLng(150, 150), LatLng(150, -50)],
      area: 100.0,
    );

    test('点在围栏内部命中（地理空间射线法）', () {
      final results = detectFenceHits(
        tapScreenPoint: const Offset(5, 5),
        tapLatLng: const LatLng(5, 5),
        fences: [smallFence],
        project: _identityProject,
      );
      expect(results.length, 1);
      expect(results.first.fenceId, 'small');
    });

    test('点在边界 40px 内命中（屏幕空间容差）', () {
      final results = detectFenceHits(
        tapScreenPoint: const Offset(5, -20),
        tapLatLng: const LatLng(-20, 5),
        fences: [smallFence],
        project: _identityProject,
      );
      expect(results.length, 1);
      expect(results.first.fenceId, 'small');
    });

    test('点在边界 40px 外未命中', () {
      final results = detectFenceHits(
        tapScreenPoint: const Offset(5, -50),
        tapLatLng: const LatLng(-50, 5),
        fences: [smallFence],
        project: _identityProject,
      );
      expect(results, isEmpty);
    });

    test('重叠围栏按面积升序排列', () {
      final results = detectFenceHits(
        tapScreenPoint: const Offset(5, 5),
        tapLatLng: const LatLng(5, 5),
        fences: [largeFence, smallFence],
        project: _identityProject,
      );
      expect(results.length, 2);
      expect(results[0].fenceId, 'small');
      expect(results[1].fenceId, 'large');
    });

    test('空围栏列表返回空', () {
      final results = detectFenceHits(
        tapScreenPoint: const Offset(5, 5),
        tapLatLng: const LatLng(5, 5),
        fences: const [],
        project: _identityProject,
      );
      expect(results, isEmpty);
    });
  });
}
```

- [x] **Step 2: Run tests to verify they fail**

Run: `cd Mobile/mobile_app && flutter test test/features/fence/fence_hit_detection_test.dart`
Expected: FAIL — `fence_hit_detection.dart` does not exist yet.

- [x] **Step 3: Implement the hit detection utility**

Create `Mobile/mobile_app/lib/features/fence/presentation/fence_hit_detection.dart`:

```dart
import 'dart:ui';

import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_polygon_contains.dart';

typedef LatLngToOffset = Offset Function(LatLng);

class FenceHitResult {
  const FenceHitResult({required this.fenceId, required this.areaHectares});

  final String fenceId;
  final double areaHectares;
}

double distanceToSegment(Offset point, Offset start, Offset end) {
  final dx = end.dx - start.dx;
  final dy = end.dy - start.dy;
  if (dx == 0 && dy == 0) {
    return (point - start).distance;
  }
  final t = (((point.dx - start.dx) * dx) + ((point.dy - start.dy) * dy)) /
      ((dx * dx) + (dy * dy));
  final clampedT = t.clamp(0.0, 1.0);
  final projection = Offset(
    start.dx + dx * clampedT,
    start.dy + dy * clampedT,
  );
  return (point - projection).distance;
}

bool isPointNearPolygonBoundary(
  Offset point,
  List<Offset> polygonScreenPoints,
  double tolerance,
) {
  if (polygonScreenPoints.length < 2) {
    return false;
  }
  for (var i = 0; i < polygonScreenPoints.length; i++) {
    final start = polygonScreenPoints[i];
    final end = polygonScreenPoints[(i + 1) % polygonScreenPoints.length];
    if (distanceToSegment(point, start, end) < tolerance) {
      return true;
    }
  }
  return false;
}

List<FenceHitResult> detectFenceHits({
  required Offset tapScreenPoint,
  required LatLng tapLatLng,
  required List<FenceItem> fences,
  required LatLngToOffset project,
  double boundaryTolerancePx = 40.0,
}) {
  final results = <FenceHitResult>[];
  for (final fence in fences) {
    if (fence.points.length < 3) {
      continue;
    }

    final insideGeo = fencePolygonContainsLatLng(tapLatLng, fence.points);

    var nearBoundary = false;
    if (!insideGeo) {
      final screenPoints = <Offset>[];
      var projectionFailed = false;
      for (final p in fence.points) {
        try {
          screenPoints.add(project(p));
        } catch (_) {
          projectionFailed = true;
          break;
        }
      }
      if (!projectionFailed) {
        nearBoundary = isPointNearPolygonBoundary(
          tapScreenPoint,
          screenPoints,
          boundaryTolerancePx,
        );
      }
    }

    if (insideGeo || nearBoundary) {
      results.add(FenceHitResult(
        fenceId: fence.id,
        areaHectares: fence.areaHectares,
      ));
    }
  }
  results.sort((a, b) => a.areaHectares.compareTo(b.areaHectares));
  return results;
}
```

- [x] **Step 4: Run tests to verify they pass**

Run: `cd Mobile/mobile_app && flutter test test/features/fence/fence_hit_detection_test.dart -v`
Expected: All tests PASS.

- [x] **Step 5: Commit**

```bash
cd Mobile/mobile_app
git add lib/features/fence/presentation/fence_hit_detection.dart test/features/fence/fence_hit_detection_test.dart
git commit -m "feat(fence): add screen-space hit detection with 40px boundary tolerance"
```

---

## Task 3: Create Candidate Sheet Widget

**Files:**
- Create: `lib/features/fence/presentation/widgets/fence_candidate_sheet.dart`

- [x] **Step 1: Create the widget**

Create `Mobile/mobile_app/lib/features/fence/presentation/widgets/fence_candidate_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';

Future<String?> showFenceCandidateSheet(
  BuildContext context,
  List<FenceItem> candidates,
) {
  return showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.lg)),
    ),
    builder: (ctx) => _CandidateList(
      key: const Key('fence-candidate-sheet'),
      candidates: candidates,
    ),
  );
}

class _CandidateList extends StatelessWidget {
  const _CandidateList({super.key, required this.candidates});

  final List<FenceItem> candidates;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              '选择围栏',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final fence in candidates)
            ListTile(
              key: Key('fence-candidate-${fence.id}'),
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(fence.colorValue),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(fence.name),
              trailing: Text(
                '${fence.livestockCount}头',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              onTap: () => Navigator.of(context).pop(fence.id),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
```

- [x] **Step 2: Run analyze**

Run: `cd Mobile/mobile_app && flutter analyze`
Expected: No new warnings.

- [x] **Step 3: Commit**

```bash
cd Mobile/mobile_app
git add lib/features/fence/presentation/widgets/fence_candidate_sheet.dart
git commit -m "feat(fence): add overlapping fence candidate BottomSheet widget"
```

---

## Task 4: Create Mini Title Bar Widget

**Files:**
- Create: `lib/features/fence/presentation/widgets/fence_mini_title_bar.dart`

- [x] **Step 1: Create the widget**

Create `Mobile/mobile_app/lib/features/fence/presentation/widgets/fence_mini_title_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';

class FenceMiniTitleBar extends StatelessWidget {
  const FenceMiniTitleBar({
    super.key,
    required this.fenceName,
    required this.onBack,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
  });

  final String fenceName;
  final VoidCallback onBack;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('fence-edit-mini-title'),
      height: 48,
      color: AppColors.overlayDark,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              key: const Key('fence-edit-back'),
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: '返回',
              iconSize: 20,
            ),
            Expanded(
              child: Text(
                '编辑围栏：$fenceName',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              key: const Key('fence-edit-undo'),
              onPressed: canUndo ? onUndo : null,
              icon: Icon(
                Icons.undo,
                color: canUndo ? Colors.white : Colors.white38,
              ),
              tooltip: '撤销',
              iconSize: 20,
            ),
            IconButton(
              key: const Key('fence-edit-redo'),
              onPressed: canRedo ? onRedo : null,
              icon: Icon(
                Icons.redo,
                color: canRedo ? Colors.white : Colors.white38,
              ),
              tooltip: '重做',
              iconSize: 20,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [x] **Step 2: Run analyze**

Run: `cd Mobile/mobile_app && flutter analyze`
Expected: No new warnings.

- [x] **Step 3: Commit**

```bash
cd Mobile/mobile_app
git add lib/features/fence/presentation/widgets/fence_mini_title_bar.dart
git commit -m "feat(fence): add edit mode mini title bar with undo/redo"
```

---

## Task 5: Modify Toolbar — Remove Undo/Redo

**Files:**
- Modify: `lib/features/fence/presentation/widgets/fence_edit_toolbar.dart`

> **Note:** This task is part of a coordinated commit with Tasks 6–8. Do NOT commit separately — tests will fail until fence_page.dart is rewritten and test files are updated.

- [x] **Step 1: Rewrite the toolbar**

Replace the full content of `Mobile/mobile_app/lib/features/fence/presentation/widgets/fence_edit_toolbar.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_edit_session.dart';

class FenceEditToolbar extends StatelessWidget {
  const FenceEditToolbar({
    super.key,
    required this.activeTool,
    required this.onSave,
    required this.onExit,
    required this.onSelectTool,
    this.canSave = true,
    this.canExit = true,
    this.canSelectTool = true,
  });

  final FenceEditTool activeTool;
  final VoidCallback onSave;
  final VoidCallback onExit;
  final ValueChanged<FenceEditTool> onSelectTool;
  final bool canSave;
  final bool canExit;
  final bool canSelectTool;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('fence-edit-toolbar'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.surfaceAlt,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              key: const Key('fence-edit-exit'),
              onPressed: canExit ? onExit : null,
              icon: const Icon(Icons.close),
              tooltip: '退出编辑',
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ToolButton(
                      widgetKey: 'fence-edit-tool-move',
                      icon: Icons.open_with,
                      label: '拖点',
                      active: activeTool == FenceEditTool.moveVertex,
                      onPressed: canSelectTool
                          ? () => onSelectTool(FenceEditTool.moveVertex)
                          : null,
                    ),
                    _ToolButton(
                      widgetKey: 'fence-edit-tool-insert',
                      icon: Icons.add_circle_outline,
                      label: '插点',
                      active: activeTool == FenceEditTool.insertVertex,
                      onPressed: canSelectTool
                          ? () => onSelectTool(FenceEditTool.insertVertex)
                          : null,
                    ),
                    _ToolButton(
                      widgetKey: 'fence-edit-tool-delete',
                      icon: Icons.remove_circle_outline,
                      label: '删点',
                      active: activeTool == FenceEditTool.deleteVertex,
                      onPressed: canSelectTool
                          ? () => onSelectTool(FenceEditTool.deleteVertex)
                          : null,
                    ),
                    _ToolButton(
                      widgetKey: 'fence-edit-tool-translate',
                      icon: Icons.pan_tool_alt_outlined,
                      label: '平移',
                      active: activeTool == FenceEditTool.translate,
                      onPressed: canSelectTool
                          ? () => onSelectTool(FenceEditTool.translate)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              key: const Key('fence-edit-save'),
              onPressed: canSave ? onSave : null,
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.widgetKey,
    required this.icon,
    required this.label,
    required this.active,
    required this.onPressed,
  });

  final String widgetKey;
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final child = active
        ? FilledButton.tonalIcon(
            key: Key(widgetKey),
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          )
        : OutlinedButton.icon(
            key: Key(widgetKey),
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          );
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: child,
    );
  }
}
```

Key changes vs. original:
- Removed `isEditing` parameter (toolbar only renders when editing)
- Removed `onUndo`, `onRedo`, `canUndo`, `canRedo` (moved to `FenceMiniTitleBar`)
- Added `SafeArea(top: false)` for bottom safe area
- 退出按钮（`fence-edit-exit`，`Icons.close`）从原工具栏保留，行为不变；系统返回键行为也保持不变（通过 `PopScope` 触发 `_handleEditExit`）

---

## Task 6: Rewrite `fence_page.dart` — Single Map Architecture

**Files:**
- Modify: `lib/features/pages/fence_page.dart:1-910`

> **Note:** This task is part of a coordinated commit with Tasks 5, 7, 8. Do NOT commit separately.

This is the core change. The file is replaced entirely. Below are the key sections with complete code.

- [x] **Step 1: Replace the full file**

Replace the entire content of `Mobile/mobile_app/lib/features/pages/fence_page.dart` with:

```dart
import 'dart:math' show min;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/api/api_role.dart';
import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/data/generators/gps_trajectory_generator.dart';
import 'package:smart_livestock_demo/core/map/map_config.dart';
import 'package:smart_livestock_demo/core/mock/mock_config.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/permissions/role_permission.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_edit_session.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_state.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_hit_detection.dart';
import 'package:smart_livestock_demo/features/fence/presentation/widgets/fence_candidate_sheet.dart';
import 'package:smart_livestock_demo/features/fence/presentation/widgets/fence_edit_toolbar.dart';
import 'package:smart_livestock_demo/features/fence/presentation/widgets/fence_mini_title_bar.dart';
import 'package:smart_livestock_demo/features/fence/presentation/widgets/fence_unsaved_dialog.dart';

class FencePage extends ConsumerStatefulWidget {
  const FencePage({super.key});

  @override
  ConsumerState<FencePage> createState() => _FencePageState();
}

class _FencePageState extends ConsumerState<FencePage>
    with TickerProviderStateMixin {
  final _mapController = MapController();
  final _trajectoryGenerator = GpsTrajectoryGenerator(seed: 42);
  final _gestureKey = GlobalKey();
  bool _panelOpen = false;

  late final AnimationController _breathingController;

  int _activePointerCount = 0;
  bool _isMultiTouch = false;
  int? _draggingVertexIndex;
  Offset? _lastTranslateOffset;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fenceState = ref.watch(fenceControllerProvider);
    final role = ref.watch(sessionControllerProvider).role!;
    final canManage = RolePermission.canEditFence(role);
    final isEditing = fenceState.editSession != null;

    if (fenceState.selectedFenceId != null && !isEditing) {
      if (!_breathingController.isAnimating) {
        _breathingController.repeat(reverse: true);
      }
    } else {
      if (_breathingController.isAnimating) {
        _breathingController.stop();
        _breathingController.value = 0;
      }
    }

    return PopScope<void>(
      canPop: !isEditing,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handlePagePop(context);
      },
      child: Scaffold(
        key: const Key('page-fence'),
        appBar: isEditing
            ? null
            : AppBar(title: const Text(MockConfig.ranchName)),
        body: _buildBody(
          context,
          fenceState,
          ref.read(fenceControllerProvider.notifier),
          canManage,
          ref.watch(appModeProvider),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    FenceState fenceState,
    FenceController controller,
    bool canManage,
    AppMode appMode,
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
        return _buildMap(
          context, fenceState, controller, canManage, appMode,
        );
    }
  }

  Widget _buildMap(
    BuildContext context,
    FenceState fenceState,
    FenceController controller,
    bool canManage,
    AppMode appMode,
  ) {
    const panelAnimDuration = Duration(milliseconds: 280);
    const panelCurve = Curves.easeOutCubic;
    final editSession = fenceState.editSession;
    final isEditing = editSession != null;
    final isSaving = fenceState.editMode == FenceEditMode.saving;
    final selectedFenceId = fenceState.selectedFenceId;

    return LayoutBuilder(
      builder: (context, constraints) {
        final panelW = min(300.0, constraints.maxWidth * 0.82);
        final mockTrajectoryPoints = appMode.isMock
            ? _buildMockTrajectoryPoints(fenceState)
            : const <LatLng>[];

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                child: Stack(
                  children: [
                    Container(
                      key: _gestureKey,
                      child: FlutterMap(
                        key: const Key('fence-map'),
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: DemoSeed.mapCenter,
                          initialZoom: DemoSeed.defaultZoom,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all,
                          ),
                          onTap: isEditing
                              ? (editSession.tool ==
                                      FenceEditTool.insertVertex
                                  ? (tapPos, _) =>
                                      _handleEditMapTapInsert(
                                        tapPos, editSession, controller,
                                      )
                                  : null)
                              : (tapPosition, point) =>
                                  _handleMapTap(
                                    tapPosition,
                                    point,
                                    fenceState,
                                    controller,
                                  ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: MapConfig.tileUrlTemplate,
                            userAgentPackageName:
                                'com.smartlivestock.demo',
                            maxZoom: MapConfig.cacheMaxZoom.toDouble(),
                          ),
                          if (!isEditing)
                            AnimatedBuilder(
                              animation: _breathingController,
                              builder: (context, _) => PolygonLayer(
                                polygons:
                                    _buildBrowsePolygons(fenceState),
                              ),
                            )
                          else
                            PolygonLayer(
                              polygons:
                                  _buildEditPolygons(editSession),
                            ),
                          if (!isEditing &&
                              editSession == null &&
                              appMode.isMock &&
                              mockTrajectoryPoints.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: mockTrajectoryPoints,
                                  color: AppColors.primary,
                                  strokeWidth: 3,
                                ),
                              ],
                            ),
                          if (!isEditing &&
                              appMode.isLive &&
                              ApiCache.instance.initialized &&
                              ApiCache.instance
                                  .mapTrajectoryPoints.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: [
                                    for (final p in ApiCache
                                        .instance.mapTrajectoryPoints)
                                      LatLng(
                                        (p['lat'] as num).toDouble(),
                                        (p['lng'] as num).toDouble(),
                                      ),
                                  ],
                                  color: AppColors.primary,
                                  strokeWidth: 3,
                                ),
                              ],
                            ),
                          if (isEditing &&
                              editSession.points.length >= 2)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: [
                                    ...editSession.points,
                                    editSession.points.first,
                                  ],
                                  color: AppColors.primary,
                                  strokeWidth: 2.5,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              if (!isEditing)
                                ..._buildLivestockMarkers(appMode),
                              if (isEditing)
                                ..._buildVertexMarkers(
                                  editSession, controller, isSaving,
                                ),
                              if (isEditing &&
                                  editSession.tool ==
                                      FenceEditTool.insertVertex)
                                ..._buildEdgeMidpointMarkers(
                                  editSession, controller, isSaving,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isEditing &&
                        !isSaving &&
                        editSession.tool == FenceEditTool.translate &&
                        editSession.points.length >= 3)
                      Positioned.fill(
                        child: ClipPath(
                          clipper:
                              _PolygonClipper(_translateHitPolygon(editSession)),
                          child: GestureDetector(
                            key: const Key(
                                'fence-edit-translate-hit-area'),
                            behavior: HitTestBehavior.opaque,
                            onPanStart: _handleTranslatePanStart,
                            onPanUpdate: _handleTranslatePanUpdate,
                            onPanEnd: (_) =>
                                _lastTranslateOffset = null,
                            onPanCancel: () =>
                                _lastTranslateOffset = null,
                            child: const ColoredBox(
                                color: Colors.transparent),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (isEditing)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: FenceMiniTitleBar(
                  fenceName: fenceState.selectedFence?.name ?? '',
                  onBack: () => _handleEditExit(context, controller),
                  onUndo: controller.undoEdit,
                  onRedo: controller.redoEdit,
                  canUndo: editSession.canUndo && !isSaving,
                  canRedo: editSession.canRedo && !isSaving,
                ),
              ),

            if (isEditing)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: FenceEditToolbar(
                  activeTool: editSession.tool,
                  onSave: () =>
                      _handleEditSave(context, controller, appMode),
                  canSave:
                      controller.canSaveSession(editSession),
                  canExit: !isSaving,
                  onExit: () =>
                      _handleEditExit(context, controller),
                  canSelectTool: !isSaving,
                  onSelectTool: controller.selectEditTool,
                ),
              ),

            if (!isEditing)
              AnimatedPositioned(
                duration: panelAnimDuration,
                curve: panelCurve,
                left: _panelOpen ? 0 : -panelW,
                top: 0,
                bottom: 0,
                width: panelW,
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black38,
                  color: Theme.of(context).colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(AppSpacing.lg),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SafeArea(
                    right: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '牧场 (${fenceState.fences.length})',
                                key: const Key('fence-drawer-title'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                              if (canManage)
                                IconButton(
                                  key: const Key('fence-add'),
                                  onPressed: () => context
                                      .push(AppRoute.fenceForm.path)
                                      .then((_) {
                                    if (appMode.isLive) {
                                      ref
                                          .read(fenceControllerProvider
                                              .notifier)
                                          .reloadFromRepository();
                                    }
                                  }),
                                  icon: const Icon(
                                      Icons.add_circle_outline),
                                  tooltip: '新建围栏',
                                ),
                            ],
                          ),
                          if (fenceState.fences.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xl,
                              ),
                              child: Center(
                                child: Text(
                                  '暂无围栏，打开菜单后点 + 创建',
                                  key: const Key('fence-empty-hint'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color:
                                            AppColors.textSecondary,
                                      ),
                                ),
                              ),
                            )
                          else
                            for (final fence in fenceState.fences)
                              _FenceCard(
                                fence: fence,
                                isSelected: fence.id ==
                                    fenceState.selectedFenceId,
                                canManage: canManage,
                                onTap: () {
                                  controller.select(fence.id);
                                  _mapController.move(
                                    _fenceCenter(fence.points),
                                    16.0,
                                  );
                                  setState(
                                      () => _panelOpen = false);
                                },
                                onEdit: () {
                                  controller.select(fence.id);
                                  controller
                                      .startEditing(fence.id);
                                  _mapController.move(
                                    _fenceCenter(fence.points),
                                    16.0,
                                  );
                                  setState(
                                      () => _panelOpen = false);
                                },
                                onDelete: () =>
                                    _showDeleteDialog(
                                  context,
                                  fence,
                                  controller,
                                  appMode,
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            if (!isEditing)
              AnimatedPositioned(
                duration: panelAnimDuration,
                curve: panelCurve,
                left: _panelOpen ? panelW + 12 : 12,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: FloatingActionButton.small(
                    key: const Key('fence-panel-toggle'),
                    heroTag: 'fence-panel-toggle',
                    onPressed: () =>
                        setState(() => _panelOpen = !_panelOpen),
                    tooltip:
                        _panelOpen ? '收起牧场列表' : '牧场列表',
                    child: Icon(_panelOpen
                        ? Icons.chevron_left
                        : Icons.menu),
                  ),
                ),
              ),

            if (!isEditing &&
                canManage &&
                fenceState.fences.isNotEmpty)
              Positioned(
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: FloatingActionButton.extended(
                  key: const Key('fence-start-edit'),
                  heroTag: 'fence-start-edit',
                  onPressed: () {
                    if (selectedFenceId == null) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('请先选择一个牧场'),
                          ),
                        );
                      return;
                    }
                    controller.startEditing(selectedFenceId);
                    setState(() => _panelOpen = false);
                  },
                  icon: const Icon(
                      Icons.edit_location_alt_outlined),
                  label: const Text('编辑边界'),
                ),
              ),
          ],
        );
      },
    );
  }

  // --- Polygon builders ---

  List<Polygon> _buildBrowsePolygons(FenceState fenceState) {
    final t = _breathingController.value;
    final hasSelection = fenceState.selectedFenceId != null;
    return fenceState.fences.map((fence) {
      final color = Color(fence.colorValue);
      final selected = fence.id == fenceState.selectedFenceId;
      if (selected) {
        return Polygon(
          points: fence.points,
          color: color.withValues(alpha: 0.3 + 0.1 * t),
          borderColor: color,
          borderStrokeWidth: 3.0 + 1.5 * t,
        );
      }
      return Polygon(
        points: fence.points,
        color: color.withValues(alpha: hasSelection ? 0.08 : 0.15),
        borderColor:
            hasSelection ? color.withValues(alpha: 0.4) : color,
        borderStrokeWidth: hasSelection ? 1.5 : 2.0,
      );
    }).toList();
  }

  List<Polygon> _buildEditPolygons(FenceEditSession editSession) {
    if (editSession.points.length < 3) return const [];
    return [
      Polygon(
        points: editSession.points,
        color: AppColors.primary.withValues(alpha: 0.22),
        borderColor: AppColors.primary,
        borderStrokeWidth: 2.5,
      ),
    ];
  }

  // --- Vertex / edge markers for edit mode ---

  List<Marker> _buildVertexMarkers(
    FenceEditSession editSession,
    FenceController controller,
    bool isSaving,
  ) {
    final isInteractive = !isSaving;
    return [
      for (var i = 0; i < editSession.points.length; i++)
        Marker(
          key: Key('fence-edit-vertex-marker-$i'),
          point: editSession.points[i],
          width: 88,
          height: 88,
          alignment: Alignment.center,
          child: GestureDetector(
            key: Key('fence-edit-vertex-$i'),
            behavior: HitTestBehavior.opaque,
            onTap: isInteractive
                ? () {
                    if (editSession.tool == FenceEditTool.deleteVertex) {
                      _handleRemoveVertex(
                        context, controller, editSession, i,
                      );
                    }
                  }
                : null,
            onPanStart: isInteractive &&
                    editSession.tool == FenceEditTool.moveVertex
                ? (_) {
                    if (_isMultiTouch) return;
                    setState(() => _draggingVertexIndex = i);
                  }
                : null,
            onPanUpdate: isInteractive &&
                    editSession.tool == FenceEditTool.moveVertex
                ? (details) {
                    if (_isMultiTouch || _draggingVertexIndex != i) {
                      return;
                    }
                    _handleVertexPanUpdate(i, details.globalPosition, controller);
                  }
                : null,
            onPanEnd: isInteractive &&
                    editSession.tool == FenceEditTool.moveVertex
                ? (_) {
                    setState(() => _draggingVertexIndex = null);
                  }
                : null,
            onPanCancel: isInteractive &&
                    editSession.tool == FenceEditTool.moveVertex
                ? () {
                    setState(() => _draggingVertexIndex = null);
                  }
                : null,
            child: Center(
              child: _VertexHandle(
                highlight:
                    editSession.tool == FenceEditTool.moveVertex ||
                        editSession.tool == FenceEditTool.deleteVertex,
              ),
            ),
          ),
        ),
    ];
  }

  List<Marker> _buildEdgeMidpointMarkers(
    FenceEditSession editSession,
    FenceController controller,
    bool isSaving,
  ) {
    return [
      for (var i = 0; i < editSession.points.length; i++)
        Marker(
          key: Key('fence-edit-edge-marker-$i'),
          point: _midPointForEdge(editSession.points, i),
          width: 28,
          height: 28,
          child: GestureDetector(
            key: Key('fence-edit-edge-$i'),
            behavior: HitTestBehavior.opaque,
            onTap: !isSaving
                ? () => controller.insertDraftVertex(
                      i,
                      _midPointForEdge(editSession.points, i),
                    )
                : null,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
          ),
        ),
    ];
  }

  // --- Multi-touch tracking ---

  void _onPointerDown(PointerDownEvent event) {
    _activePointerCount++;
    if (_activePointerCount >= 2) {
      _isMultiTouch = true;
      if (_draggingVertexIndex != null || _lastTranslateOffset != null) {
        setState(() {
          _draggingVertexIndex = null;
          _lastTranslateOffset = null;
        });
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointerCount--;
    if (_activePointerCount <= 0) {
      _activePointerCount = 0;
      _isMultiTouch = false;
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointerCount--;
    if (_activePointerCount <= 0) {
      _activePointerCount = 0;
      _isMultiTouch = false;
    }
  }

  // --- Browse mode: hit detection ---

  void _handleMapTap(
    TapPosition tapPosition,
    LatLng point,
    FenceState fenceState,
    FenceController controller,
  ) {
    final screenPoint = tapPosition.relative;
    if (screenPoint == null) return;
    final camera = _mapController.camera;

    Offset project(LatLng ll) {
      final p = camera.latLngToScreenOffset(ll);
      return Offset((p.dx as num).toDouble(), (p.dy as num).toDouble());
    }

    final hits = detectFenceHits(
      tapScreenPoint: screenPoint,
      tapLatLng: point,
      fences: fenceState.fences,
      project: project,
    );

    if (hits.isEmpty) {
      controller.select(null);
      return;
    }

    if (hits.length == 1) {
      controller.select(hits.first.fenceId);
      return;
    }

    final candidates = <FenceItem>[];
    for (final hit in hits) {
      for (final fence in fenceState.fences) {
        if (fence.id == hit.fenceId) {
          candidates.add(fence);
          break;
        }
      }
    }
    showFenceCandidateSheet(context, candidates).then((selectedId) {
      if (selectedId != null) {
        controller.select(selectedId);
      }
    });
  }

  // --- Edit mode: insert vertex via map tap ---

  void _handleEditMapTapInsert(
    TapPosition tapPosition,
    FenceEditSession editSession,
    FenceController controller,
  ) {
    final local = tapPosition.relative;
    if (local == null) return;
    final edgeHit = _findNearestEdge(local, editSession.points);
    if (edgeHit == null || edgeHit.distance > 24.0) return;
    final insertPoint = _latLngFromLocal(local);
    if (insertPoint == null) return;
    controller.insertDraftVertex(edgeHit.edgeStartIndex, insertPoint);
  }

  // --- Edit mode: vertex drag ---

  void _handleVertexPanUpdate(
    int vertexIndex,
    Offset globalPosition,
    FenceController controller,
  ) {
    final context = _gestureKey.currentContext;
    if (context == null) return;
    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox) return;
    final local = renderBox.globalToLocal(globalPosition);
    final nextPoint = _latLngFromLocal(local);
    if (nextPoint == null) return;
    controller.moveDraftVertex(vertexIndex, nextPoint);
  }

  // --- Edit mode: translate ---

  void _handleTranslatePanStart(DragStartDetails details) {
    if (_isMultiTouch) return;
    _lastTranslateOffset = details.localPosition;
  }

  void _handleTranslatePanUpdate(DragUpdateDetails details) {
    if (_isMultiTouch) {
      _lastTranslateOffset = null;
      return;
    }
    final previous = _lastTranslateOffset;
    final current = details.localPosition;
    if (previous == null) {
      _lastTranslateOffset = current;
      return;
    }
    final previousLatLng = _latLngFromLocal(previous);
    final currentLatLng = _latLngFromLocal(current);
    if (previousLatLng == null || currentLatLng == null) {
      _lastTranslateOffset = current;
      return;
    }
    ref.read(fenceControllerProvider.notifier).translateDraft(
          currentLatLng.latitude - previousLatLng.latitude,
          currentLatLng.longitude - previousLatLng.longitude,
        );
    _lastTranslateOffset = current;
  }

  // --- Coordinate helpers ---

  LatLng? _latLngFromLocal(Offset localPosition) {
    try {
      final camera = _mapController.camera;
      if (camera.size.width == 0 || camera.size.height == 0) return null;
      return camera.screenOffsetToLatLng(localPosition);
    } catch (_) {
      return null;
    }
  }

  Offset? _offsetForPoint(LatLng point) {
    try {
      final offset = _mapController.camera.latLngToScreenOffset(point);
      return Offset(
        (offset.dx as num).toDouble(),
        (offset.dy as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  _EdgeHit? _findNearestEdge(Offset localPosition, List<LatLng> points) {
    if (points.length < 2) return null;
    _EdgeHit? best;
    for (var i = 0; i < points.length; i++) {
      final start = _offsetForPoint(points[i]);
      final end = _offsetForPoint(points[(i + 1) % points.length]);
      if (start == null || end == null) continue;
      final d = distanceToSegment(localPosition, start, end);
      if (best == null || d < best.distance) {
        best = _EdgeHit(edgeStartIndex: i, distance: d);
      }
    }
    return best;
  }

  List<Offset> _translateHitPolygon(FenceEditSession editSession) {
    final offsets = <Offset>[];
    for (final point in editSession.points) {
      final offset = _offsetForPoint(point);
      if (offset == null) return const [];
      offsets.add(offset);
    }
    return offsets;
  }

  static LatLng _midPointForEdge(List<LatLng> points, int edgeStartIndex) {
    final start = points[edgeStartIndex];
    final end = points[(edgeStartIndex + 1) % points.length];
    return LatLng(
      (start.latitude + end.latitude) / 2,
      (start.longitude + end.longitude) / 2,
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

  // --- Edit flow handlers ---

  Future<void> _handleEditExit(
    BuildContext context,
    FenceController controller,
  ) async {
    final fenceState = ref.read(fenceControllerProvider);
    if (fenceState.editMode == FenceEditMode.saving) return;
    final hasChanges = fenceState.editSession?.hasChanges ?? false;
    if (!hasChanges) {
      controller.cancelEditing();
      if (mounted) setState(() => _panelOpen = true);
      return;
    }
    final action = await showFenceUnsavedDialog(context);
    if (!context.mounted || action == null) return;
    switch (action) {
      case FenceUnsavedAction.save:
        await _handleEditSave(
          context, controller, ref.read(appModeProvider),
        );
        return;
      case FenceUnsavedAction.discard:
        controller.discardEditing();
        setState(() => _panelOpen = true);
        return;
      case FenceUnsavedAction.continueEditing:
        return;
    }
  }

  Future<void> _handleEditSave(
    BuildContext context,
    FenceController controller,
    AppMode appMode,
  ) async {
    final session = ref.read(fenceControllerProvider).editSession;
    if (session == null || !session.hasChanges) return;
    final geometryError =
        FenceController.validateDraftGeometry(session.points);
    if (geometryError != null) {
      _showSnackBar(context, geometryError);
      return;
    }
    if (appMode.isMock) {
      controller.saveEditing();
      if (mounted) setState(() => _panelOpen = true);
      return;
    }
    final sessionInstanceId = session.sessionInstanceId;
    final fenceId = session.fenceId;
    controller.markSavingEdit();
    final ok = await ApiCache.instance.updateFenceRemote(
      apiRoleFromEnvironment,
      fenceId,
      {
        'coordinates': [
          for (final point in session.points)
            [point.longitude, point.latitude],
        ],
      },
    );
    if (!ok) {
      final restored =
          controller.restoreEditingAfterSaveFailureIfCurrent(
        sessionInstanceId: sessionInstanceId,
        fenceId: fenceId,
      );
      if (restored && context.mounted) {
        _showSnackBar(
          context,
          fenceSaveErrorMessageForStatusCode(
            ApiCache.instance.lastFenceSaveStatusCode,
          ),
        );
      }
      return;
    }
    final saved = controller.saveEditingIfCurrent(
      sessionInstanceId: sessionInstanceId,
      fenceId: fenceId,
    );
    if (!saved) return;
    await ApiCache.instance
        .refreshFencesAndMap(apiRoleFromEnvironment);
    controller.reloadFromRepository();
    if (context.mounted) setState(() => _panelOpen = true);
  }

  Future<void> _handlePagePop(BuildContext context) async {
    final fenceState = ref.read(fenceControllerProvider);
    final controller = ref.read(fenceControllerProvider.notifier);
    if (fenceState.editSession == null ||
        fenceState.editMode == FenceEditMode.saving) {
      return;
    }
    await _handleEditExit(context, controller);
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleRemoveVertex(
    BuildContext context,
    FenceController controller,
    FenceEditSession editSession,
    int vertexIndex,
  ) {
    if (editSession.points.length <= 3) {
      _showSnackBar(context, '边界至少保留 3 个点');
      return;
    }
    controller.removeDraftVertex(vertexIndex);
  }

  // --- Livestock markers ---

  List<Marker> _buildLivestockMarkers(AppMode appMode) {
    if (appMode.isMock) {
      return [
        for (int i = 0; i < DemoSeed.livestockLocations.length; i++)
          Marker(
            key: Key('fence-map-marker-$i'),
            point: DemoSeed.livestockLocations[i].toLatLng(),
            width: 56,
            height: 56,
            child: _MapMarker(
              label: DemoSeed
                  .earTags[i < DemoSeed.earTags.length ? i : 0],
              isAlert: i == 0,
            ),
          ),
      ];
    }
    if (!ApiCache.instance.initialized ||
        ApiCache.instance.animals.isEmpty) {
      return [
        for (int i = 0; i < DemoSeed.livestockLocations.length; i++)
          Marker(
            key: Key('fence-map-marker-fallback-$i'),
            point: DemoSeed.livestockLocations[i].toLatLng(),
            width: 56,
            height: 56,
            child: _MapMarker(
              label: DemoSeed
                  .earTags[i < DemoSeed.earTags.length ? i : 0],
              isAlert: i == 0,
            ),
          ),
      ];
    }
    final animals = ApiCache.instance.animals;
    return [
      for (var i = 0; i < animals.length; i++)
        Marker(
          key: Key('fence-map-marker-$i'),
          point: LatLng(
            (animals[i]['lat'] as num).toDouble(),
            (animals[i]['lng'] as num).toDouble(),
          ),
          width: 56,
          height: 56,
          child: _MapMarker(
            label: animals[i]['earTag'] as String? ?? '-',
            isAlert: animals[i]['boundaryStatus'] == 'outside',
          ),
        ),
    ];
  }

  List<LatLng> _buildMockTrajectoryPoints(FenceState fenceState) {
    final selectedFenceId =
        fenceState.selectedFenceId ?? 'fence_pasture_a';
    List<LatLng>? boundary;
    for (final fence in fenceState.fences) {
      if (fence.id == selectedFenceId) {
        boundary = fence.points;
        break;
      }
    }
    if (boundary == null || boundary.length < 2) return const [];
    String? earTag;
    for (final livestock in DemoSeed.livestock) {
      if (livestock.fenceId == selectedFenceId) {
        earTag = livestock.earTag;
        break;
      }
    }
    final activeEarTag = earTag ?? DemoSeed.earTags.first;
    final restFence = DemoSeed.fencePointsById('fence_rest');
    final points = _trajectoryGenerator.generate(
      earTag: activeEarTag,
      fenceBoundary: boundary,
      restFenceBoundary: restFence.isEmpty ? null : restFence,
      anchorPoints: DemoSeed.gpsAnchorPoints,
      start: DateTime.utc(2026, 4, 7, 10),
      end: DateTime.utc(2026, 4, 8, 10),
    );
    return points.map((p) => p.toLatLng()).toList();
  }

  // --- Delete dialog ---

  void _showDeleteDialog(
    BuildContext context,
    FenceItem fence,
    FenceController controller,
    AppMode appMode,
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
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (appMode.isLive) {
                final ok = await ApiCache.instance.deleteFenceRemote(
                    apiRoleFromEnvironment, fence.id);
                if (!context.mounted) return;
                if (ok) {
                  await ApiCache.instance
                      .refreshFencesAndMap(apiRoleFromEnvironment);
                  if (!context.mounted) return;
                  controller.reloadFromRepository();
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                          content: Text('已删除「${fence.name}」')),
                    );
                } else {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                          content: Text('删除失败，请稍后重试')),
                    );
                }
              } else {
                controller.delete(fence.id);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text('已删除「${fence.name}」')),
                  );
              }
            },
            child: const Text('删除',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// --- Private helper widgets ---

class _VertexHandle extends StatelessWidget {
  const _VertexHandle({required this.highlight});

  static const double _outerDiameter = 44;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final outerColor = highlight ? AppColors.primary : Colors.white;
    const borderColor = AppColors.primary;
    final innerColor = highlight ? Colors.white : AppColors.primary;

    return SizedBox(
      width: _outerDiameter,
      height: _outerDiameter,
      child: Container(
        decoration: BoxDecoration(
          color: outerColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4),
          ],
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: innerColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _EdgeHit {
  const _EdgeHit({required this.edgeStartIndex, required this.distance});
  final int edgeStartIndex;
  final double distance;
}

class _PolygonClipper extends CustomClipper<ui.Path> {
  const _PolygonClipper(this.points);
  final List<Offset> points;

  @override
  ui.Path getClip(Size size) {
    final path = ui.Path();
    if (points.length < 3) return path;
    path.addPolygon(points, true);
    return path;
  }

  @override
  bool shouldReclip(covariant _PolygonClipper oldClipper) {
    if (oldClipper.points.length != points.length) return true;
    for (var i = 0; i < points.length; i++) {
      if (oldClipper.points[i] != points[i]) return true;
    }
    return false;
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
                      style:
                          Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _StatusLabel(active: fence.active),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${fence.livestockCount}头',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
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
                  icon:
                      const Icon(Icons.edit_outlined, size: 20),
                  tooltip: '编辑',
                ),
                IconButton(
                  key: Key('fence-delete-${fence.id}'),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      size: 20),
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.textSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        active ? '启用' : '停用',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: active
                  ? AppColors.success
                  : AppColors.textSecondary,
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
            child: const Icon(Icons.pets,
                color: Colors.white, size: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 4, vertical: 1),
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
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(
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

- [x] **Step 2: Verify the file compiles (will run after test updates)**

---

## Task 7: Delete `fence_edit_overlay.dart`

**Files:**
- Delete: `lib/features/fence/presentation/widgets/fence_edit_overlay.dart`

> **Note:** Part of coordinated commit with Tasks 5, 6, 8.

- [x] **Step 1: Delete the file**

```bash
cd Mobile/mobile_app
rm lib/features/fence/presentation/widgets/fence_edit_overlay.dart
```

---

## Task 8: Update All Test Files

**Files:**
- Rewrite: `test/features/fence/fence_edit_overlay_test.dart` → `test/features/fence/fence_edit_ui_test.dart`
- Modify: `test/features/fence/fence_map_tap_highlight_test.dart`
- Modify: `test/features/fence/fence_page_mode_switch_test.dart`

> **Note:** Part of coordinated commit with Tasks 5, 6, 7.

- [x] **Step 1: Delete old overlay test and create new edit UI test**

Delete `Mobile/mobile_app/test/features/fence/fence_edit_overlay_test.dart`.

Create `Mobile/mobile_app/test/features/fence/fence_edit_ui_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';

void main() {
  testWidgets('进入编辑态后显示迷你标题条与工具栏', (tester) async {
    await _openFencePage(tester);
    await _selectFenceA(tester);

    await tester.tap(find.byKey(const Key('fence-start-edit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fence-edit-mini-title')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-toolbar')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-save')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-tool-move')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-tool-insert')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-tool-delete')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-tool-translate')), findsOneWidget);
  });

  testWidgets('迷你标题条显示围栏名称', (tester) async {
    await _openFencePage(tester);
    await _selectFenceA(tester);

    await tester.tap(find.byKey(const Key('fence-start-edit')));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('page-fence'))),
    );
    final fenceName =
        container.read(fenceControllerProvider).selectedFence!.name;
    expect(find.text('编辑围栏：$fenceName'), findsOneWidget);
  });

  testWidgets('撤销/重做按钮初始禁用', (tester) async {
    await _openFencePage(tester);
    await _selectFenceA(tester);

    await tester.tap(find.byKey(const Key('fence-start-edit')));
    await tester.pumpAndSettle();

    final IconButton undoButton = tester.widget<IconButton>(
      find.byKey(const Key('fence-edit-undo')),
    );
    final IconButton redoButton = tester.widget<IconButton>(
      find.byKey(const Key('fence-edit-redo')),
    );
    expect(undoButton.onPressed, isNull);
    expect(redoButton.onPressed, isNull);
  });

  testWidgets('编辑态地图可见且无固体背景遮盖', (tester) async {
    await _openFencePage(tester);
    await _selectFenceA(tester);

    await tester.tap(find.byKey(const Key('fence-start-edit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fence-map')), findsOneWidget);
  });
}

Future<void> _openFencePage(WidgetTester tester) async {
  await tester.pumpWidget(const DemoApp());
  await tester.tap(find.byKey(const Key('role-owner')));
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav-fence')));
  await tester.pumpAndSettle();
}

Future<void> _selectFenceA(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('fence-panel-toggle')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('fence-card-fence_pasture_a')));
  await tester.pump(const Duration(milliseconds: 100));
}
```

- [x] **Step 2: Update fence_map_tap_highlight_test.dart**

Replace the full content of `Mobile/mobile_app/test/features/fence/fence_map_tap_highlight_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';

void main() {
  testWidgets('选中围栏后呼吸动画高亮样式与非选中围栏有明显视觉差异', (tester) async {
    await _openFencePage(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('page-fence'))),
    );
    container.read(fenceControllerProvider.notifier).select('fence_pasture_a');
    await tester.pump(const Duration(milliseconds: 750));

    final polygonLayer =
        tester.widget<PolygonLayer>(find.byType(PolygonLayer));
    final fences = container.read(fenceControllerProvider).fences;
    final selectedFence =
        fences.firstWhere((f) => f.id == 'fence_pasture_a');
    final selectedPolygon = polygonLayer.polygons.firstWhere(
      (p) => p.points == selectedFence.points,
    );
    final otherPolygons = polygonLayer.polygons.where(
      (p) => p.points != selectedFence.points,
    );

    expect(selectedPolygon.color!.a, closeTo(0.35, 0.06));
    expect(selectedPolygon.borderStrokeWidth,
        closeTo(3.75, 0.76));
    for (final p in otherPolygons) {
      expect(p.color!.a, closeTo(0.08, 0.03));
      expect(p.borderStrokeWidth, 1.5);
    }
  });

  testWidgets('切换选中围栏后前一个围栏恢复正常显示', (tester) async {
    await _openFencePage(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('page-fence'))),
    );
    final controller = container.read(fenceControllerProvider.notifier);

    controller.select('fence_pasture_a');
    await tester.pump(const Duration(milliseconds: 750));
    controller.select('fence_pasture_b');
    await tester.pump(const Duration(milliseconds: 750));

    final state = container.read(fenceControllerProvider);
    expect(state.selectedFenceId, 'fence_pasture_b');

    final polygonLayer =
        tester.widget<PolygonLayer>(find.byType(PolygonLayer));
    final fenceA =
        state.fences.firstWhere((f) => f.id == 'fence_pasture_a');
    final polygonA = polygonLayer.polygons.firstWhere(
      (p) => p.points == fenceA.points,
    );
    expect(polygonA.color!.a, closeTo(0.08, 0.03));
    expect(polygonA.borderStrokeWidth, 1.5);
  });

  testWidgets('无选中围栏时默认透明度为 0.15', (tester) async {
    await _openFencePage(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('page-fence'))),
    );
    container.read(fenceControllerProvider.notifier).select(null);
    await tester.pump();

    final polygonLayer =
        tester.widget<PolygonLayer>(find.byType(PolygonLayer));
    for (final p in polygonLayer.polygons) {
      expect(p.color!.a, closeTo(0.15, 0.03));
      expect(p.borderStrokeWidth, 2.0);
    }
  });
}

Future<void> _openFencePage(WidgetTester tester) async {
  await tester.pumpWidget(const DemoApp());
  await tester.tap(find.byKey(const Key('role-owner')));
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav-fence')));
  await tester.pumpAndSettle();
}
```

Key changes:
- Removed the third test that used `onMapTap` directly (hit detection uses screen-space + geo-space dual check, not testable via `onTap` callback with fake LatLng)
- Updated alpha values: selected at 750ms ≈ `0.35±0.06` (animation midpoint), unselected `0.08±0.03`, default `0.15±0.03`
- Updated border widths: selected at 750ms ≈ `3.75±0.76`, unselected `1.5`, default `2.0`
- **Breathing animation fix**: `select()` triggers infinite `AnimationController.repeat(reverse: true)`; `pumpAndSettle()` would timeout. All fence-selection tests use `pump(Duration(milliseconds: 750))` to advance animation to midpoint (value ≈ 0.5) then assert. `select(null)` stops the animation so `pump()` suffices.
- `_openFencePage` keeps `pumpAndSettle()` because no fence is selected during login/navigation (animation not running)

- [x] **Step 3: Update fence_page_mode_switch_test.dart**

In `Mobile/mobile_app/test/features/fence/fence_page_mode_switch_test.dart`, replace all occurrences of `fence-edit-overlay` key with `fence-edit-mini-title`:

Replace: `find.byKey(const Key('fence-edit-overlay'))`
With: `find.byKey(const Key('fence-edit-mini-title'))`

This applies to the following tests:
- Line 29: `'未选中围栏时点击编辑边界显示提示且不进入编辑态'`
- Line 39: `'侧栏编辑按钮直接进入边界编辑'`
- Line 49: `'进入编辑全屏后可直接退出并恢复浏览列表'` (2 occurrences)
- Line 56: same test
- Line 86: `'有未保存改动时退出弹出三选确认且遮罩不能关闭并可继续编辑'`
- Line 129: `'有未保存改动时可放弃更改并退出编辑态且点位保持原值'`
- Line 157: `'有未保存改动时可保存并退出编辑态且点位写回围栏'`
- Line 183: `'保存中退出按钮禁用且不会退出编辑态'`
- Line 204: `'系统返回会触发与退出一致的未保存三选确认'`
- Line 233: `'非法几何时保存按钮禁用且通过退出保存会被拦截并提示'`

Also update `_selectFenceA` helper — tapping a fence card triggers `controller.select()` which starts the breathing animation; `pumpAndSettle()` would timeout on the infinite animation. Change to `pump(Duration)`:

```dart
Future<void> _selectFenceA(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('fence-panel-toggle')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('fence-card-fence_pasture_a')));
  await tester.pump(const Duration(milliseconds: 100));
}
```

The `_insertEdgePoint` helper remains unchanged (edit mode stops the animation, so `pumpAndSettle` is safe):

```dart
Future<void> _insertEdgePoint(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('fence-edit-tool-insert')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('fence-edit-edge-0')));
  await tester.pumpAndSettle();
}
```

- [x] **Step 4: Run all tests**

Run: `cd Mobile/mobile_app && flutter test`
Expected: All tests PASS.

- [x] **Step 5: Run analyze**

Run: `cd Mobile/mobile_app && flutter analyze`
Expected: No new warnings.

- [x] **Step 6: Commit the coordinated change**

```bash
cd Mobile/mobile_app
git add -A
git commit -m "feat(fence): rewrite fence page to single-map architecture

- Unified FlutterMap instance for browse and edit modes
- Breathing animation for selected fence (alpha 0.3↔0.4, width 3.0↔4.5)
- Screen-space hit detection with 40px boundary tolerance
- Overlapping fence candidate BottomSheet
- Mini title bar with fence name + undo/redo in edit mode
- Multi-touch Listener for pinch-zoom during edit operations
- Removed FenceEditOverlay and dual MapController"
```

---

## Task 9: Final Verification

- [x] **Step 1: Run full analysis**

Run: `cd Mobile/mobile_app && flutter analyze`
Expected: No warnings.

- [x] **Step 2: Run full test suite**

Run: `cd Mobile/mobile_app && flutter test`
Expected: All tests pass.

- [x] **Step 3: Verify against acceptance criteria**

| # | Criterion | How to verify |
|---|-----------|---------------|
| 1 | 浏览态 40px 内选中 + 呼吸动画 | `fence_hit_detection_test.dart` + `fence_map_tap_highlight_test.dart` |
| 2 | 重叠围栏候选列表 | `fence_candidate_sheet.dart` exists + manual test |
| 3 | 编辑态地图可见 | `fence_edit_ui_test.dart`: `fence-map` key found in edit mode |
| 4 | 编辑态双指缩放 | `Listener` multi-touch tracking + `InteractiveFlag.all` |
| 5 | 多指中断操作 | `_onPointerDown` clears `_draggingVertexIndex` + `_lastTranslateOffset` |
| 6 | 迷你标题条 | `fence_edit_ui_test.dart`: title bar with fence name + undo/redo |
| 7 | `flutter analyze` 无新增警告 | Step 1 |
| 8 | `flutter test` 全部通过 | Step 2 |
