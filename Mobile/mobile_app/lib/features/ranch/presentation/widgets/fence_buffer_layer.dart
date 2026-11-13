import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hkt_livestock_agentic/core/map/coord_transform.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';

/// 50m 预警缓冲带（围栏边界【外侧】环带，NIX-412）。
///
/// 几何单源：外环 = 后端围栏创建/更新时 JTS 预计算并存库的
/// [RanchFenceData.bufferPolygon]——与告警引擎 containsBuffer 判定的
/// 是同一份几何（渲染的带 ≡ 触发 FENCE_APPROACH 的带）。洞 = 围栏本体，
/// 挖掉后可见部分即"围栏外 50m 环带"，任意形状（含凹多边形）统一成立。
///
/// bufferPolygon 为空（后端未下发/历史行缺失）时跳过该围栏——
/// 不回退客户端自算（角平分线外扩在凹角自交，两套几何正是 NIX-412 病根）。
class FenceBufferLayer extends StatelessWidget {
  const FenceBufferLayer({
    super.key,
    required this.fences,
    this.shouldTransform = false,
  });

  final List<RanchFenceData> fences;
  final bool shouldTransform;

  @override
  Widget build(BuildContext context) {
    final polygons = <Polygon>[];

    for (final fence in fences) {
      if (!fence.active || fence.points.isEmpty) continue;
      // Backend JTS buffer ring absent → no band (never recompute locally).
      if (fence.bufferPoints.length < 3) continue;

      final fenceScreen = shouldTransform
          ? CoordTransform.wgs84ToGcj02All(fence.points)
          : fence.points;
      // Outer ring and hole must go through the same coordinate transform,
      // otherwise the band visually shifts off the fence boundary.
      final outerScreen = shouldTransform
          ? CoordTransform.wgs84ToGcj02All(fence.bufferPoints)
          : fence.bufferPoints;

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
}
