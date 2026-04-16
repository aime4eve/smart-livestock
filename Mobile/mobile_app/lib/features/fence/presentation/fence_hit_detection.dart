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
