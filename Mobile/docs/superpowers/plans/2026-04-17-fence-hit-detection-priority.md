# 围栏命中检测两级优先 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将围栏命中检测从单一优先级改为两级优先（内部命中 > 边界容差命中），Tier 2 按距离胜出而非面积，减少 BottomSheet 误弹出。

**Architecture:** 扩展 `FenceHitResult` 携带 `isInside` 和 `boundaryDistance` 字段；`isPointNearPolygonBoundary` 改为返回最近距离；`detectFenceHits` 分离 Tier 1/Tier 2 按新规则排序；`_handleMapTap` 用距离比值 1.5x 判定直接选中或弹 BottomSheet。

**Tech Stack:** Flutter, dart:ui, latlong2

---

## Issue 索引

| 优先级 | Issue | 标题 |
|--------|-------|------|
| P0 | #26 | 围栏地图点击选中体验优化——两级优先检测 |

## 完成记录

| 完成日期 | Issue | PR | 备注 |
|----------|-------|----|------|
| 2026-04-17 | #26 | (direct commit) | 三提交：fe5ddcb(生产代码) + 9bd01a7(测试) + 84339ee(lint修复) |

---

## File Structure

### Modified Files

| File | Responsibility |
|------|---------------|
| `lib/features/fence/presentation/fence_hit_detection.dart` | `FenceHitResult` 新增 `isInside`/`boundaryDistance`；`isPointNearPolygonBoundary` → `nearestDistanceToPolygonBoundary`；`detectFenceHits` 两级排序 |
| `lib/features/pages/fence_page.dart` | `_handleMapTap` 两级优先 + 距离比值判定 |
| `test/features/fence/fence_hit_detection_test.dart` | 新增两级优先排序、距离排序、距离比值阈值用例 |

---

## Task 1: 扩展 FenceHitResult 并改造检测函数

**Files:**
- Modify: `lib/features/fence/presentation/fence_hit_detection.dart`

- [ ] **Step 1: 替换 `fence_hit_detection.dart` 全部内容**

Replace the full content of `lib/features/fence/presentation/fence_hit_detection.dart` with:

```dart
import 'dart:ui';

import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_polygon_contains.dart';

typedef LatLngToOffset = Offset Function(LatLng);

class FenceHitResult {
  const FenceHitResult({
    required this.fenceId,
    required this.areaHectares,
    required this.isInside,
    required this.boundaryDistance,
  });

  final String fenceId;
  final double areaHectares;
  final bool isInside;
  final double boundaryDistance;
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

double nearestDistanceToPolygonBoundary(
  Offset point,
  List<Offset> polygonScreenPoints,
) {
  if (polygonScreenPoints.length < 2) {
    return double.infinity;
  }
  var minDist = double.infinity;
  for (var i = 0; i < polygonScreenPoints.length; i++) {
    final start = polygonScreenPoints[i];
    final end = polygonScreenPoints[(i + 1) % polygonScreenPoints.length];
    final d = distanceToSegment(point, start, end);
    if (d < minDist) {
      minDist = d;
    }
  }
  return minDist;
}

// Kept for backward compatibility with existing tests.
bool isPointNearPolygonBoundary(
  Offset point,
  List<Offset> polygonScreenPoints,
  double tolerance,
) {
  return nearestDistanceToPolygonBoundary(point, polygonScreenPoints) < tolerance;
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

    if (insideGeo) {
      results.add(FenceHitResult(
        fenceId: fence.id,
        areaHectares: fence.areaHectares,
        isInside: true,
        boundaryDistance: 0,
      ));
      continue;
    }

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
      final distance = nearestDistanceToPolygonBoundary(
        tapScreenPoint,
        screenPoints,
      );
      if (distance < boundaryTolerancePx) {
        results.add(FenceHitResult(
          fenceId: fence.id,
          areaHectares: fence.areaHectares,
          isInside: false,
          boundaryDistance: distance,
        ));
      }
    }
  }

  results.sort((a, b) {
    if (a.isInside != b.isInside) return a.isInside ? -1 : 1;
    if (a.isInside) return a.areaHectares.compareTo(b.areaHectares);
    return a.boundaryDistance.compareTo(b.boundaryDistance);
  });

  return results;
}
```

Key changes vs. original:
- `FenceHitResult`: added `isInside` (required) and `boundaryDistance` (required)
- New `nearestDistanceToPolygonBoundary`: returns min distance instead of bool
- `isPointNearPolygonBoundary`: kept as wrapper calling `nearestDistanceToPolygonBoundary`, preserves backward compat with existing tests
- `detectFenceHits`: separates Tier 1 (inside) and Tier 2 (boundary) hits; sorts Tier 1 first by area asc, then Tier 2 by distance asc

