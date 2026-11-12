import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Square meters per mu (1 mu = 2000/3 m² ≈ 666.67 m²), spec §5.6.
/// Used only inside [formatAreaForLocale] — callers must not divide by
/// this directly (plan Task 4: locale branching stays in one function).
const double sqmPerMu = 2000 / 3;

/// Square meters per hectare (1 ha = 10000 m²), appendix A ruling #14.
/// Used only inside [formatAreaForLocale] — same single-function rule.
const double sqmPerHa = 10000;

/// Locale-aware area display formatting — the single conversion entry
/// point for area values (plan Task 4 contract, appendix A ruling #14):
/// zh renders mu with 1 decimal and degrades below 0.1 mu; every other
/// language renders hectares with 2 decimals (ha convention precision)
/// and degrades below 0.01 ha. Degraded results carry the raw square
/// meters in [AreaDisplay.value] with [AreaDisplay.fallback] set; the
/// caller renders those via the `fenceTrackDraftAreaSqmFallback` l10n
/// key.
AreaDisplay formatAreaForLocale(String languageCode, double areaM2) {
  if (languageCode == 'zh') {
    final mu = areaM2 / sqmPerMu;
    if (mu >= 0.1) {
      return AreaDisplay(mu.toStringAsFixed(1), fallback: false);
    }
  } else {
    final ha = areaM2 / sqmPerHa;
    if (ha >= 0.01) {
      return AreaDisplay(ha.toStringAsFixed(2), fallback: false);
    }
  }
  // Below the display floor in either locale: degrade to raw ㎡.
  return AreaDisplay(areaM2.round().toString(), fallback: true);
}

/// Result of [formatAreaForLocale]: ready-to-print [value], plus whether
/// it is a raw-square-meters [fallback] instead of a locale-unit value.
class AreaDisplay {
  const AreaDisplay(this.value, {required this.fallback});

  final String value;
  final bool fallback;
}

const double _mPerDegLat = 111320.0;

/// Planar area of a WGS-84 ring (square meters) via local equirectangular
/// projection around the ring centroid + shoelace formula. Accurate enough
/// for fence-sized polygons (the envelope pipeline uses the same
/// projection family for its degenerate-area check).
double polygonAreaM2(List<LatLng> ring) {
  if (ring.length < 3) return 0;
  final lat0 =
      ring.map((p) => p.latitude).reduce((a, b) => a + b) / ring.length;
  final lng0 =
      ring.map((p) => p.longitude).reduce((a, b) => a + b) / ring.length;
  final mPerDegLng = _mPerDegLat * math.cos(lat0 * math.pi / 180.0);
  var area = 0.0;
  for (var i = 0; i < ring.length; i++) {
    final a = ring[i];
    final b = ring[(i + 1) % ring.length];
    final ax = (a.longitude - lng0) * mPerDegLng;
    final ay = (a.latitude - lat0) * _mPerDegLat;
    final bx = (b.longitude - lng0) * mPerDegLng;
    final by = (b.latitude - lat0) * _mPerDegLat;
    area += ax * by - bx * ay;
  }
  return area.abs() / 2;
}
