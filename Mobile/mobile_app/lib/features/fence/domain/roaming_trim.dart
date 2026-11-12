import 'track_point.dart';
import 'track_to_envelope_converter.dart';

/// Distance-quantile roaming trim for animal tracks (spec §5.2): drops the
/// points farthest from the median center so occasional far-roaming
/// excursions do not inflate the envelope. Pure function, no Flutter deps.
///
/// dart2js-safe: the only ordering is a sort over double distances with an
/// explicit index tie-break — no Set iteration order, no stability
/// assumption on `List.sort`.
class RoamingTrim {
  const RoamingTrim._();

  /// Keeps the `floor(n × quantile)` points nearest to the median center
  /// (per-axis median of lat/lng), clamped to at least 3 points. [kept]
  /// preserves the original point order; [trimmed] holds the discarded set
  /// (order unspecified).
  ///
  /// Pass-through (empty [trimmed]): fewer than 3 input points. When
  /// `n × quantile < 3` (e.g. n=3 at quantile 0.95) the 3-point floor
  /// already covers the whole input, so everything is kept.
  static ({List<TrackPoint> kept, List<TrackPoint> trimmed}) trim(
      List<TrackPoint> points, double quantile) {
    final n = points.length;
    if (n < 3) {
      return (kept: List.of(points), trimmed: const <TrackPoint>[]);
    }
    var keepCount = (n * quantile).floor();
    if (keepCount < 3) keepCount = 3;
    if (keepCount > n) keepCount = n;

    final lat0 = _median(points.map((p) => p.lat));
    final lng0 = _median(points.map((p) => p.lng));
    final dists = <double>[
      for (final p in points)
        TrackToEnvelopeConverter.haversineM(lat0, lng0, p.lat, p.lng),
    ];

    // Sort indices by distance ascending; the index tie-break makes the
    // result deterministic without relying on sort stability.
    final order = List<int>.generate(n, (i) => i);
    order.sort((a, b) {
      final c = dists[a].compareTo(dists[b]);
      return c != 0 ? c : a.compareTo(b);
    });

    final keepFlag = List<bool>.filled(n, false);
    for (var k = 0; k < keepCount; k++) {
      keepFlag[order[k]] = true;
    }
    final kept = <TrackPoint>[];
    final trimmed = <TrackPoint>[];
    for (var i = 0; i < n; i++) {
      (keepFlag[i] ? kept : trimmed).add(points[i]);
    }
    return (kept: kept, trimmed: trimmed);
  }

  static double _median(Iterable<double> values) {
    final list = values.toList()..sort();
    if (list.isEmpty) return 0;
    final mid = list.length ~/ 2;
    return list.length.isOdd ? list[mid] : (list[mid - 1] + list[mid]) / 2;
  }
}
