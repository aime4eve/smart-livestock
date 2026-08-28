import 'package:hkt_livestock_agentic/core/models/core_models.dart';

class DevicesListData {
  const DevicesListData({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<DeviceItem> items;
  final int total;
  final int page;
  final int pageSize;
}

class DeviceLicense {
  const DeviceLicense({
    required this.id,
    required this.deviceId,
    required this.licenseKey,
    required this.status,
  });

  final String id;
  final String deviceId;
  final String licenseKey;
  final String status;
}

class Installation {
  const Installation({
    required this.id,
    required this.deviceId,
    required this.livestockId,
    required this.installedAt,
  });

  final String id;
  final String deviceId;
  final String livestockId;
  final String installedAt;
}

class GpsPoint {
  const GpsPoint({
    required this.lat,
    required this.lng,
    required this.timestamp,
    this.livestockId,
  });

  final double lat;
  final double lng;
  final String timestamp;
  final String? livestockId;
}

class TbDeviceCandidate {
  const TbDeviceCandidate({
    required this.tbDeviceId,
    required this.tbDeviceName,
    required this.profileId,
    required this.profileName,
    required this.deviceType,
    required this.profileValid,
  });

  final String tbDeviceId;
  final String tbDeviceName;
  final String profileId;
  final String profileName;
  final String? deviceType;
  final bool profileValid;
}

class TbDevicePreflight {
  const TbDevicePreflight({
    required this.eui,
    required this.status,
    required this.nsProjectId,
    required this.nsAppId,
    required this.candidates,
    required this.latestTelemetryAt,
    required this.localDeviceId,
    required this.localDeviceCode,
    required this.bindingStatus,
    required this.activeInstallation,
  });

  final String eui;
  final String status;
  final int? nsProjectId;
  final int? nsAppId;
  final List<TbDeviceCandidate> candidates;
  final String? latestTelemetryAt;
  final String? localDeviceId;
  final String? localDeviceCode;
  final String? bindingStatus;
  final bool activeInstallation;

  TbDeviceCandidate? get selectedCandidate =>
      candidates.length == 1 ? candidates.first : null;

  bool get canProvision =>
      selectedCandidate != null && selectedCandidate!.profileValid;
}

class TbDeviceProvisionResult {
  const TbDeviceProvisionResult({
    required this.eui,
    required this.localDeviceId,
    required this.deviceCode,
    required this.deviceStatus,
    required this.bindingStatus,
    required this.livestockId,
    required this.installationCreated,
    required this.deviceType,
    required this.firstTelemetryTrigger,
  });

  final String eui;
  final String localDeviceId;
  final String deviceCode;
  final String deviceStatus;
  final String bindingStatus;
  final String? livestockId;
  final bool installationCreated;
  final String? deviceType;
  final String firstTelemetryTrigger;
}

abstract class DevicesRepository {
  Future<DevicesListData> loadDevices({
    int page = 1,
    int pageSize = 20,
    String? keyword,
  });

  Future<DeviceItem> loadDetail(String id);

  Future<DeviceItem> create(Map<String, dynamic> body);

  Future<DeviceItem> update(String id, Map<String, dynamic> body);

  Future<void> activate(String id);

  Future<void> decommission(String id);

  Future<void> delete(String id);

  Future<List<DeviceLicense>> loadLicenses();

  Future<List<Installation>> loadInstallations();

  Future<List<GpsPoint>> loadLatestGps();

  Future<List<GpsPoint>> loadGpsHistory(String livestockId);

  Future<Map<String, dynamic>> loadDeviceHealth(String deviceId);

  Future<TbDevicePreflight> preflightTbDevice(String eui);

  Future<TbDeviceProvisionResult> provisionTbDevice({
    required String eui,
    String? deviceCode,
    String? deviceType,
    String? livestockId,
  });
}
