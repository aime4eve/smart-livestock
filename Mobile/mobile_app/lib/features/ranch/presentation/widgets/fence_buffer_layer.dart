import 'dart:async' show StreamSubscription;
import 'dart:math' show cos, pow, sqrt;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/core/map/coord_transform.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';

/// Meters per screen pixel at the given zoom/latitude.
double _metersPerPixelAt(double zoom, double latDeg) =>
    156543.03392 * cos(latDeg * pi / 180) / pow(2, zoom);

/// 50m 预警缓冲带（围栏内侧贴边环带）。
///
/// 2026-11-13 重构（集成测试反馈 #4：旧版顶点外扩多边形在凹角处自交，
/// 碎块翻进围栏内部）：改画「动态宽度 Polyline」——路径沿围栏边界向内
/// 平移半带宽，带宽 = [bufferDistance]（像素随 zoom 实时换算），带外缘
/// 正好贴围栏边界、整体落在围栏内侧。平移距离只有半带宽（25m），折叠
/// 瑕疵（若有）完全被宽带覆盖。
class FenceBufferLayer extends StatefulWidget {
  const FenceBufferLayer({
    super.key,
    required this.fences,
    required this.mapController,
    this.bufferDistance = 50,
    this.shouldTransform = false,
  });

  final List<RanchFenceData> fences;
  final MapController mapController;
  final int bufferDistance;
  final bool shouldTransform;

  @override
  State<FenceBufferLayer> createState() => _FenceBufferLayerState();
}

class _FenceBufferLayerState extends State<FenceBufferLayer> {
  StreamSubscription<MapEvent>? _sub;
  double _metersPerPixel = _metersPerPixelAt(15, 28.2);

  @override
  void initState() {
    super.initState();
    _sub = widget.mapController.mapEventStream.listen(_onMapEvent);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onMapEvent(MapEvent event) {
    final mpp =
        _metersPerPixelAt(event.camera.zoom, event.camera.center.latitude);
    // 只在缩放级别实质变化时重建（平移不改变像素宽度）。
    if ((mpp - _metersPerPixel).abs() / _metersPerPixel > 0.01) {
      setState(() => _metersPerPixel = mpp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final polylines = <Polyline>[];

    for (final fence in widget.fences) {
      if (!fence.active || fence.points.isEmpty) continue;

      // 中心线沿边界向内平移半带宽 → 色带外缘正好贴围栏边界、整体在内。
      final centerline =
          _offsetRing(fence.points, -(widget.bufferDistance / 2));
      if (centerline.length < 3) continue;
      final path = widget.shouldTransform
          ? CoordTransform.wgs84ToGcj02All(centerline)
          : centerline;

      polylines.add(Polyline(
        points: path,
        strokeWidth: (widget.bufferDistance) / _metersPerPixel,
        color: Colors.orange.withValues(alpha: 0.25),
      ));
    }

    if (polylines.isEmpty) return const SizedBox.shrink();

    return PolylineLayer(polylines: polylines);
  }

  /// 顶点环沿角平分线法线偏移 [meters]（负值=向内）。MVP 近似：急转角
  /// 的偏移量 clamp 到 4 倍步长防飞点；半带宽（25m）的小偏移折叠瑕疵被
  /// 色带宽度覆盖，不可见。
  List<LatLng> _offsetRing(List<LatLng> points, double meters) {
    if (points.length < 3) return [];
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

      // 边法线（米制单位向量）：lng 分量按纬度缩放到与 lat 同米级。
      final len1 = sqrt(dx1 * dx1 + dy1 * dy1);
      final len2 = sqrt(dx2 * dx2 + dy2 * dy2);
      if (len1 < 1e-10 || len2 < 1e-10) {
        buffer.add(curr);
        continue;
      }
      final nx1 = -dy1 / len1 / 111320.0;
      final ny1 = dx1 / len1 / 111320.0;
      final nx2 = -dy2 / len2 / 111320.0;
      final ny2 = dx2 / len2 / 111320.0;

      final avgNx = (nx1 + nx2) / 2;
      final avgNy = (ny1 + ny2) / 2;
      final avgLen = sqrt(avgNx * avgNx + avgNy * avgNy);
      if (avgLen < 1e-10) {
        buffer.add(curr);
        continue;
      }

      var scale = meters / avgLen;
      final maxScale = meters.abs() * 4;
      if (scale.abs() > maxScale) scale = scale.sign * maxScale;

      buffer.add(LatLng(
        curr.latitude + avgNy * scale,
        curr.longitude + avgNx * scale,
      ));
    }
    return buffer;
  }
}
