import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/core/data/generators/time_series_generator.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';

class GpsTrajectoryGenerator extends TimeSeriesGenerator<GeoPoint> {
  GpsTrajectoryGenerator({super.seed});

  static int _fingerprintPoints(List<LatLng>? points) {
    if (points == null || points.isEmpty) {
      return 0;
    }
    return Object.hashAll(
      points.map((p) => Object.hash(p.latitude, p.longitude)),
    );
  }

  static String _cacheKey(
    String earTag,
    List<LatLng> fenceBoundary,
    List<LatLng>? restFenceBoundary,
    List<LatLng>? anchorPoints,
    DateTime start,
    DateTime end,
  ) {
    final fenceFp = _fingerprintPoints(fenceBoundary);
    final restFenceFp = _fingerprintPoints(restFenceBoundary);
    final anchorFp = _fingerprintPoints(anchorPoints);
    return '$earTag|$fenceFp|$restFenceFp|$anchorFp|${start.millisecondsSinceEpoch}|${end.millisecondsSinceEpoch}';
  }

  List<GeoPoint> generate({
    required String earTag,
    required List<LatLng> fenceBoundary,
    List<LatLng>? restFenceBoundary,
    List<LatLng>? anchorPoints,
    required DateTime start,
    required DateTime end,
  }) {
    final key = _cacheKey(
      earTag,
      fenceBoundary,
      restFenceBoundary,
      anchorPoints,
      start,
      end,
    );
    return memoized(key, () => _doGenerate(
          earTag: earTag,
          fenceBoundary: fenceBoundary,
          restFenceBoundary: restFenceBoundary,
          anchorPoints: anchorPoints,
          start: start,
          end: end,
        ));
  }

  List<GeoPoint> _doGenerate({
    required String earTag,
    required List<LatLng> fenceBoundary,
    List<LatLng>? restFenceBoundary,
    List<LatLng>? anchorPoints,
    required DateTime start,
    required DateTime end,
  }) {
    final hasRestFence =
        restFenceBoundary != null && restFenceBoundary.isNotEmpty;
    final hasAnchors = anchorPoints != null && anchorPoints.isNotEmpty;
    final enhancedMode = hasRestFence || hasAnchors;
    if (!enhancedMode) {
      return _doGenerateLegacy(
        earTag: earTag,
        fenceBoundary: fenceBoundary,
        start: start,
        end: end,
      );
    }
    return _doGenerateEnhanced(
      earTag: earTag,
      fenceBoundary: fenceBoundary,
      restFenceBoundary: restFenceBoundary ?? fenceBoundary,
      anchorPoints: anchorPoints ?? const [],
      start: start,
      end: end,
    );
  }

  List<GeoPoint> _doGenerateLegacy({
    required String earTag,
    required List<LatLng> fenceBoundary,
    required DateTime start,
    required DateTime end,
  }) {
    final rng = rngForEntity(earTag);
    final points = <GeoPoint>[];

    final lats = fenceBoundary.map((p) => p.latitude).toList();
    final lngs = fenceBoundary.map((p) => p.longitude).toList();
    final minLat = lats.reduce(min);
    final maxLat = lats.reduce(max);
    final minLng = lngs.reduce(min);
    final maxLng = lngs.reduce(max);

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    var currentLat = centerLat + (rng.nextDouble() - 0.5) * (maxLat - minLat) * 0.3;
    var currentLng = centerLng + (rng.nextDouble() - 0.5) * (maxLng - minLng) * 0.3;

    var t = start;
    while (t.isBefore(end)) {
      final hour = t.hour;
      final isGrazing = hour >= 6 && hour < 18;
      final step = isGrazing ? 0.0003 : 0.00005;

      currentLat += (rng.nextDouble() - 0.5) * step * 2;
      currentLng += (rng.nextDouble() - 0.5) * step * 2;

      const margin = 0.0001;
      currentLat = currentLat.clamp(minLat + margin, maxLat - margin);
      currentLng = currentLng.clamp(minLng + margin, maxLng - margin);

      points.add(GeoPoint(
        lat: double.parse(currentLat.toStringAsFixed(4)),
        lng: double.parse(currentLng.toStringAsFixed(4)),
        timestamp: t.toIso8601String(),
      ));

      t = t.add(const Duration(hours: 1));
    }

    return points;
  }

