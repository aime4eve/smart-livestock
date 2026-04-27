import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';

class DemoSeed {
  const DemoSeed._();

  static const LatLng mapCenter = LatLng(28.2282, 112.9388);
  static const double defaultZoom = 14.0;

  static const List<GeoPoint> trajectoryPoints = [];

  // Anchor points represent water troughs, feeding stations, and salt licks.
  // During feeding hours (6-8, 17-19) cattle move toward these and stay nearby.
  static const List<LatLng> gpsAnchorPoints = [
    LatLng(28.2336, 112.9435), // 放牧A区 — 饮水点
    LatLng(28.2312, 112.9409), // 放牧A区 — 喂食站
    LatLng(28.2268, 112.9342), // 放牧B区 — 饮水点
    LatLng(28.2254, 112.9357), // 放牧B区 — 喂食站
    LatLng(28.2332, 112.9415), // 放牧A区 — 盐砖
    LatLng(28.2250, 112.9330), // 放牧B区 — 盐砖
  ];

  static const List<FencePolygon> fencePolygons = [
    FencePolygon(
      id: 'fence_pasture_a',
      name: '放牧A区',
      points: [
        LatLng(28.2340, 112.9400),
        LatLng(28.2340, 112.9440),
        LatLng(28.2305, 112.9440),
        LatLng(28.2305, 112.9400),
      ],
      colorValue: 0xFF4C9A5F,
      type: 'rectangle',
      areaHectares: 15.2,
    ),
    FencePolygon(
      id: 'fence_pasture_b',
      name: '放牧B区',
      points: [
        LatLng(28.2275, 112.9320),
        LatLng(28.2275, 112.9360),
        LatLng(28.2240, 112.9360),
        LatLng(28.2240, 112.9320),
      ],
      colorValue: 0xFF2F6B3B,
      type: 'rectangle',
      areaHectares: 14.8,
    ),
    FencePolygon(
      id: 'fence_rest',
      name: '夜间休息区',
      points: [
        LatLng(28.2295, 112.9380),
        LatLng(28.2295, 112.9400),
        LatLng(28.2280, 112.9400),
        LatLng(28.2280, 112.9380),
      ],
      colorValue: 0xFFD28A2D,
      type: 'rectangle',
      areaHectares: 3.5,
    ),
    FencePolygon(
      id: 'fence_quarantine',
      name: '隔离区',
      points: [
        LatLng(28.2255, 112.9400),
        LatLng(28.2255, 112.9410),
        LatLng(28.2248, 112.9410),
        LatLng(28.2248, 112.9400),
      ],
      colorValue: 0xFFB84040,
      type: 'rectangle',
      areaHectares: 0.8,
    ),
  ];

  static final List<LivestockInfo> livestock = _generateLivestock();

  static List<LatLng> fencePointsById(String fenceId) {
    for (final fence in fencePolygons) {
      if (fence.id == fenceId) {
        return fence.points;
      }
    }
    return const [];
  }

  static List<String> get earTags =>
      livestock.map((l) => l.earTag).toList();

  static List<GeoPoint> get livestockLocations => livestock
      .map((l) => GeoPoint(
            lat: l.lat,
            lng: l.lng,
            timestamp: '2026-04-08T10:00:00',
          ))
      .toList();

  static Map<String, String> get earTagToLivestockId => {
        for (final l in livestock) l.earTag: l.livestockId,
      };

