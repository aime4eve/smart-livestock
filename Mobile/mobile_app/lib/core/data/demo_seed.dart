import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';

class DemoSeed {
  const DemoSeed._();

  static const List<String> earTags = ['耳标-001', '耳标-002', '耳标-003'];

  // Mock GPS center: 长沙市 (28.2282, 112.9388)
  static const LatLng mapCenter = LatLng(28.2282, 112.9388);
  static const double defaultZoom = 13.0;

  // 轨迹点 — 模拟长沙望城区牧场周边
  static const List<GeoPoint> trajectoryPoints = [
    GeoPoint(lat: 28.2280, lng: 112.9380, timestamp: '2026-03-30T08:00:00'),
    GeoPoint(lat: 28.2288, lng: 112.9385, timestamp: '2026-03-30T08:15:00'),
    GeoPoint(lat: 28.2295, lng: 112.9390, timestamp: '2026-03-30T08:30:00'),
    GeoPoint(lat: 28.2300, lng: 112.9398, timestamp: '2026-03-30T08:45:00'),
    GeoPoint(lat: 28.2305, lng: 112.9405, timestamp: '2026-03-30T09:00:00'),
    GeoPoint(lat: 28.2298, lng: 112.9410, timestamp: '2026-03-30T09:15:00'),
    GeoPoint(lat: 28.2290, lng: 112.9400, timestamp: '2026-03-30T09:30:00'),
    GeoPoint(lat: 28.2285, lng: 112.9392, timestamp: '2026-03-30T09:45:00'),
    GeoPoint(lat: 28.2282, lng: 112.9385, timestamp: '2026-03-30T10:00:00'),
    GeoPoint(lat: 28.2288, lng: 112.9378, timestamp: '2026-03-30T10:15:00'),
    GeoPoint(lat: 28.2295, lng: 112.9370, timestamp: '2026-03-30T10:30:00'),
    GeoPoint(lat: 28.2302, lng: 112.9375, timestamp: '2026-03-30T10:45:00'),
  ];

  // 牲畜当前 GPS 位置
  static const List<GeoPoint> livestockLocations = [
    GeoPoint(lat: 28.2282, lng: 112.9385, timestamp: '2026-03-30T10:00:00'),
    GeoPoint(lat: 28.2302, lng: 112.9375, timestamp: '2026-03-30T10:45:00'),
    GeoPoint(lat: 28.2260, lng: 112.9410, timestamp: '2026-03-30T10:30:00'),
  ];

  // 围栏区域 — 长沙望城牧场
  static const List<FencePolygon> fencePolygons = [
    FencePolygon(
      id: 'fence_001',
      name: '北区围栏',
      points: [
        LatLng(28.2310, 112.9360),
        LatLng(28.2310, 112.9430),
        LatLng(28.2260, 112.9430),
        LatLng(28.2260, 112.9360),
      ],
      colorValue: 0xFF4C9A5F,
    ),
    FencePolygon(
      id: 'fence_002',
      name: '河谷育肥区',
      points: [
        LatLng(28.2330, 112.9320),
        LatLng(28.2350, 112.9350),
        LatLng(28.2320, 112.9360),
      ],
      colorValue: 0xFF2F6B3B,
    ),
  ];

  static const List<DashboardMetric> dashboardMetrics = [
    DashboardMetric(
      widgetKey: 'dashboard-metric-animal-total',
      title: '牲畜总数',
      value: '128',
    ),
    DashboardMetric(
      widgetKey: 'dashboard-metric-device-online',
      title: '在线设备',
      value: '96',
    ),
    DashboardMetric(
      widgetKey: 'dashboard-metric-alert-pending',
      title: '未处理告警',
      value: '7',
    ),
    DashboardMetric(
      widgetKey: 'dashboard-metric-health-watch',
      title: '健康关注',
      value: '12',
    ),
  ];

  static const livestockDetail = LivestockDetail(
    earTag: '耳标-001',
    breed: '西门塔尔牛',
    ageMonths: 36,
    weightKg: 520.0,
    health: LivestockHealth.healthy,
    devices: [
      DeviceItem(
        id: 'dev-gps-001',
        name: 'GPS项圈-001',
        type: DeviceType.gps,
        status: DeviceStatus.online,
        boundEarTag: '耳标-001',
        batteryPercent: 85,
        signalStrength: '强',
        lastSync: '2 分钟前',
      ),
      DeviceItem(
        id: 'dev-rumen-001',
        name: '瘤胃胶囊-001',
        type: DeviceType.rumenCapsule,
        status: DeviceStatus.online,
        boundEarTag: '耳标-001',
        batteryPercent: 92,
        signalStrength: '中',
        lastSync: '5 分钟前',
      ),
    ],
    bodyTemp: 38.6,
    activityLevel: '正常（步数 2,340）',
    ruminationFreq: '正常（每日 8.2 小时）',
    lastLocation: '北区围栏 · 东坡草地',
  );

