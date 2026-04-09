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
  const FencePolygon({required this.id, required this.name, required this.points, required this.colorValue});
  final String id;
  final String name;
  final List<LatLng> points;
  final int colorValue;
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

class LivestockDetail {
  const LivestockDetail({
    required this.earTag,
    required this.breed,
    required this.ageMonths,
    required this.weightKg,
    required this.health,
    required this.devices,
    required this.bodyTemp,
    required this.activityLevel,
    required this.ruminationFreq,
    required this.lastLocation,
  });

  final String earTag;
  final String breed;
  final int ageMonths;
  final double weightKg;
  final LivestockHealth health;
  final List<DeviceItem> devices;
  final double bodyTemp;
  final String activityLevel;
  final String ruminationFreq;
  final String lastLocation;
}

enum DeviceType { gps, rumenCapsule, accelerometer }

enum DeviceStatus { online, offline, lowBattery }

class DeviceItem {
  const DeviceItem({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.boundEarTag,
    this.batteryPercent,
    this.signalStrength,
    this.lastSync,
  });

  final String id;
  final String name;
  final DeviceType type;
  final DeviceStatus status;
  final String boundEarTag;
  final int? batteryPercent;
  final String? signalStrength;
  final String? lastSync;
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
    required this.batteryLowCount,
    required this.signalLostCount,
    required this.dailyTrend,
  });

  final int fenceBreachCount;
  final int batteryLowCount;
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