  static LivestockDetail? getLivestockDetail(String earTag) {
    LivestockInfo? info;
    for (final l in livestock) {
      if (l.earTag == earTag) {
        info = l;
        break;
      }
    }
    if (info == null) return null;

    final boundDevices =
        devices.where((d) => d.boundEarTag == earTag).toList();

    String fenceName = '';
    for (final f in fencePolygons) {
      if (f.id == info.fenceId) {
        fenceName = f.name;
        break;
      }
    }

    final tempByHealth = switch (info.health) {
      LivestockHealth.healthy =>
        38.3 + Random(info.earTag.hashCode).nextDouble() * 0.6,
      LivestockHealth.watch =>
        39.2 + Random(info.earTag.hashCode).nextDouble() * 0.4,
      LivestockHealth.abnormal =>
        39.8 + Random(info.earTag.hashCode).nextDouble() * 0.5,
    };

    return LivestockDetail(
      earTag: info.earTag,
      livestockId: info.livestockId,
      breed: info.breed,
      ageMonths: info.ageMonths,
      weightKg: info.weightKg,
      health: info.health,
      fenceId: info.fenceId,
      devices: boundDevices,
      bodyTemp: double.parse(tempByHealth.toStringAsFixed(1)),
      activityLevel: switch (info.health) {
        LivestockHealth.healthy =>
          '正常（步数 ${1800 + Random(info.earTag.hashCode).nextInt(1200)}）',
        LivestockHealth.watch =>
          '偏低（步数 ${600 + Random(info.earTag.hashCode).nextInt(400)}）',
        LivestockHealth.abnormal =>
          '异常（步数 ${200 + Random(info.earTag.hashCode).nextInt(300)}）',
      },
      ruminationFreq: switch (info.health) {
        LivestockHealth.healthy =>
          '正常（每日 ${(7.5 + Random(info.earTag.hashCode).nextDouble() * 1.5).toStringAsFixed(1)} 小时）',
        LivestockHealth.watch =>
          '偏低（每日 ${(4.5 + Random(info.earTag.hashCode).nextDouble() * 1.0).toStringAsFixed(1)} 小时）',
        LivestockHealth.abnormal =>
          '异常（每日 ${(2.0 + Random(info.earTag.hashCode).nextDouble() * 1.0).toStringAsFixed(1)} 小时）',
      },
      lastLocation: '$fenceName · 区域${1 + Random(info.earTag.hashCode).nextInt(3)}',
    );
  }

  static final List<DeviceItem> devices = _generateDevices();

  static final List<AlertItem> alerts = [
    const AlertItem(id: 'alert-001', title: '越界 · SL-2024-003', subtitle: '2026-04-08 14:23', priority: 'P0', type: 'geofence', stage: 'pending', earTag: 'SL-2024-003'),
    const AlertItem(id: 'alert-002', title: '体温异常 · SL-2024-048', subtitle: '2026-04-08 11:05', priority: 'P0', type: 'fever', stage: 'acknowledged', earTag: 'SL-2024-048', livestockId: '0048'),
    const AlertItem(id: 'alert-003', title: '越界 · SL-2024-017', subtitle: '2026-04-07 16:30', priority: 'P0', type: 'geofence', stage: 'handled', earTag: 'SL-2024-017'),
    const AlertItem(id: 'alert-004', title: '体温异常 · SL-2024-049', subtitle: '2026-04-07 09:15', priority: 'P0', type: 'fever', stage: 'handled', earTag: 'SL-2024-049', livestockId: '0049'),
    const AlertItem(id: 'alert-005', title: '设备离线 · SL-2024-043', subtitle: '2026-04-08 13:40', priority: 'P1', type: 'offline', stage: 'pending', earTag: 'SL-2024-043'),
    const AlertItem(id: 'alert-006', title: '低电量 · SL-2024-045', subtitle: '2026-04-08 12:20', priority: 'P1', type: 'lowbattery', stage: 'pending', earTag: 'SL-2024-045'),
    const AlertItem(id: 'alert-007', title: '设备离线 · SL-2024-044', subtitle: '2026-04-08 08:50', priority: 'P1', type: 'offline', stage: 'acknowledged', earTag: 'SL-2024-044'),
    const AlertItem(id: 'alert-008', title: '低电量 · SL-2024-046', subtitle: '2026-04-07 15:10', priority: 'P1', type: 'lowbattery', stage: 'handled', earTag: 'SL-2024-046'),
    const AlertItem(id: 'alert-009', title: '设备离线 · SL-2024-042', subtitle: '2026-04-07 10:25', priority: 'P1', type: 'offline', stage: 'handled', earTag: 'SL-2024-042'),
    const AlertItem(id: 'alert-010', title: '行为异常 · SL-2024-047', subtitle: '2026-04-08 09:30', priority: 'P2', type: 'behavior', stage: 'pending', earTag: 'SL-2024-047', livestockId: '0047'),
    const AlertItem(id: 'alert-011', title: '围栏接近 · SL-2024-012', subtitle: '2026-04-07 14:50', priority: 'P2', type: 'geofence', stage: 'handled', earTag: 'SL-2024-012'),
    const AlertItem(id: 'alert-012', title: '行为异常 · SL-2024-050', subtitle: '2026-04-07 11:35', priority: 'P2', type: 'behavior', stage: 'handled', earTag: 'SL-2024-050', livestockId: '0050'),
    const AlertItem(id: 'alert-013', title: '围栏接近 · SL-2024-008', subtitle: '2026-04-06 16:45', priority: 'P2', type: 'geofence', stage: 'handled', earTag: 'SL-2024-008'),
    const AlertItem(id: 'alert-014', title: '行为异常 · SL-2024-030', subtitle: '2026-04-06 10:00', priority: 'P2', type: 'behavior', stage: 'archived', earTag: 'SL-2024-030', livestockId: '0030'),
    const AlertItem(id: 'alert-015', title: '越界 · SL-2024-005', subtitle: '2026-04-05 09:10', priority: 'P0', type: 'geofence', stage: 'archived', earTag: 'SL-2024-005'),
    const AlertItem(id: 'alert-016', title: '设备离线 · SL-2024-041', subtitle: '2026-04-04 14:30', priority: 'P1', type: 'offline', stage: 'archived', earTag: 'SL-2024-041'),
    const AlertItem(id: 'alert-017', title: '低电量 · SL-2024-047', subtitle: '2026-04-03 11:20', priority: 'P1', type: 'lowbattery', stage: 'archived', earTag: 'SL-2024-047'),
    const AlertItem(id: 'alert-018', title: '体温异常 · SL-2024-050', subtitle: '2026-04-02 08:00', priority: 'P0', type: 'fever', stage: 'archived', earTag: 'SL-2024-050', livestockId: '0050'),
  ];