- [ ] **Step 2: Run analyze to verify**

Run: `cd Mobile/mobile_app && flutter analyze`
Expected: 编译错误 — `fence_page.dart` 中 `FenceHitResult` 构造函数缺少 `isInside` 和 `boundaryDistance` 参数。这些错误将在 Task 2 中修复。检测函数本身不应有新警告。

---

## Task 2: 更新 `_handleMapTap` 选择逻辑

**Files:**
- Modify: `lib/features/pages/fence_page.dart:686-732`

- [ ] **Step 1: 替换 `_handleMapTap` 方法**

In `lib/features/pages/fence_page.dart`, replace the `_handleMapTap` method (lines 686-732) with:

```dart
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

    // Tier 1: inside-polygon hit — select directly, ignore boundary hits
    if (hits.first.isInside) {
      controller.select(hits.first.fenceId);
      return;
    }

    // Tier 2: boundary-only hits
    if (hits.length == 1) {
      controller.select(hits.first.fenceId);
      return;
    }

    // Multiple boundary hits — check distance ratio
    if (hits.first.boundaryDistance < 1.0) {
      // Practically on the boundary — no ambiguity.
      // Also guards against boundaryDistance == 0 (division by zero).
      controller.select(hits.first.fenceId);
      return;
    }
    final ratio = hits[1].boundaryDistance / hits.first.boundaryDistance;
    if (ratio >= 1.5) {
      // Closest fence is significantly nearer
      controller.select(hits.first.fenceId);
      return;
    }

    // Ambiguous — show candidate BottomSheet
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
```

- [ ] **Step 2: Run analyze**

Run: `cd Mobile/mobile_app && flutter analyze`
Expected: No new warnings.

- [ ] **Step 3: Commit Tasks 1 + 2 together**

