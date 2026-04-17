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
