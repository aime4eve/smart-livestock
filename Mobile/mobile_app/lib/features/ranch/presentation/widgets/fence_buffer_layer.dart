import 'dart:math' show cos, max, min, sqrt;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/core/map/coord_transform.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';

/// 50m 预警缓冲带（围栏边界【外侧】环带，NIX-412）。
///
/// 渲染=带洞多边形：外环=围栏顶点外扩 50m（角平分线法），洞=围栏本体——
/// 即使外扩环在凹角处局部自交，围栏内部恒被洞遮挡，可见部分只剩围栏外
/// 50m 环带（2026-11-13 集成测试反馈：无挖洞时外扩碎片翻进围栏内部，
/// 视觉上"缓冲带在围栏里"）。
class FenceBufferLayer extends StatelessWidget {
  const FenceBufferLayer({
    super.key,
    required this.fences,
    this.bufferDistance = 50,
    this.shouldTransform = false,
  });

  final List<RanchFenceData> fences;
  final int bufferDistance;
  final bool shouldTransform;

  @override
  Widget build(BuildContext context) {
    final polygons = <Polygon>[];

    for (final fence in fences) {
      if (!fence.active || fence.points.isEmpty) continue;

      final fenceScreen = shouldTransform
          ? CoordTransform.wgs84ToGcj02All(fence.points)
          : fence.points;

      final outer = _offsetRing(fence.points, bufferDistance.toDouble());
      if (outer.isEmpty) continue;
      final outerScreen =
          shouldTransform ? CoordTransform.wgs84ToGcj02All(outer) : outer;

      polygons.add(Polygon(
        points: outerScreen,
        holePointsList: [fenceScreen],
        color: Colors.orange.withValues(alpha: 0.15),
        borderColor: Colors.orange.withValues(alpha: 0.5),
        borderStrokeWidth: 1.5,
        pattern: StrokePattern.dashed(segments: const [8, 6]),
      ));
    }

    if (polygons.isEmpty) return const SizedBox.shrink();

    return PolygonLayer(polygons: polygons);
  }

  /// 顶点环沿角平分线法线向外偏移 [meters]（米制角平分线法，锐角补偿+
  /// 安全上限防尖角飞点）。注意：法线计算全程在米制平面进行（先把边向
  /// 量换算成米再归一）——旧版把单位法线再除以 111320 导致量纲错误，
  /// scale 恒触发 clamp、实际偏移变成 8~200 米乱值。
  List<LatLng> _offsetRing(List<LatLng> points, double meters) {
    if (points.length < 3) return [];
    final lat0 = points.first.latitude;
    const mPerLat = 111320.0;
    final mPerLng = 111320.0 * cos(lat0 * pi / 180);

    final buffer = <LatLng>[];
    final n = points.length;
    for (int i = 0; i < n; i++) {
      final prev = points[(i - 1 + n) % n];
      final curr = points[i];
      final next = points[(i + 1) % n];

      // 两邻边（米制）。
      final e1x = (curr.longitude - prev.longitude) * mPerLng;
      final e1y = (curr.latitude - prev.latitude) * mPerLat;
      final e2x = (next.longitude - curr.longitude) * mPerLng;
      final e2y = (next.latitude - curr.latitude) * mPerLat;
      final l1 = sqrt(e1x * e1x + e1y * e1y);
      final l2 = sqrt(e2x * e2x + e2y * e2y);
      if (l1 < 1e-9 || l2 < 1e-9) {
        buffer.add(curr);
        continue;
      }
      // 边单位向量 → 左法线（米制单位向量）。
      final n1x = -e1y / l1;
      final n1y = e1x / l1;
      final n2x = -e2y / l2;
      final n2y = e2x / l2;

      // 角平分线单位向量。
      var bx = n1x + n2x;
      var by = n1y + n2y;
      final bl = sqrt(bx * bx + by * by);
      if (bl < 1e-9) {
        buffer.add(curr);
        continue;
      }
      bx /= bl;
      by /= bl;

      // 转角正弦（邻边单位向量叉积）→ 外扩沿平分线的距离补偿（保持到
      // 两条边的垂直距离都 = meters）；安全上限防尖角飞点。
      final sinHalf = (n1x * n2y - n1y * n2x).abs();
      var offset = meters / max(sinHalf, 0.5);
      offset = min(offset, meters.abs() * 2.5);

      buffer.add(LatLng(
        curr.latitude + by * offset / mPerLat,
        curr.longitude + bx * offset / mPerLng,
      ));
    }
    return buffer;
  }
}
