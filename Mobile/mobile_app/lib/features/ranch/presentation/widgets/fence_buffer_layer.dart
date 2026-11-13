import 'dart:math' show cos, sqrt;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/core/map/coord_transform.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';

/// Degree offset per meter at given latitude.
double _degPerMeterLat(int meters) => meters / 111000.0;
double _degPerMeterLng(int meters, double latRad) => meters / (111000.0 * cos(latRad));

const _pi = 3.141592653589793;

/// Renders fence buffer zones as semi-transparent orange polygons
/// with dashed borders on the map.
///
/// MVP approximation: offsets fence vertices by [bufferDistance] meters
/// using latitude-corrected degree offsets.
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

      // 预警带画在围栏【内侧】（牲畜在栏内活动，接近边界 50m 时进入预警
      // 带——集成测试反馈 2026-11-13：外扩版语义反了）。实现=带洞多边形：
      // 外环=围栏顶点，洞=内缩 ring；内缩退化时回退外扩（原行为）。
      final inner = _computeBuffer(fence.points, -bufferDistance);
      final fenceScreen = shouldTransform
          ? CoordTransform.wgs84ToGcj02All(fence.points)
          : fence.points;

      if (inner.length >= 3) {
        final innerScreen =
            shouldTransform ? CoordTransform.wgs84ToGcj02All(inner) : inner;
        polygons.add(Polygon(
          points: fenceScreen,
          holePointsList: [innerScreen],
          color: Colors.orange.withValues(alpha: 0.1),
          borderColor: Colors.orange.withValues(alpha: 0.5),
          borderStrokeWidth: 1.5,
          pattern: StrokePattern.dashed(segments: const [8, 6]),
        ));
        continue;
      }

      final rawBuffer = _computeBuffer(fence.points, bufferDistance);
      if (rawBuffer.isEmpty) continue;
      final bufferPoints =
          shouldTransform ? CoordTransform.wgs84ToGcj02All(rawBuffer) : rawBuffer;
      polygons.add(Polygon(
        points: bufferPoints,
        color: Colors.orange.withValues(alpha: 0.1),
        borderColor: Colors.orange.withValues(alpha: 0.5),
        borderStrokeWidth: 1.5,
        pattern: StrokePattern.dashed(segments: const [8, 6]),
      ));
    }

    if (polygons.isEmpty) return const SizedBox.shrink();

    return PolygonLayer(polygons: polygons);
  }

  List<LatLng> _computeBuffer(List<LatLng> points, int meters) {
    if (points.length < 3) return [];

    final avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final latOff = _degPerMeterLat(meters);
    final lngOff = _degPerMeterLng(meters, avgLat * _pi / 180);

    final buffer = <LatLng>[];
    final n = points.length;

    for (int i = 0; i < n; i++) {
      final prev = points[(i - 1 + n) % n];
      final curr = points[i];
      final next = points[(i + 1) % n];

      final dx1 = curr.longitude - prev.longitude;
      final dy1 = curr.latitude - prev.latitude;
      final dx2 = next.longitude - curr.longitude;
      final dy2 = next.latitude - curr.latitude;

      final nx1 = -dy1 / latOff;
      final ny1 = dx1 / lngOff;
      final len1 = sqrt(nx1 * nx1 + ny1 * ny1);

      final nx2 = -dy2 / latOff;
      final ny2 = dx2 / lngOff;
      final len2 = sqrt(nx2 * nx2 + ny2 * ny2);

      if (len1 < 1e-10 || len2 < 1e-10) {
        buffer.add(curr);
        continue;
      }

      final avgNx = (nx1 / len1 + nx2 / len2) / 2;
      final avgNy = (ny1 / len1 + ny2 / len2) / 2;
      final avgLen = sqrt(avgNx * avgNx + avgNy * avgNy);

      if (avgLen < 1e-10) {
        buffer.add(curr);
        continue;
      }

      var scale = meters / avgLen;
      // 尖角处 avgLen→0 会让外扩距离爆炸成"飞点"——clamp 到 4 倍步长。
      final maxScale = meters.abs() * 4;
      if (scale.abs() > maxScale) scale = scale.sign * maxScale;
      final dLng = avgNx * scale / 111000.0 * (latOff / lngOff);
      final dLat = avgNy * scale / 111000.0;

      buffer.add(LatLng(
        curr.latitude + dLat,
        curr.longitude + dLng,
      ));
    }

    return buffer;
  }
}