  static const List<DashboardMetric> dashboardMetrics = [
    DashboardMetric(widgetKey: 'dashboard-metric-animal-total', title: '牲畜总数', value: '50'),
    DashboardMetric(widgetKey: 'dashboard-metric-device-online', title: '在线设备', value: '85'),
    DashboardMetric(widgetKey: 'dashboard-metric-alert-today', title: '今日告警', value: '8'),
    DashboardMetric(widgetKey: 'dashboard-metric-health-rate', title: '健康率', value: '92%'),
  ];

  static const healthSummary = StatsHealthSummary(
    healthyCount: 43,
    watchCount: 4,
    abnormalCount: 3,
  );

  static const alertSummary = StatsAlertSummary(
    fenceBreachCount: 4,
    batteryLowCount: 3,
    signalLostCount: 3,
    dailyTrend: [
      StatsChartData(label: '周一', value: 2.0, color: 0xFF4C9A5F),
      StatsChartData(label: '周二', value: 3.0, color: 0xFF4C9A5F),
      StatsChartData(label: '周三', value: 1.0, color: 0xFF4C9A5F),
      StatsChartData(label: '周四', value: 4.0, color: 0xFFD28A2D),
      StatsChartData(label: '周五', value: 3.0, color: 0xFF4C9A5F),
      StatsChartData(label: '周六', value: 2.0, color: 0xFF4C9A5F),
      StatsChartData(label: '周日', value: 3.0, color: 0xFF4C9A5F),
    ],
  );

  static const deviceSummary = StatsDeviceSummary(
    totalDevices: 100,
    onlineCount: 85,
    weeklyOnlineRate: 85.0,
    weeklyTrend: [
      StatsChartData(label: '周一', value: 87.0, color: 0xFF2F6B3B),
      StatsChartData(label: '周二', value: 84.5, color: 0xFF2F6B3B),
      StatsChartData(label: '周三', value: 86.0, color: 0xFF2F6B3B),
      StatsChartData(label: '周四', value: 83.0, color: 0xFF2F6B3B),
      StatsChartData(label: '周五', value: 85.5, color: 0xFF2F6B3B),
      StatsChartData(label: '周六', value: 86.0, color: 0xFF2F6B3B),
      StatsChartData(label: '周日', value: 84.0, color: 0xFF2F6B3B),
    ],
  );