  List<GeoPoint> _doGenerateEnhanced({
    required String earTag,
    required List<LatLng> fenceBoundary,
    required List<LatLng> restFenceBoundary,
    required List<LatLng> anchorPoints,
    required DateTime start,
    required DateTime end,
  }) {
    final rng = rngForEntity(earTag);
    final points = <GeoPoint>[];
    final mainBounds = _boundsFromPolygon(fenceBoundary);
    final restBounds = _boundsFromPolygon(restFenceBoundary);
    final nearBoundaryMode = earTag.hashCode.abs() % 23 == 0;

    var currentLat =
        mainBounds.centerLat + (rng.nextDouble() - 0.5) * mainBounds.latSpan * 0.3;
    var currentLng =
        mainBounds.centerLng + (rng.nextDouble() - 0.5) * mainBounds.lngSpan * 0.3;

    var t = start;
    var wasNight = false;
    while (t.isBefore(end)) {
      final hour = t.hour;
      final isNight = hour < 6 || hour >= 18;
      final activeBounds = isNight ? restBounds : mainBounds;

      if (isNight && !wasNight) {
        currentLat = restBounds.centerLat + (rng.nextDouble() - 0.5) * 0.0002;
        currentLng = restBounds.centerLng + (rng.nextDouble() - 0.5) * 0.0002;
      }

      if (!isNight && anchorPoints.isNotEmpty) {
        final idx =
            (earTag.hashCode.abs() + _dayOfYear(t) + hour) % anchorPoints.length;
        final target = anchorPoints[idx];
        final bias = hour % 3 == 0 ? 0.32 : 0.14;
        currentLat += (target.latitude - currentLat) * bias;
        currentLng += (target.longitude - currentLng) * bias;
      }

      final step = isNight ? 0.00005 : 0.00028;
      currentLat += (rng.nextDouble() - 0.5) * step * 2;
      currentLng += (rng.nextDouble() - 0.5) * step * 2;

      if (!isNight && nearBoundaryMode && hour % 7 == 0) {
        final side = rng.nextInt(4);
        switch (side) {
          case 0:
            currentLat = mainBounds.maxLat - 0.00012;
            break;
          case 1:
            currentLat = mainBounds.minLat + 0.00012;
            break;
          case 2:
            currentLng = mainBounds.maxLng - 0.00012;
            break;
          case 3:
            currentLng = mainBounds.minLng + 0.00012;
            break;
        }
      }

      const margin = 0.0001;
      currentLat = currentLat.clamp(
        activeBounds.minLat + margin,
        activeBounds.maxLat - margin,
      );
      currentLng = currentLng.clamp(
        activeBounds.minLng + margin,
        activeBounds.maxLng - margin,
      );

      points.add(GeoPoint(
        lat: double.parse(currentLat.toStringAsFixed(4)),
        lng: double.parse(currentLng.toStringAsFixed(4)),
        timestamp: t.toIso8601String(),
      ));

      wasNight = isNight;
      t = t.add(const Duration(hours: 1));
    }
    return points;
  }

  int _dayOfYear(DateTime dt) {
    final firstDay = DateTime(dt.year, 1, 1);
    return dt.difference(firstDay).inDays + 1;
  }

  _Bounds _boundsFromPolygon(List<LatLng> polygon) {
    final lats = polygon.map((p) => p.latitude).toList();
    final lngs = polygon.map((p) => p.longitude).toList();
    return _Bounds(
      minLat: lats.reduce(min),
      maxLat: lats.reduce(max),
      minLng: lngs.reduce(min),
      maxLng: lngs.reduce(max),
    );
  }
}

class _Bounds {
  const _Bounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  double get centerLat => (minLat + maxLat) / 2;
  double get centerLng => (minLng + maxLng) / 2;
  double get latSpan => max(maxLat - minLat, 0.0002);
  double get lngSpan => max(maxLng - minLng, 0.0002);
}
