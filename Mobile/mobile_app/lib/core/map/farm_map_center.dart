import 'package:latlong2/latlong.dart';

import 'coord_transform.dart';

/// Resolves where a farm's map should first position itself.
///
/// Priority: actual fence extent (first fence's vertex average) →
/// the farm's registered coordinates → null (caller keeps default).
/// [shouldTransform] converts WGS-84 to GCJ-02 for 高德 tiles.
LatLng? resolveFarmMapCenter({
  required Iterable<List<LatLng>> fenceRings,
  double? farmLatitude,
  double? farmLongitude,
  bool shouldTransform = false,
}) {
  for (final points in fenceRings) {
    if (points.isEmpty) continue;
    double lat = 0, lng = 0;
    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    final center = LatLng(lat / points.length, lng / points.length);
    return shouldTransform ? CoordTransform.wgs84ToGcj02(center) : center;
  }
  if (farmLatitude == null || farmLongitude == null) return null;
  final raw = LatLng(farmLatitude, farmLongitude);
  return shouldTransform ? CoordTransform.wgs84ToGcj02(raw) : raw;
}
