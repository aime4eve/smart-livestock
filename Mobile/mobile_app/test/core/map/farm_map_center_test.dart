import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/core/map/farm_map_center.dart';
import 'package:hkt_livestock_agentic/core/map/map_constants.dart';

/// Regression for the bug where a farm created by b2b_admin without any
/// fence showed the hardcoded demo center (Changsha) on the owner's ranch
/// map instead of the farm's registered coordinates.
void main() {
  group('resolveFarmMapCenter', () {
    test('no fences → farm registered coordinates', () {
      final center = resolveFarmMapCenter(
        fenceRings: const [],
        farmLatitude: -32.0,
        farmLongitude: -62.5,
      );
      expect(center, const LatLng(-32.0, -62.5));
    });

    test('fences win over farm coordinates (vertex average of first fence)', () {
      final center = resolveFarmMapCenter(
        fenceRings: const [
          [LatLng(10.0, 20.0), LatLng(12.0, 22.0)],
          [LatLng(50.0, 60.0)],
        ],
        farmLatitude: -32.0,
        farmLongitude: -62.5,
      );
      expect(center, const LatLng(11.0, 21.0));
    });

    test('empty fence ring is skipped, next fence used', () {
      final center = resolveFarmMapCenter(
        fenceRings: const [
          [],
          [LatLng(10.0, 20.0)],
        ],
        farmLatitude: -32.0,
        farmLongitude: -62.5,
      );
      expect(center, const LatLng(10.0, 20.0));
    });

    test('no fences and no farm coordinates → null (keep default)', () {
      final center = resolveFarmMapCenter(fenceRings: const []);
      expect(center, isNull);
    });

    test('shouldTransform converts farm coordinates to GCJ-02', () {
      final raw = resolveFarmMapCenter(
        fenceRings: const [],
        farmLatitude: 28.229,
        farmLongitude: 112.938,
      );
      final transformed = resolveFarmMapCenter(
        fenceRings: const [],
        farmLatitude: 28.229,
        farmLongitude: 112.938,
        shouldTransform: true,
      );
      expect(raw, isNotNull);
      expect(transformed, isNotNull);
      expect(transformed!.latitude, isNot(equals(raw!.latitude)));
      expect(transformed.latitude, closeTo(raw.latitude, 0.01));
      expect(transformed.longitude, closeTo(raw.longitude, 0.01));
    });

    test('Changsha demo farm with fences keeps centering inside its area', () {
      // 既有行为守护：带围栏的演示牧场不应因本次修复改变定位区域
      final center = resolveFarmMapCenter(
        fenceRings: const [
          [LatLng(28.2336, 112.9435), LatLng(28.2254, 112.9357)],
        ],
        farmLatitude: 28.229,
        farmLongitude: 112.938,
      );
      expect(center!.latitude, inInclusiveRange(28.20, 28.25));
      expect(center.longitude, inInclusiveRange(112.90, 112.96));
      expect(center, isNot(MapConstants.mapCenter));
    });
  });
}
