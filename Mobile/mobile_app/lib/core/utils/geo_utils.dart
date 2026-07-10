import 'dart:math';

/// Haversine distance between two coordinates in meters.
double haversineDistance(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0; // Earth radius in meters
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}

double _toRad(double deg) => deg * pi / 180;

/// Total distance of a GPS path in meters.
double totalPathDistance(List<({double lat, double lng})> points) {
  double dist = 0;
  for (int i = 1; i < points.length; i++) {
    dist += haversineDistance(
      points[i - 1].lat, points[i - 1].lng,
      points[i].lat, points[i].lng,
    );
  }
  return dist;
}

/// Uniformly downsample a list to at most [maxSize] elements.
List<T> downsample<T>(List<T> items, int maxSize) {
  if (items.length <= maxSize) return items;
  final step = items.length / maxSize;
  final result = <T>[];
  for (double i = 0; i < items.length && result.length < maxSize; i += step) {
    result.add(items[i.toInt()]);
  }
  return result;
}
