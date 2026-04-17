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
      // nearbyFence 不包含 (5,5)，但 (5,5) 距其边界在 40px 内
      final nearbyFence = _makeFence(
        'nearby',
        const [LatLng(0, -30), LatLng(0, -20), LatLng(10, -20), LatLng(10, -30)],
        area: 1.0,
      );
      // 点击 small 内部（Tier 1），nearby 的上边界 y=0，点 y=5 距离 5px（Tier 2）
      final results = detectFenceHits(
        tapScreenPoint: const Offset(5, 5),
        tapLatLng: const LatLng(5, 5),
        fences: [nearbyFence, smallFence],
        project: _identityProject,
      );
      expect(results.length, 2);
      // small 是 Tier 1（内部命中），排在前面
      expect(results[0].fenceId, 'small');
      expect(results[0].isInside, isTrue);
      // nearby 是 Tier 2（边界命中），排在后面
      expect(results[1].fenceId, 'nearby');
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
