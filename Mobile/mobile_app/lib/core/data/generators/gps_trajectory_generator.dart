import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';

class GpsTrajectoryGenerator {
  GpsTrajectoryGenerator({this.seed = 42});

  final int seed;
  final Map<String, List<GeoPoint>> _cache = {};

  List<GeoPoint> generate({
    required String earTag,
    required List<LatLng> fenceBoundary,
    required DateTime start,
    required DateTime end,
  }) {
    return _cache.putIfAbsent(earTag, () => _doGenerate(
          earTag: earTag,
          fenceBoundary: fenceBoundary,
          start: start,
          end: end,
        ));
  }

  List<GeoPoint> _doGenerate({
    required String earTag,
    required List<LatLng> fenceBoundary,
    required DateTime start,
    required DateTime end,
  }) {
    final rng = Random(seed + earTag.hashCode);
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
}
