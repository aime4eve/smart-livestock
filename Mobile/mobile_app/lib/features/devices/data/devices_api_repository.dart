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
  Future<void> delete(String id) async {
    await ApiClient.instance.farmDelete('/devices/$id');
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
       'ACTIVE' => DeviceStatus.online,
       _ => DeviceStatus.offline,
     };
     return DeviceItem(
       id: id,
       name: (m['deviceCode'] ?? m['name'] ?? '') as String,
       type: type,
       status: status,
       boundLivestockCode: m['boundLivestockCode'] as String? ?? '',
       batteryPercent: (m['batteryLevel'] ?? m['batteryPercent']) as int?,
       signalStrength: m['signalStrength'] as String?,
       lastSync: (m['lastOnlineAt'] ?? m['lastSync']) as String?,
       platformDeviceId: m['platformDeviceId']?.toString(),
       rssi: _parseNullableInt(m['rssi']),
       snr: m['snr']?.toString(),
       lastGateway: m['lastGateway'] as String?,
      antiDisassemblyStatus: _parseNullableInt(m['antiDisassemblyStatus']),
      lastTelemetrySyncedAt: m['lastTelemetrySyncedAt'] as String?,
      devEui: m['devEui'] as String?,
      runtimeStatus: m['runtimeStatus'] as String?,
      softwareVersion: m['softwareVersion'] as String?,
      hardwareVersion: m['hardwareVersion'] as String?,
      deviceTypeName: m['deviceTypeName'] as String?,
      lifecycleStatus: m['status'] as String?,
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
    return await ApiClient.instance.farmGet('/devices/$deviceId/health');
  }

  @override
  Future<TbDevicePreflight> preflightTbDevice(String eui) async {
    final data = await ApiClient.instance.farmGet(
      '/devices/tb/preflight?eui=${Uri.encodeQueryComponent(eui)}',
    );
    return _parseTbPreflight(data);
  }

  @override
  Future<TbDeviceProvisionResult> provisionTbDevice({
    required String eui,
    String? deviceCode,
    String? deviceType,
    String? livestockId,
  }) async {
    final data = await ApiClient.instance.farmPost(
      '/devices/tb/provision',
      body: {
        'eui': eui,
        if (deviceCode != null && deviceCode.isNotEmpty) 'deviceCode': deviceCode,
        if (deviceType != null) 'deviceType': deviceType,
        if (livestockId != null) 'livestockId': livestockId,
      },
    );
    final result = _requiredMap(data['result']);
    return TbDeviceProvisionResult(
      eui: result['eui']?.toString() ?? eui,
      localDeviceId: result['localDeviceId']?.toString() ?? '',
      deviceCode: result['deviceCode']?.toString() ?? '',
      deviceStatus: result['deviceStatus']?.toString() ?? '',
      bindingStatus: result['bindingStatus']?.toString() ?? '',
      livestockId: result['livestockId']?.toString(),
      installationCreated: result['installationCreated'] == true,
      deviceType: result['deviceType']?.toString(),
      firstTelemetryTrigger: data['firstTelemetryTrigger']?.toString() ?? '',
    );
  }

  static int? _parseNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  // Test-only accessors for private parsing methods
  static DeviceItem? parseDeviceItemForTest(Map<String, dynamic> m) =>
      _parseDeviceItem(m);
  static DeviceLicense parseLicenseForTest(Map<String, dynamic> m) =>
      _parseLicense(m);
  static Installation parseInstallationForTest(Map<String, dynamic> m) =>
      _parseInstallation(m);
  static GpsPoint parseGpsPointForTest(Map<String, dynamic> m) =>
      _parseGpsPoint(m);

  static TbDevicePreflight parseTbPreflightForTest(Map<String, dynamic> m) =>
      _parseTbPreflight(m);

  static TbDevicePreflight _parseTbPreflight(Map<String, dynamic> data) {
    final ns = _optionalMap(data['nsDevice']);
    final candidatesRaw = data['tbCandidates'];
    final candidates = candidatesRaw is List
        ? candidatesRaw
            .whereType<Map<String, dynamic>>()
            .map(_parseTbCandidate)
            .toList()
        : <TbDeviceCandidate>[];
    return TbDevicePreflight(
      eui: data['eui']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      nsProjectId: _parseNullableInt(ns?['projectId']),
      nsAppId: _parseNullableInt(ns?['appId']),
      candidates: candidates,
      latestTelemetryAt: data['latestTelemetryAt']?.toString(),
      localDeviceId: data['localDeviceId']?.toString(),
      localDeviceCode: data['localDeviceCode']?.toString(),
      bindingStatus: data['bindingStatus']?.toString(),
      activeInstallation: data['activeInstallation'] == true,
    );
  }

  static TbDeviceCandidate _parseTbCandidate(Map<String, dynamic> data) {
    return TbDeviceCandidate(
      tbDeviceId: data['tbDeviceId']?.toString() ?? '',
      tbDeviceName: data['tbDeviceName']?.toString() ?? '',
      profileId: data['profileId']?.toString() ?? '',
      profileName: data['profileName']?.toString() ?? '',
      deviceType: data['deviceType']?.toString(),
      profileValid: data['profileValid'] == true,
    );
  }

  static Map<String, dynamic>? _optionalMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  static Map<String, dynamic> _requiredMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw FormatException('Expected object: $value');
  }
}
