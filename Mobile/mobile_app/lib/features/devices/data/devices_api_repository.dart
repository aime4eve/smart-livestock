import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/features/devices/domain/devices_repository.dart';

class DevicesApiRepository implements DevicesRepository {
  const DevicesApiRepository();

  @override
  Future<DevicesListData> loadDevices({
    int page = 1,
    int pageSize = 20,
    String? keyword,
  }) async {
    var path = '/devices?page=$page&pageSize=$pageSize';
    if (keyword != null && keyword.isNotEmpty) {
      path += '&keyword=${Uri.encodeQueryComponent(keyword)}';
    }
    final data = await ApiClient.instance.farmGet(path);
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
    await ApiClient.instance.farmPut('/devices/$id/activate');
  }

  @override
  Future<void> decommission(String id) async {
    await ApiClient.instance.farmPut('/devices/$id/decommission');
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
      final typeStr = (m['deviceType'] ?? m['type']) as String;
      final type = switch (typeStr.toUpperCase()) {
        'TRACKER' || 'GPS' => DeviceType.gps,
        'RUMEN_CAPSULE' || 'CAPSULE' => DeviceType.rumenCapsule,
        'EAR_TAG' => DeviceType.earTag,
        _ => throw FormatException('deviceType: $typeStr'),
      };
      final statusStr = (m['runtimeStatus'] ?? m['status']) as String;
      final status = switch (statusStr.toUpperCase()) {
        'ONLINE' => DeviceStatus.online,
        'OFFLINE' => DeviceStatus.offline,
        'LOW_BATTERY' => DeviceStatus.lowBattery,
        _ => DeviceStatus.offline,
      };
     return DeviceItem(
       id: id,
       name: (m['deviceCode'] ?? m['name'] ?? '') as String,
       type: type,
       status: status,
       boundEarTag: m['boundEarTag'] as String? ?? '',
       batteryPercent: (m['batteryLevel'] ?? m['batteryPercent']) as int?,
       signalStrength: m['signalStrength'] as String?,
       lastSync: (m['lastOnlineAt'] ?? m['lastSync']) as String?,
       platformDeviceId: _parseNullableInt(m['platformDeviceId']),
       rssi: _parseNullableInt(m['rssi']),
       snr: m['snr']?.toString(),
       lastGateway: m['lastGateway'] as String?,
       antiDisassemblyStatus: _parseNullableInt(m['antiDisassemblyStatus']),
       lastTelemetrySyncedAt: m['lastTelemetrySyncedAt'] as String?,
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

  @override
  Future<Map<String, dynamic>> loadDeviceHealth(String deviceId) async {
    return await farmGet('devices/$deviceId/health');
  }

  static int? _parseNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
