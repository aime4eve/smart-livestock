import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/fence_polygon_contains.dart';

void main() {
  test('fencePolygonContainsLatLng inside polygon returns true', () {
    const points = [
      LatLng(28.2340, 112.9400),
      LatLng(28.2340, 112.9440),
      LatLng(28.2305, 112.9440),
      LatLng(28.2305, 112.9400),
    ];
    final inner = LatLng(
      (points[0].latitude + points[2].latitude) / 2,
      (points[0].longitude + points[2].longitude) / 2,
    );
    expect(fencePolygonContainsLatLng(inner, points), isTrue);
  });

  test('fencePolygonContainsLatLng outside polygon returns false', () {
    const points = [
      LatLng(28.2340, 112.9400),
      LatLng(28.2340, 112.9440),
      LatLng(28.2305, 112.9440),
      LatLng(28.2305, 112.9400),
    ];
    const outside = LatLng(28.20, 112.90);
    expect(fencePolygonContainsLatLng(outside, points), isFalse);
  });

  test('fencePolygonContainsLatLng fewer than 3 points returns false', () {
    expect(
      fencePolygonContainsLatLng(
        const LatLng(28.0, 112.0),
        const [
          LatLng(28.0, 112.0),
          LatLng(28.1, 112.0),
        ],
      ),
      isFalse,
    );
  });
}