  static List<LivestockInfo> _generateLivestock() {
    final rng = Random(42);
    final result = <LivestockInfo>[];

    const breeds = ['西门塔尔牛', '安格斯牛', '利木赞牛'];
    final breedWeightRanges = [
      (450.0, 650.0),
      (400.0, 550.0),
      (350.0, 500.0),
    ];
    var breedCounts = [20, 15, 15];
    var breedIdx = 0;

    void addCattle(
      int count,
      String fenceId,
      LivestockHealth health,
      double latMin,
      double latMax,
      double lngMin,
      double lngMax,
    ) {
      for (var i = 0; i < count; i++) {
        final n = result.length + 1;
        while (breedCounts[breedIdx] <= 0) {
          breedIdx++;
        }
        breedCounts[breedIdx]--;

        final wRange = breedWeightRanges[breedIdx];
        result.add(LivestockInfo(
          earTag: 'SL-2024-${n.toString().padLeft(3, '0')}',
          livestockId: n.toString().padLeft(4, '0'),
          breed: breeds[breedIdx],
          ageMonths: 18 + rng.nextInt(55),
          weightKg: double.parse(
            (wRange.$1 + rng.nextDouble() * (wRange.$2 - wRange.$1))
                .toStringAsFixed(1),
          ),
          health: health,
          fenceId: fenceId,
          lat: double.parse(
            (latMin + rng.nextDouble() * (latMax - latMin))
                .toStringAsFixed(4),
          ),
          lng: double.parse(
            (lngMin + rng.nextDouble() * (lngMax - lngMin))
                .toStringAsFixed(4),
          ),
        ));
      }
    }

    addCattle(25, 'fence_pasture_a', LivestockHealth.healthy,
        28.2305, 28.2340, 112.9400, 112.9440);
    addCattle(18, 'fence_pasture_b', LivestockHealth.healthy,
        28.2240, 28.2275, 112.9320, 112.9360);
    addCattle(4, 'fence_rest', LivestockHealth.watch,
        28.2280, 28.2295, 112.9380, 112.9400);
    addCattle(3, 'fence_quarantine', LivestockHealth.abnormal,
        28.2248, 28.2255, 112.9400, 112.9410);

    return result;
  }

  static List<DeviceItem> _generateDevices() {
    final result = <DeviceItem>[];

    void addBatch(
      int count,
      String idPrefix,
      DeviceType type,
      String namePrefix,
      int onlineCount,
      int offlineCount,
      int lowBatteryCount,
    ) {
      for (var i = 1; i <= count; i++) {
        final id = '$idPrefix-${i.toString().padLeft(3, '0')}';
        final name = '$namePrefix-${i.toString().padLeft(3, '0')}';
        final earTag = 'SL-2024-${i.toString().padLeft(3, '0')}';

        DeviceStatus status;
        if (i <= onlineCount) {
          status = DeviceStatus.online;
        } else if (i <= onlineCount + offlineCount) {
          status = DeviceStatus.offline;
        } else {
          status = DeviceStatus.lowBattery;
        }

        result.add(DeviceItem(
          id: id,
          name: name,
          type: type,
          status: status,
          boundEarTag: earTag,
          batteryPercent: switch (status) {
            DeviceStatus.online => 60 + (i * 3 % 35),
            DeviceStatus.lowBattery => 5 + (i % 10),
            DeviceStatus.offline => null,
          },
          signalStrength: switch (status) {
            DeviceStatus.online => i % 3 == 0 ? '中' : '强',
            DeviceStatus.lowBattery => '弱',
            DeviceStatus.offline => '无',
          },
          lastSync: switch (status) {
            DeviceStatus.online => '${1 + i % 5} 分钟前',
            DeviceStatus.lowBattery => '${10 + i % 20} 分钟前',
            DeviceStatus.offline => '${1 + i % 6} 小时前',
          },
        ));
      }
    }

    addBatch(50, 'DEV-GPS', DeviceType.gps, 'GPS追踪器', 42, 4, 4);
    addBatch(30, 'DEV-RC', DeviceType.rumenCapsule, '瘤胃胶囊', 26, 2, 2);
    addBatch(20, 'DEV-ACC', DeviceType.accelerometer, '加速度计', 17, 2, 1);

    return result;
  }
}
