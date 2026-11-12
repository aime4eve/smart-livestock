import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/roaming_trim.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_point.dart';

/// RoamingTrim unit tests: quantile boundary, equidistant points, kept
/// order preservation, the 3-point floor, quantile 1.0, and pass-through
/// for tiny inputs.
void main() {
  const anchorLat = 28.20;
  const anchorLng = 112.90;
  final mPerDegLng = 111320.0 * cos(anchorLat * pi / 180.0);

  /// Meter-offset → track point (accuracy/timestamp irrelevant here).
  TrackPoint m(double x, double y) =>
      TrackPoint(lat: anchorLat + y / 111320.0, lng: anchorLng + x / mPerDegLng);

  /// [n] points evenly spread on a circle of [radiusM] around the anchor.
  List<TrackPoint> circle(int n, double radiusM) => [
        for (var i = 0; i < n; i++)
          m(cos(2 * pi * i / n) * radiusM, sin(2 * pi * i / n) * radiusM),
      ];

  test('quantile boundary keeps exactly floor(n × quantile)', () {
    // 19 points on a 10m ring + 1 far point at 100m → 20 points at q=0.95.
    final inner = circle(19, 10);
    final far = m(100, 0);
    final pts = [...inner, far];

    final result = RoamingTrim.trim(pts, 0.95);

    expect(result.kept.length, 19);
    expect(result.trimmed, [far]);
  });

  test('all-equidistant points trim nothing (small-n full keep)', () {
    // 3 identical points: n × 0.95 < 3 → the 3-point floor keeps everything.
    final pts = [m(10, 10), m(10, 10), m(10, 10)];

    final result = RoamingTrim.trim(pts, 0.95);

    expect(result.kept.length, 3);
    expect(result.trimmed, isEmpty);
  });

  test('kept preserves the original point order', () {
    // Far point placed in the middle of the input; kept must stay ordered.
    final inner = circle(9, 10);
    final far = m(500, 0);
    final pts = [...inner.sublist(0, 4), far, ...inner.sublist(4)];

    final result = RoamingTrim.trim(pts, 0.9); // floor(10 × 0.9) = 9

    expect(result.trimmed, [far]);
    expect(result.kept, orderedEquals(inner));
  });

  test('keeps at least 3 points even at a tiny quantile', () {
    final pts = [
      ...circle(3, 10), // the 3 nearest
      ...circle(7, 100), // farther ring
    ];

    final result = RoamingTrim.trim(pts, 0.2); // floor(10 × 0.2) = 2 → clamp 3

    expect(result.kept.length, 3);
    expect(result.trimmed.length, 7);
    expect(result.kept, orderedEquals(pts.sublist(0, 3)));
  });

  test('quantile 1.0 keeps everything', () {
    final pts = [...circle(8, 10), m(500, 0), m(-600, 100)];

    final result = RoamingTrim.trim(pts, 1.0);

    expect(result.kept, orderedEquals(pts));
    expect(result.trimmed, isEmpty);
  });

  test('empty and <3-point inputs pass through unchanged', () {
    final empty = RoamingTrim.trim(const <TrackPoint>[], 0.95);
    expect(empty.kept, isEmpty);
    expect(empty.trimmed, isEmpty);

    final two = [m(0, 0), m(50, 0)];
    final result = RoamingTrim.trim(two, 0.5);
    expect(result.kept, orderedEquals(two));
    expect(result.trimmed, isEmpty);
  });
}