  static const livestockDetailWatch = LivestockDetail(
    earTag: '耳标-002',
    breed: '安格斯牛',
    ageMonths: 24,
    weightKg: 410.0,
    health: LivestockHealth.watch,
    devices: [
      DeviceItem(
        id: 'dev-gps-002',
        name: 'GPS项圈-002',
        type: DeviceType.gps,
        status: DeviceStatus.lowBattery,
        boundEarTag: '耳标-002',
        batteryPercent: 12,
        signalStrength: '弱',
        lastSync: '18 分钟前',
      ),
    ],
    bodyTemp: 39.8,
    activityLevel: '偏低（步数 890）',
    ruminationFreq: '偏低（每日 5.1 小时）',
    lastLocation: '南区围栏 · 河谷附近',
  );

  static const List<DeviceItem> devices = [
    DeviceItem(
      id: 'dev-gps-001',
      name: 'GPS项圈-001',
      type: DeviceType.gps,
      status: DeviceStatus.online,
      boundEarTag: '耳标-001',
      batteryPercent: 85,
      signalStrength: '强',
      lastSync: '2 分钟前',
    ),
    DeviceItem(
      id: 'dev-gps-002',
      name: 'GPS项圈-002',
      type: DeviceType.gps,
      status: DeviceStatus.lowBattery,
      boundEarTag: '耳标-002',
      batteryPercent: 12,
      signalStrength: '弱',
      lastSync: '18 分钟前',
    ),
    DeviceItem(
      id: 'dev-rumen-001',
      name: '瘤胃胶囊-001',
      type: DeviceType.rumenCapsule,
      status: DeviceStatus.online,
      boundEarTag: '耳标-001',
      batteryPercent: 92,
      signalStrength: '中',
      lastSync: '5 分钟前',
    ),
    DeviceItem(
      id: 'dev-gps-003',
      name: 'GPS项圈-003',
      type: DeviceType.gps,
      status: DeviceStatus.offline,
      boundEarTag: '耳标-023',
      signalStrength: '无',
      lastSync: '3 小时前',
    ),
    DeviceItem(
      id: 'dev-acc-001',
      name: '加速度计-001',
      type: DeviceType.accelerometer,
      status: DeviceStatus.online,
      boundEarTag: '耳标-001',
      batteryPercent: 78,
      signalStrength: '强',
      lastSync: '1 分钟前',
    ),
  ];

  static const healthSummary = StatsHealthSummary(
    healthyCount: 108,
    watchCount: 12,
    abnormalCount: 8,
  );

  static const alertSummary = StatsAlertSummary(
    fenceBreachCount: 12,
    batteryLowCount: 5,
    signalLostCount: 3,
    dailyTrend: [
      StatsChartData(label: '周一', value: 3, color: 0xFF4C9A5F),
      StatsChartData(label: '周二', value: 5, color: 0xFF4C9A5F),
      StatsChartData(label: '周三', value: 2, color: 0xFF4C9A5F),
      StatsChartData(label: '周四', value: 7, color: 0xFFD28A2D),
      StatsChartData(label: '周五', value: 4, color: 0xFF4C9A5F),
      StatsChartData(label: '周六', value: 1, color: 0xFF4C9A5F),
      StatsChartData(label: '周日', value: 3, color: 0xFF4C9A5F),
    ],
  );

  static const deviceSummary = StatsDeviceSummary(
    totalDevices: 96,
    onlineCount: 91,
    weeklyOnlineRate: 94.2,
    weeklyTrend: [
      StatsChartData(label: '周一', value: 95.0, color: 0xFF2F6B3B),
      StatsChartData(label: '周二', value: 93.5, color: 0xFF2F6B3B),
      StatsChartData(label: '周三', value: 94.8, color: 0xFF2F6B3B),
      StatsChartData(label: '周四', value: 92.1, color: 0xFF2F6B3B),
      StatsChartData(label: '周五', value: 96.0, color: 0xFF2F6B3B),
      StatsChartData(label: '周六', value: 94.5, color: 0xFF2F6B3B),
      StatsChartData(label: '周日', value: 93.8, color: 0xFF2F6B3B),
    ],
  );
}
