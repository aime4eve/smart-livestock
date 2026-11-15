import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/features/fence/data/fence_dto.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/fence_item.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_draft_area.dart';

void main() {
  test('coordinatesToLatLngPoints maps lng lat pairs to LatLng', () {
    final pts = coordinatesToLatLngPoints([
      [112.94, 28.234],
      [112.944, 28.2305],
    ]);
    expect(pts.length, 2);
    expect(pts[0], const LatLng(28.234, 112.94));
    expect(pts[1], const LatLng(28.2305, 112.944));
  });

  test('livestockCountsByFenceId aggregates fenceId', () {
    final m = livestockCountsByFenceId([
      {'fenceId': 'fence_a'},
      {'fenceId': 'fence_a'},
      {'fenceId': 'fence_b'},
    ]);
    expect(m['fence_a'], 2);
    expect(m['fence_b'], 1);
  });

  test('fenceItemFromJson builds FenceItem from API map', () {
    final item = fenceItemFromJson(
      {
        'id': 'fence_pasture_a',
        'name': '放牧A区',
        'type': 'polygon',
        'alarmEnabled': true,
        'status': 'active',
        'coordinates': [
          [112.94, 28.234],
          [112.944, 28.234],
          [112.944, 28.2305],
          [112.94, 28.2305],
        ],
      },
      0,
      12,
    );
    expect(item.id, 'fence_pasture_a');
    expect(item.livestockCount, 12);
    expect(item.points.length, 4);
    expect(item.type, FenceType.polygon);
  });

  // NIX-410: the persisted form shape rides the `shape` key (the legacy
  // `type` key was never sent by the backend and always fell back).
  test('fenceItemFromJson maps the shape key to the FenceType enum', () {
    FenceItem parse(Map<String, dynamic> raw) =>
        fenceItemFromJson(raw, 0, 0);

    expect(
      parse({
        'id': 'f1',
        'shape': 'rectangle',
        'coordinates': [
          [112.9, 28.2],
          [112.91, 28.2],
          [112.91, 28.21],
        ],
      }).type,
      FenceType.rectangle,
    );
    expect(
      parse({
        'id': 'f2',
        'shape': 'circle',
        'coordinates': [
          [112.9, 28.2],
          [112.91, 28.2],
          [112.91, 28.21],
        ],
      }).type,
      FenceType.circle,
    );
    // Missing key (older payloads) and unknown values degrade to polygon.
    expect(
      parse({
        'id': 'f3',
        'coordinates': [
          [112.9, 28.2],
          [112.91, 28.2],
          [112.91, 28.21],
        ],
      }).type,
      FenceType.polygon,
    );
    expect(
      parse({
        'id': 'f4',
        'shape': 'hexagon',
        'coordinates': [
          [112.9, 28.2],
          [112.91, 28.2],
          [112.91, 28.21],
        ],
      }).type,
      FenceType.polygon,
    );
  });

  // NIX-200: the backend sends the true area; the offline-cache / older
  // payload path (no key or 0) falls back to computing from the vertices
  // with the SAME planar formula as the server — one value on every surface.
  test('fenceItemFromJson prefers the API area and falls back to vertices',
      () {
    FenceItem parse(Map<String, dynamic> raw) =>
        fenceItemFromJson(raw, 0, 0);
    final squareCoords = [
      [112.938, 28.0],
      [112.939, 28.0],
      [112.939, 28.001],
      [112.938, 28.001],
    ];

    // API value wins when present.
    expect(
      parse({
        'id': 'a1',
        'shape': 'polygon',
        'areaHectares': 6.55,
        'coordinates': squareCoords,
      }).areaHectares,
      closeTo(6.55, 1e-9),
    );

    // Missing key → computed fallback (0.001° square at lat 28 ≈ 1.1 ha).
    final computed = parse({
      'id': 'a2',
      'shape': 'polygon',
      'coordinates': squareCoords,
    }).areaHectares;
    final expected = polygonAreaM2([
      const LatLng(28.0, 112.938),
      const LatLng(28.0, 112.939),
      const LatLng(28.001, 112.939),
      const LatLng(28.001, 112.938),
    ]) / 10000.0;
    expect(computed, closeTo(expected, 1e-9));
    // Server mirror (FenceAreaCalculatorTest) pins the same square to
    // FenceAreaCalculator.areaHectares — this cross-checks the formulas.
    expect(computed, closeTo(1.0942, 0.001));

    // Legacy zero → still computes instead of showing 0.
    expect(
      parse({
        'id': 'a3',
        'shape': 'polygon',
        'areaHectares': 0,
        'coordinates': squareCoords,
      }).areaHectares,
      closeTo(expected, 1e-9),
    );
  });
}
