import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_polygon_contains.dart';

void main() {
  test('fencePolygonContainsLatLng 在多边形内部为 true', () {
    final a = DemoSeed.fencePolygons.first;
    final inner = LatLng(
      (a.points[0].latitude + a.points[2].latitude) / 2,
      (a.points[0].longitude + a.points[2].longitude) / 2,
    );
    expect(fencePolygonContainsLatLng(inner, a.points), isTrue);
  });

  test('fencePolygonContainsLatLng 在多边形外部为 false', () {
    final a = DemoSeed.fencePolygons.first;
    const outside = LatLng(28.20, 112.90);
    expect(fencePolygonContainsLatLng(outside, a.points), isFalse);
  });

  test('fencePolygonContainsLatLng 顶点少于 3 为 false', () {
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
