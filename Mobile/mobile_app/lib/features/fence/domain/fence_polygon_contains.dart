import 'package:latlong2/latlong.dart';

bool fencePolygonContainsLatLng(LatLng point, List<LatLng> ring) {
  if (ring.length < 3) {
    return false;
  }
  final x = point.longitude;
  final y = point.latitude;
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final xi = ring[i].longitude;
    final yi = ring[i].latitude;
    final xj = ring[j].longitude;
    final yj = ring[j].latitude;
    final intersect =
        ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
    if (intersect) {
      inside = !inside;
    }
  }
  return inside;
}