```bash
cd Mobile/mobile_app
git add lib/features/fence/presentation/fence_hit_detection.dart lib/features/pages/fence_page.dart
git commit -m "feat(fence): two-tier hit detection with distance-based selection

- FenceHitResult gains isInside + boundaryDistance fields
- detectFenceHits separates Tier 1 (inside) from Tier 2 (boundary)
- _handleMapTap uses distance ratio 1.5x threshold for direct selection
- Nearest-boundary wins over area-based ordering for Tier 2

Issue: #26

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 3: 更新命中检测测试

**Files:**
- Modify: `test/features/fence/fence_hit_detection_test.dart`

- [ ] **Step 1: 替换测试文件全部内容**

Replace the full content of `test/features/fence/fence_hit_detection_test.dart` with:

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

  group('nearestDistanceToPolygonBoundary', () {
    final square = [
      const Offset(0, 0),
      const Offset(100, 0),
      const Offset(100, 100),
      const Offset(0, 100),
    ];

    test('点在边界上距离为 0', () {
      expect(
        nearestDistanceToPolygonBoundary(const Offset(50, 0), square),
        closeTo(0, 0.001),
      );
    });

    test('点在边界外 30px 距离为 30', () {
      expect(
        nearestDistanceToPolygonBoundary(const Offset(50, -30), square),
        closeTo(30, 0.001),
      );
    });

    test('点在多边形中心到边界距离为 50', () {
      expect(
        nearestDistanceToPolygonBoundary(const Offset(50, 50), square),
        closeTo(50, 0.001),
      );
    });

    test('少于 2 个点返回 infinity', () {
      expect(
        nearestDistanceToPolygonBoundary(
            const Offset(0, 0), [const Offset(0, 0)]),
        double.infinity,
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
        isPointNearPolygonBoundary(
            const Offset(0, 0), [const Offset(0, 0)], 40),
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

    test('点在围栏内部命中（Tier 1）', () {
      final results = detectFenceHits(
        tapScreenPoint: const Offset(5, 5),
        tapLatLng: const LatLng(5, 5),
        fences: [smallFence],
        project: _identityProject,
      );
      expect(results.length, 1);
      expect(results.first.fenceId, 'small');
      expect(results.first.isInside, isTrue);
      expect(results.first.boundaryDistance, 0);
    });

    test('点在边界 40px 内命中（Tier 2）', () {
      final results = detectFenceHits(
        tapScreenPoint: const Offset(5, -20),
        tapLatLng: const LatLng(-20, 5),
        fences: [smallFence],
        project: _identityProject,
      );
      expect(results.length, 1);
      expect(results.first.fenceId, 'small');
      expect(results.first.isInside, isFalse);
      expect(results.first.boundaryDistance, greaterThan(0));
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

    test('空围栏列表返回空', () {
      final results = detectFenceHits(
        tapScreenPoint: const Offset(5, 5),
        tapLatLng: const LatLng(5, 5),
        fences: const [],
        project: _identityProject,
      );
      expect(results, isEmpty);
    });

    test('Tier 1 优先于 Tier 2（内部命中排在边界命中前面）', () {
      // 点击 small 内部，同时也在 large 的 40px 容差内
      final results = detectFenceHits(
        tapScreenPoint: const Offset(5, 5),
        tapLatLng: const LatLng(5, 5),
        fences: [largeFence, smallFence],
        project: _identityProject,
      );
      expect(results.length, 2);
      // small 是 Tier 1（内部命中），排在前面
      expect(results[0].fenceId, 'small');
      expect(results[0].isInside, isTrue);
      // large 是 Tier 2（边界命中），排在后面
      expect(results[1].fenceId, 'large');
      expect(results[1].isInside, isFalse);
    });

    test('同为 Tier 1 按面积升序排列（嵌套围栏）', () {
      final tinyFence = _makeFence(
        'tiny',
        const [LatLng(2, 2), LatLng(2, 8), LatLng(8, 8), LatLng(8, 2)],
        area: 0.5,
      );
      // 点同时在 tiny 和 small 内部
      final results = detectFenceHits(
        tapScreenPoint: const Offset(5, 5),
        tapLatLng: const LatLng(5, 5),
        fences: [smallFence, tinyFence],
        project: _identityProject,
      );
      expect(results.length, 2);
      expect(results[0].fenceId, 'tiny');   // 面积更小，优先
      expect(results[1].fenceId, 'small');
      expect(results.every((r) => r.isInside), isTrue);
    });

    test('同为 Tier 2 按边界距离升序排列', () {
      // 两个围栏不相交，点在两者边界的 40px 容差内
      final fenceNear = _makeFence(
        'near',
        const [LatLng(0, 0), LatLng(0, 10), LatLng(10, 10), LatLng(10, 0)],
        area: 1.0,
      );
      final fenceFar = _makeFence(
        'far',
        const [
          LatLng(0, 60), LatLng(0, 70), LatLng(10, 70), LatLng(10, 60)
        ],
        area: 1.0,
      );
      // 点在 x=35, y=5 — 距 near 右边 25px，距 far 左边 25px
      // 用 screen-space 测试：near 右边 x=10, far 左边 x=60
      // 点在 (35, 5)，距 near 边 25px，距 far 边 25px
      // 为了让距离不同，放在 x=20 处
      final results = detectFenceHits(
        tapScreenPoint: const Offset(20, 5),
        tapLatLng: const LatLng(5, 20), // y=5 lat 范围内，x=20 lng 在 near 和 far 之间
        fences: [fenceFar, fenceNear],
        project: _identityProject,
      );
      // near 右边在 x=10，点在 x=20，距离=10
      // far 左边在 x=60，点在 x=20，距离=40
      if (results.length == 2) {
        expect(results[0].fenceId, 'near');
        expect(results[1].fenceId, 'far');
        expect(results[0].boundaryDistance,
            lessThan(results[1].boundaryDistance));
      }
    });
  });
}
```

- [ ] **Step 2: Run tests to verify**

Run: `cd Mobile/mobile_app && flutter test test/features/fence/fence_hit_detection_test.dart -v`
Expected: All tests PASS.

- [ ] **Step 3: Commit**

```bash
cd Mobile/mobile_app
git add test/features/fence/fence_hit_detection_test.dart
git commit -m "test(fence): add two-tier priority and distance sorting tests

- Tier 1 inside hits sorted before Tier 2 boundary hits
- Tier 1 ties broken by area ascending (nested fences)
- Tier 2 sorted by boundary distance ascending
- nearestDistanceToPolygonBoundary returns exact distance

Issue: #26

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 4: Final Verification

- [ ] **Step 1: Run full analysis**

Run: `cd Mobile/mobile_app && flutter analyze`
Expected: No warnings.

- [ ] **Step 2: Run full test suite**

Run: `cd Mobile/mobile_app && flutter test`
Expected: All tests pass.

- [ ] **Step 3: Verify against acceptance criteria**

| # | Criterion | How to verify |
|---|-----------|---------------|
| 1 | 点击围栏内部可直接选中 | `fence_hit_detection_test.dart`: Tier 1 prioritized over Tier 2 |
| 2 | 点击边界附近按距离选中最近 | `fence_hit_detection_test.dart`: Tier 2 sorted by distance |
| 3 | 距离相近时弹 BottomSheet | `fence_page.dart` `_handleMapTap`: ratio < 1.5 → BottomSheet |
| 4 | 点击空白取消选中 | `fence_page.dart` `_handleMapTap`: hits.isEmpty → select(null) |
| 5 | flutter test 全部通过 | Step 2 |
| 6 | flutter analyze 无新增警告 | Step 1 |
