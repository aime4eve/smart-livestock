import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/core/api/api_client.dart';

class MapOverviewData {
  const MapOverviewData({
    required this.livestockCount,
    required this.onlineDeviceCount,
    required this.activeAlertCount,
  });

  final int livestockCount;
  final int onlineDeviceCount;
  final int activeAlertCount;
}

class GpsPoint {
  const GpsPoint({
    required this.lat,
    required this.lng,
    required this.timestamp,
    this.livestockId,
    this.earTag,
  });

  final double lat;
  final double lng;
  final String timestamp;
  final String? livestockId;
  final String? earTag;

  LatLng toLatLng() => LatLng(lat, lng);
}

class MapApiRepository {
  const MapApiRepository();

  Future<MapOverviewData> loadOverview() async {
    final data = await ApiClient.instance.farmGet('/map/overview');
    return MapOverviewData(
      livestockCount: _parseInt(data['livestockCount']) ?? 0,
      onlineDeviceCount: _parseInt(data['onlineDeviceCount']) ?? 0,
      activeAlertCount: _parseInt(data['activeAlertCount']) ?? 0,
    );
  }

  Future<List<GpsPoint>> loadLatestPositions() async {
    final data = await ApiClient.instance.farmGet('/gps-logs/latest');
    final items = data['items'] ?? data['value'];
    if (items is! List) return const [];
    return items.whereType<Map<String, dynamic>>().map(_parseGpsPoint).toList();
  }

  Future<List<GpsPoint>> loadTrajectory(String livestockId) async {
    final data =
        await ApiClient.instance.farmGet('/livestock/$livestockId/gps-logs');
    final items = data['items'] ?? data['value'];
    if (items is! List) return const [];
    return items.whereType<Map<String, dynamic>>().map(_parseGpsPoint).toList();
  }

  static int? _parseInt(dynamic v) =>
      v is int ? v : v is String ? int.tryParse(v) : null;

  static GpsPoint _parseGpsPoint(Map<String, dynamic> m) {
    final rawLat = m['latitude'] ?? m['lat'] ?? 0;
    final rawLng = m['longitude'] ?? m['lng'] ?? 0;
    return GpsPoint(
      lat: (rawLat is num ? rawLat.toDouble() : 0.0),
      lng: (rawLng is num ? rawLng.toDouble() : 0.0),
      timestamp: (m['timestamp'] ?? '') as String,
      livestockId: m['livestockId'] as String?,
      earTag: m['earTag'] as String?,
    );
  }
}
