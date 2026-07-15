import 'package:latlong2/latlong.dart';

enum TrajectoryRange {
  h24,
  d7,
  d30,
}

class GeoPoint {
  const GeoPoint({required this.lat, required this.lng, required this.timestamp});
  final double lat;
  final double lng;
  final String timestamp;

  LatLng toLatLng() => LatLng(lat, lng);
}

class FencePolygon {
  const FencePolygon({
    required this.id,
    required this.name,
    required this.points,
    required this.colorValue,
    this.type = 'polygon',
    this.alarmEnabled = true,
    this.active = true,
    this.areaHectares = 1.0,
  });

  final String id;
  final String name;
  final List<LatLng> points;
  final int colorValue;
  final String type;
  final bool alarmEnabled;
  final bool active;
  final double areaHectares;
}

class DashboardMetric {
  const DashboardMetric({
    required this.widgetKey,
    required this.title,
    required this.value,
  });

  final String widgetKey;
  final String title;
  final String value;
}

enum LivestockHealth { healthy, watch, abnormal }

enum Breed {
  angus,
  wagyu,
  simmental,
  limousin,
  other;

  /// Parse from API string code (e.g. 'ANGUS', 'Simmental', '安格斯').
  static Breed fromString(String? raw) {
    if (raw == null) return Breed.other;
    final code = raw.toUpperCase();
    const map = {
      'ANGUS': Breed.angus,
      'WAGYU': Breed.wagyu,
      'SIMMENTAL': Breed.simmental,
      'LIMOUSIN': Breed.limousin,
    };
    return map[code] ?? Breed.other;
  }
}

class LivestockInfo {
  const LivestockInfo({
    required this.livestockCode,
    required this.livestockId,
    required this.breed,
    required this.ageMonths,
    required this.weightKg,
    required this.health,
    required this.fenceId,
    required this.lat,
    required this.lng,
  });

  final String livestockCode;
  final String livestockId;
  final Breed breed;
  final int ageMonths;
  final double weightKg;
  final LivestockHealth health;
  final String fenceId;
  final double lat;
  final double lng;
}

class LivestockDetail {
  const LivestockDetail({
    required this.livestockCode,
    required this.livestockId,
    required this.breed,
    required this.ageMonths,
    required this.weightKg,
    required this.health,
    required this.fenceId,
    required this.devices,
    required this.bodyTemp,
    required this.activityLevel,
    required this.ruminationFreq,
    required this.lastLocation,
    this.gender,
    this.birthDate,
  });

  final String livestockCode;
  final String livestockId;
  final Breed breed;
  final int ageMonths;
  final double weightKg;
  final LivestockHealth health;
  final String fenceId;
  final List<DeviceItem> devices;
  final double bodyTemp;
  final String activityLevel;
  final String ruminationFreq;
  final String lastLocation;
  final String? gender;
  final DateTime? birthDate;
}

enum DeviceType { gps, rumenCapsule, earTag }

enum DeviceStatus { online, offline }

class DeviceItem {
  const DeviceItem({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.boundLivestockCode,
    this.batteryPercent,
    this.signalStrength,
    this.lastSync,
    this.platformDeviceId,
    this.rssi,
    this.snr,
    this.lastGateway,
    this.antiDisassemblyStatus,
    this.lastTelemetrySyncedAt,
   this.devEui,
   this.runtimeStatus,
   this.softwareVersion,
   this.hardwareVersion,
   this.deviceTypeName,
   this.lifecycleStatus,
 });

  final String id;
  final String name;
  final DeviceType type;
  final DeviceStatus status;
  final String boundLivestockCode;
  final int? batteryPercent;
  final String? signalStrength;
  final String? lastSync;
  final String? platformDeviceId;
  final int? rssi;
  final String? snr;
  final String? lastGateway;
  final int? antiDisassemblyStatus;
  final String? lastTelemetrySyncedAt;
  final String? devEui;
  final String? runtimeStatus;
 final String? softwareVersion;
 final String? hardwareVersion;
 final String? deviceTypeName;
 final String? lifecycleStatus;

 bool get isPlatformRegistered => platformDeviceId != null;
 bool get hasTamperAlert => antiDisassemblyStatus != null && antiDisassemblyStatus != 0;
 bool get isActivated => lifecycleStatus == null || lifecycleStatus!.toUpperCase() == 'ACTIVE';

 DeviceItem copyWith({
    String? boundLivestockCode,
    int? batteryPercent,
    int? rssi,
    String? platformDeviceId,
  }) {
    return DeviceItem(
      id: id,
      name: name,
      type: type,
      status: status,
      boundLivestockCode: boundLivestockCode ?? this.boundLivestockCode,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      signalStrength: signalStrength,
      lastSync: lastSync,
      platformDeviceId: platformDeviceId ?? this.platformDeviceId,
      rssi: rssi ?? this.rssi,
      snr: snr,
      lastGateway: lastGateway,
      antiDisassemblyStatus: antiDisassemblyStatus,
      lastTelemetrySyncedAt: lastTelemetrySyncedAt,
      devEui: devEui,
      runtimeStatus: runtimeStatus,
      softwareVersion: softwareVersion,
      hardwareVersion: hardwareVersion,
      deviceTypeName: deviceTypeName,
      lifecycleStatus: lifecycleStatus,
    );
  }
}

class StatsChartData {
  const StatsChartData({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final int color;
}

class StatsHealthSummary {
  const StatsHealthSummary({
    required this.healthyCount,
    required this.watchCount,
    required this.abnormalCount,
  });

  final int healthyCount;
  final int watchCount;
  final int abnormalCount;
}

class StatsAlertSummary {
  const StatsAlertSummary({
    required this.fenceBreachCount,
    required this.signalLostCount,
    required this.dailyTrend,
  });

  final int fenceBreachCount;
  final int signalLostCount;
  final List<StatsChartData> dailyTrend;
}

class StatsDeviceSummary {
  const StatsDeviceSummary({
    required this.totalDevices,
    required this.onlineCount,
    required this.weeklyOnlineRate,
    required this.weeklyTrend,
  });

  final int totalDevices;
  final int onlineCount;
  final double weeklyOnlineRate;
  final List<StatsChartData> weeklyTrend;
}

enum StatsTimeRange { d7, d30 }

class AlertItem {
  const AlertItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priority,
    required this.type,
    required this.stage,
   required this.livestockCode,
   this.livestockId,
   this.source = 'RULE',
 });

 final String id;
  final String title;
  final String subtitle;
  final String priority;
  final String type;
 final String stage;
  final String livestockCode;
final String? livestockId;
 final String source; // RULE / AI
}
