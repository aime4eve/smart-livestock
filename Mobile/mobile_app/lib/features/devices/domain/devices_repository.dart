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

abstract class DevicesRepository {
  Future<DevicesListData> loadDevices({
    int page = 1,
    int pageSize = 20,
  });

  Future<DeviceItem> loadDetail(String id);

  Future<DeviceItem> create(Map<String, dynamic> body);

  Future<DeviceItem> update(String id, Map<String, dynamic> body);

  Future<void> activate(String id);

  Future<void> decommission(String id);

  Future<List<DeviceLicense>> loadLicenses();

  Future<List<Installation>> loadInstallations();

  Future<List<GpsPoint>> loadLatestGps();

  Future<List<GpsPoint>> loadGpsHistory(String livestockId);
}
