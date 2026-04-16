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
