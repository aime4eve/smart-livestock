import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/core/map/coord_transform.dart';

void main() {
  group('gcj02ToWgs84', () {
    test('round-trip wgs84→gcj02→wgs84 偏差 < 0.5m', () {
      final points = [
        LatLng(28.2282, 112.9388),
        LatLng(39.9042, 116.4074),
        LatLng(31.2304, 121.4737),
        LatLng(43.8256, 87.6168),
        LatLng(40.8422, 111.7500),
      ];
      for (final wgs in points) {
        final gcj = CoordTransform.wgs84ToGcj02(wgs);
        final roundTrip = CoordTransform.gcj02ToWgs84(gcj);
        final distance = _haversine(wgs, roundTrip);
        expect(distance, lessThan(0.5),
            reason: '${wgs.latitude},${wgs.longitude} round-trip ${distance}m >= 0.5m');
      }
    });

    test('海外坐标不变', () {
      final sydney = LatLng(-33.8688, 151.2093);
      expect(CoordTransform.gcj02ToWgs84(sydney), equals(sydney));
    });

    test('迭代收敛精度 < 0.1m', () {
      final wgs = LatLng(28.2282, 112.9388);
      final gcj = CoordTransform.wgs84ToGcj02(wgs);
      final inverse = CoordTransform.gcj02ToWgs84(gcj);
      final distance = _haversine(wgs, inverse);
      expect(distance, lessThan(0.1),
          reason: '迭代收敛 ${distance}m >= 0.1m');
    });
  });

  group('gcj02ToWgs84All', () {
    test('批量逆转换', () {
      final originals = [
        LatLng(28.2282, 112.9388),
        LatLng(39.9042, 116.4074),
      ];
      final gcjPoints = CoordTransform.wgs84ToGcj02All(originals);
      final wgsPoints = CoordTransform.gcj02ToWgs84All(gcjPoints);
      expect(wgsPoints.length, 2);
      for (int i = 0; i < originals.length; i++) {
        expect(_haversine(originals[i], wgsPoints[i]), lessThan(0.5));
      }
    });
  });
}

double _haversine(LatLng a, LatLng b) {
  const r = 6371000.0;
  final dLat = (b.latitude - a.latitude) * pi / 180;
  final dLng = (b.longitude - a.longitude) * pi / 180;
  final sin1 = sin(dLat / 2);
  final sin2 = sin(dLng / 2);
  final h = sin1 * sin1 +
      cos(a.latitude * pi / 180) * cos(b.latitude * pi / 180) * sin2 * sin2;
  return 2 * r * asin(sqrt(h));
}
