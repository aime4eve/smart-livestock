import 'dart:async' show StreamSubscription;
import 'dart:math' show cos, max, min, pow, sqrt;
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
/// 瑕疵（若有）完全被宽带覆盖，不可见。
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

  /// 顶点环沿角平分线法线偏移 [meters]（米制角平分线法，锐角补偿+安全
  /// 上限）。负值=向内。窄凸起（宽 < 2×offset）处内缩环会自交——调用方
  /// 用它作「洞」的带洞渲染下，该区域整体着色（凸起整体处于预警带内），
  /// 视觉语义正确。
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

      // 转角正弦（邻边单位向量叉积）→ 内缩沿平分线的距离补偿。
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
