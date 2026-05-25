import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/models/core_models.dart';
import 'package:smart_livestock_demo/features/devices/domain/devices_repository.dart';

class DevicesApiRepository implements DevicesRepository {
  const DevicesApiRepository();

  @override
  Future<DevicesListData> loadDevices({
    int page = 1,
    int pageSize = 20,
  }) async {
    final data =
        await ApiClient.instance.farmGet('/devices?page=$page&pageSize=$pageSize');
    final itemsRaw = data['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map<String, dynamic>>()
            .map(_parseDeviceItem)
            .whereType<DeviceItem>()
            .toList()
        : <DeviceItem>[];
    return DevicesListData(
      items: items,
      total: data['total'] as int? ?? items.length,
      page: data['page'] as int? ?? page,
      pageSize: data['pageSize'] as int? ?? pageSize,
    );
  }

  @override
  Future<DeviceItem> loadDetail(String id) async {
    final data = await ApiClient.instance.farmGet('/devices/$id');
    return _parseDeviceItemRequired(data);
  }

  @override
  Future<DeviceItem> create(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.farmPost('/devices', body: body);
    return _parseDeviceItemRequired(data);
  }

  @override
  Future<DeviceItem> update(String id, Map<String, dynamic> body) async {
    final data =
        await ApiClient.instance.farmPut('/devices/$id', body: body);
    return _parseDeviceItemRequired(data);
  }

  @override
  Future<void> activate(String id) async {
    await ApiClient.instance.farmPost('/devices/$id/activate');
  }

  @override
  Future<void> decommission(String id) async {
    await ApiClient.instance.farmPost('/devices/$id/decommission');
  }

  @override
  Future<List<DeviceLicense>> loadLicenses() async {
    // Tenant-level, no farm scope
    final data = await ApiClient.instance.get('/device-licenses');
    final itemsRaw = data['items'] ?? data['value'];
    if (itemsRaw is! List) return const [];
    return itemsRaw
        .whereType<Map<String, dynamic>>()
        .map(_parseLicense)
        .toList();
  }

  @override
  Future<List<Installation>> loadInstallations() async {
    final data = await ApiClient.instance.farmGet('/installations');
    final itemsRaw = data['items'] ?? data['value'];
    if (itemsRaw is! List) return const [];
    return itemsRaw
        .whereType<Map<String, dynamic>>()
        .map(_parseInstallation)
        .toList();
  }

  @override
  Future<List<GpsPoint>> loadLatestGps() async {
    final data = await ApiClient.instance.farmGet('/gps-logs/latest');
    final itemsRaw = data['items'] ?? data['value'];
    if (itemsRaw is! List) return const [];
    return itemsRaw
        .whereType<Map<String, dynamic>>()
        .map(_parseGpsPoint)
        .toList();
  }

  @override
  Future<List<GpsPoint>> loadGpsHistory(String livestockId) async {
    final data = await ApiClient.instance
        .farmGet('/livestock/$livestockId/gps-logs');
    final itemsRaw = data['items'] ?? data['value'];
    if (itemsRaw is! List) return const [];
    return itemsRaw
        .whereType<Map<String, dynamic>>()
        .map(_parseGpsPoint)
        .toList();
  }

  static DeviceItem? _parseDeviceItem(Map<String, dynamic> m) {
    try {
      final rawId = m['id'];
      final id =
          rawId is int ? rawId.toString() : (rawId as String? ?? '');
      final typeStr = m['type'] as String;
      final type = switch (typeStr) {
        'gps' => DeviceType.gps,
        'rumenCapsule' => DeviceType.rumenCapsule,
        'accelerometer' => DeviceType.accelerometer,
        _ => throw const FormatException('type'),
      };
      final statusStr = m['status'] as String;
      final status = switch (statusStr) {
        'online' => DeviceStatus.online,
        'offline' => DeviceStatus.offline,
        'lowBattery' => DeviceStatus.lowBattery,
        _ => throw const FormatException('status'),
      };
      return DeviceItem(
        id: id,
        name: m['name'] as String,
        type: type,
        status: status,
        boundEarTag: m['boundEarTag'] as String? ?? '',
        batteryPercent: (m['batteryPercent'] as num?)?.toInt(),
        signalStrength: m['signalStrength'] as String?,
        lastSync: m['lastSync'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static DeviceItem _parseDeviceItemRequired(Map<String, dynamic> m) {
    final parsed = _parseDeviceItem(m);
    if (parsed == null) throw FormatException('Failed to parse device: $m');
    return parsed;
  }

  static DeviceLicense _parseLicense(Map<String, dynamic> m) {
    final rawId = m['id'];
    return DeviceLicense(
      id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
      deviceId: (m['deviceId'] ?? '').toString(),
      licenseKey: (m['licenseKey'] ?? '').toString(),
      status: (m['status'] ?? 'active') as String,
    );
  }

  static Installation _parseInstallation(Map<String, dynamic> m) {
    final rawId = m['id'];
    return Installation(
      id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
      deviceId: (m['deviceId'] ?? '').toString(),
      livestockId: (m['livestockId'] ?? '').toString(),
      installedAt: (m['installedAt'] ?? '') as String,
    );
  }

  static GpsPoint _parseGpsPoint(Map<String, dynamic> m) {
    final rawLat = m['latitude'] ?? m['lat'] ?? 0;
    final rawLng = m['longitude'] ?? m['lng'] ?? 0;
    return GpsPoint(
      lat: (rawLat is num ? rawLat.toDouble() : 0.0),
      lng: (rawLng is num ? rawLng.toDouble() : 0.0),
      timestamp: (m['timestamp'] ?? '') as String,
      livestockId: m['livestockId'] as String?,
    );
  }
}
