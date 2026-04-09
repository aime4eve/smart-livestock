# Demo 数据增强 Implementation Plan

> **实施状态（2026-04-09 复核）:** 本计划所列开发任务已在 `Mobile/mobile_app` 与 `Mobile/backend` **落地**；下列 Step 级 checkbox 已全部勾选，仅作历史记录。与初稿的偏差见 `specs/2026-04-09-demo-data-enhancement-design.md`（实现偏差、已知差异）。

> **后续迭代:** GitHub Issues [#2](https://github.com/aime4eve/smart-livestock/issues/2)–[#8](https://github.com/aime4eve/smart-livestock/issues/8) 与执行计划 `plans/2026-04-09-demo-data-followups.md` 同步。

> **For agentic workers:** 新增量开发请跟 `2026-04-09-demo-data-followups.md` 与对应 Issue，而非重复本文件步骤。

**Goal:** 将 Demo 数据从 3 头牛/2 围栏扩展到 50 头牛/4 围栏/100 设备/18 告警，并添加时序数据生成器，使演示数据达到中型牧场运营水平。

**Architecture:** 分两层——确定性层（牛只/围栏/设备/告警静态种子）和动态层（GPS/温度/蠕动/发情运行时生成器，固定种子 `Random(42)` 确保可复现）。DemoSeed 用 `List.generate` + 确定性算法生成批量数据，TwinSeed 调用生成器填充时序字段，Mock Repository 按需获取数据。

**Tech Stack:** Flutter/Dart (Riverpod), Node.js (Express 5), latlong2

---

## File Structure

### New Files

| Path (relative to `mobile_app/`) | Responsibility |
|---|---|
| `lib/core/data/generators/gps_trajectory_generator.dart` | GPS 轨迹按需生成（每牛 168 点/7 天） |
| `lib/core/data/generators/temperature_generator.dart` | 温度曲线生成（每牛 336 点/7 天） |
| `lib/core/data/generators/motility_generator.dart` | 蠕动数据生成（每牛 336 点/7 天） |
| `lib/core/data/generators/estrus_score_generator.dart` | 发情评分生成（每牛 7 点/7 天） |
| `test/seed_data_test.dart` | 种子数据一致性测试 |
| `test/generator_test.dart` | 生成器正确性测试 |

### Modified Files

| Path | Changes |
|---|---|
| `lib/core/models/demo_models.dart` | 新增 `LivestockInfo`、`AlertItem`；`LivestockDetail` 添加 `livestockId`、`fenceId` |
| `lib/core/data/demo_seed.dart` | 扩展到 50 牛、4 围栏、100 设备、18 告警、看板指标 |
| `lib/core/data/twin_seed.dart` | 30 头孪生牛基线，使用生成器产生时序数据 |
| `lib/features/alerts/domain/alerts_repository.dart` | `AlertsViewData` 增加 `List<AlertItem> items` |
| `lib/features/alerts/data/mock_alerts_repository.dart` | 返回 DemoSeed 告警列表 |
| `lib/features/map/data/mock_map_repository.dart` | 使用 GPS 生成器 + 50 牛数据 |
| `lib/features/map/data/live_map_repository.dart` | 移除硬编码 `DemoSeed.livestockLocations/trajectoryPoints` |
| `lib/features/livestock/data/mock_livestock_repository.dart` | 支持 50 头牛按 earTag 查找 |
| `test/mock_repository_state_test.dart` | earTag 格式更新 |
| `test/flow_smoke_test.dart` | earTag 格式更新 |

### Modified Backend Files (relative to `Mobile/`)

| Path | Changes |
|---|---|
| `backend/data/seed.js` | 50 牛、100 设备、4 围栏、18 告警、看板指标 |
| `backend/data/twin_seed.js` | 30 头孪生牛基线数据 |
| `backend/routes/map.js` | `range` 参数过滤轨迹 |

### Unchanged (Auto-Pick-Up New Seed Data)

These repos read from `DemoSeed`/`TwinSeed` and will automatically use new data without code changes:

`mock_dashboard_repository.dart`, `mock_stats_repository.dart`, `mock_devices_repository.dart`, `mock_fever_repository.dart`, `mock_digestive_repository.dart`, `mock_estrus_repository.dart`, `mock_twin_overview_repository.dart`

---

## Task 1: Model Extensions

**Files:**
- Modify: `lib/core/models/demo_models.dart`
- Test: `test/seed_data_test.dart`

- [x] **Step 1: Write failing test for new models**

Create `test/seed_data_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';

void main() {
  test('LivestockInfo can be constructed with all fields', () {
    const info = LivestockInfo(
      earTag: 'SL-2024-001',
      livestockId: '0001',
      breed: '西门塔尔牛',
      ageMonths: 36,
      weightKg: 520.0,
      health: LivestockHealth.healthy,
      fenceId: 'fence_pasture_a',
      lat: 28.2320,
      lng: 112.9410,
    );
    expect(info.earTag, 'SL-2024-001');
    expect(info.livestockId, '0001');
    expect(info.fenceId, 'fence_pasture_a');
  });

  test('AlertItem can be constructed with all fields', () {
    const alert = AlertItem(
      id: 'alert-001',
      title: '越界 · SL-2024-003',
      subtitle: '2026-04-08 14:23',
      priority: 'P0',
      type: 'geofence',
      stage: 'pending',
      earTag: 'SL-2024-003',
    );
    expect(alert.id, 'alert-001');
    expect(alert.priority, 'P0');
    expect(alert.livestockId, isNull);
  });

  test('LivestockDetail has livestockId and fenceId', () {
    const detail = LivestockDetail(
      earTag: 'SL-2024-001',
      livestockId: '0001',
      breed: '西门塔尔牛',
      ageMonths: 36,
      weightKg: 520.0,
      health: LivestockHealth.healthy,
      fenceId: 'fence_pasture_a',
      devices: [],
      bodyTemp: 38.6,
      activityLevel: '正常',
      ruminationFreq: '正常',
      lastLocation: '放牧A区',
    );
    expect(detail.livestockId, '0001');
    expect(detail.fenceId, 'fence_pasture_a');
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/seed_data_test.dart -v`
Expected: FAIL — `LivestockInfo` and `AlertItem` classes don't exist, `LivestockDetail` missing fields.

- [x] **Step 3: Implement model extensions**

Add to `lib/core/models/demo_models.dart` (after `LivestockHealth` enum, before `LivestockDetail`):

```dart
class LivestockInfo {
  const LivestockInfo({
    required this.earTag,
    required this.livestockId,
    required this.breed,
    required this.ageMonths,
    required this.weightKg,
    required this.health,
    required this.fenceId,
    required this.lat,
    required this.lng,
  });

  final String earTag;
  final String livestockId;
  final String breed;
  final int ageMonths;
  final double weightKg;
  final LivestockHealth health;
  final String fenceId;
  final double lat;
  final double lng;
}
```

Add after `StatsTimeRange` enum:

```dart
class AlertItem {
  const AlertItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priority,
    required this.type,
    required this.stage,
    required this.earTag,
    this.livestockId,
  });

  final String id;
  final String title;
  final String subtitle;
  final String priority;
  final String type;
  final String stage;
  final String earTag;
  final String? livestockId;
}
```

Add `livestockId` and `fenceId` to `LivestockDetail`:

```dart
class LivestockDetail {
  const LivestockDetail({
    required this.earTag,
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
  });

  final String earTag;
  final String livestockId;
  final String breed;
  final int ageMonths;
  final double weightKg;
  final LivestockHealth health;
  final String fenceId;
  final List<DeviceItem> devices;
  final double bodyTemp;
  final String activityLevel;
  final String ruminationFreq;
  final String lastLocation;
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/seed_data_test.dart -v`
Expected: PASS

- [x] **Step 5: Fix compile errors in existing code**

Adding required `livestockId`/`fenceId` to `LivestockDetail` will break `DemoSeed.livestockDetail` and `DemoSeed.livestockDetailWatch`. Temporarily add placeholder values to keep compilation passing until Task 2 replaces them:

In `lib/core/data/demo_seed.dart`, update both `LivestockDetail` instances:
- Add `livestockId: '0001',` and `fenceId: 'fence_001',` to `livestockDetail`
- Add `livestockId: '0002',` and `fenceId: 'fence_001',` to `livestockDetailWatch`

Run: `flutter analyze`
Expected: No errors

- [x] **Step 6: Commit**

```bash
git add lib/core/models/demo_models.dart lib/core/data/demo_seed.dart test/seed_data_test.dart
git commit -m "feat: add LivestockInfo, AlertItem models; extend LivestockDetail with livestockId/fenceId"
```

---

## Task 2: DemoSeed Expansion

**Files:**
- Modify: `lib/core/data/demo_seed.dart`
- Test: `test/seed_data_test.dart`

- [x] **Step 1: Write failing tests for seed data**

Append to `test/seed_data_test.dart`:

```dart
import 'package:smart_livestock_demo/core/data/demo_seed.dart';

// ... (add to the existing main() block)

  test('DemoSeed has 50 cattle', () {
    expect(DemoSeed.livestock.length, 50);
  });

  test('earTags follow SL-2024-NNN format', () {
    for (final cow in DemoSeed.livestock) {
      expect(cow.earTag, matches(RegExp(r'^SL-2024-\d{3}$')));
    }
  });

  test('livestockIds follow 4-digit format', () {
    for (final cow in DemoSeed.livestock) {
      expect(cow.livestockId, matches(RegExp(r'^\d{4}$')));
    }
  });

  test('earTag to livestockId mapping is consistent', () {
    for (final cow in DemoSeed.livestock) {
      final n = int.parse(cow.earTag.split('-').last);
      expect(cow.livestockId, n.toString().padLeft(4, '0'));
    }
  });

  test('health distribution: 43 healthy, 4 watch, 3 abnormal', () {
    final counts = <LivestockHealth, int>{};
    for (final cow in DemoSeed.livestock) {
      counts[cow.health] = (counts[cow.health] ?? 0) + 1;
    }
    expect(counts[LivestockHealth.healthy], 43);
    expect(counts[LivestockHealth.watch], 4);
    expect(counts[LivestockHealth.abnormal], 3);
  });

  test('DemoSeed has 4 fences', () {
    expect(DemoSeed.fencePolygons.length, 4);
  });

  test('DemoSeed has 100 devices', () {
    expect(DemoSeed.devices.length, 100);
  });

  test('device type counts: 50 GPS, 30 RC, 20 ACC', () {
    final counts = <DeviceType, int>{};
    for (final d in DemoSeed.devices) {
      counts[d.type] = (counts[d.type] ?? 0) + 1;
    }
    expect(counts[DeviceType.gps], 50);
    expect(counts[DeviceType.rumenCapsule], 30);
    expect(counts[DeviceType.accelerometer], 20);
  });

  test('DemoSeed has 18 alerts', () {
    expect(DemoSeed.alerts.length, 18);
  });

  test('earTags list is derived from livestock', () {
    expect(DemoSeed.earTags.length, 50);
    expect(DemoSeed.earTags.first, 'SL-2024-001');
  });

  test('livestockLocations list has 50 entries', () {
    expect(DemoSeed.livestockLocations.length, 50);
  });

  test('getLivestockDetail returns valid detail', () {
    final detail = DemoSeed.getLivestockDetail('SL-2024-001');
    expect(detail, isNotNull);
    expect(detail!.livestockId, '0001');
    expect(detail.fenceId, isNotEmpty);
    expect(detail.devices, isNotEmpty);
  });

  test('getLivestockDetail returns null for unknown earTag', () {
    expect(DemoSeed.getLivestockDetail('UNKNOWN'), isNull);
  });
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/seed_data_test.dart -v`
Expected: FAIL — `DemoSeed.livestock`, `DemoSeed.alerts`, `DemoSeed.getLivestockDetail` don't exist yet.

- [x] **Step 3: Implement DemoSeed expansion**

Replace the entire content of `lib/core/data/demo_seed.dart`:

```dart
import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';

class DemoSeed {
  const DemoSeed._();

  static const LatLng mapCenter = LatLng(28.2282, 112.9388);
  static const double defaultZoom = 14.0;

  // --- Fences (4) ---

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
    ),
  ];

  // --- Livestock (50) ---

  static final List<LivestockInfo> livestock = _generateLivestock();

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
      LivestockHealth.healthy => 38.3 + Random(info.earTag.hashCode).nextDouble() * 0.6,
      LivestockHealth.watch => 39.2 + Random(info.earTag.hashCode).nextDouble() * 0.4,
      LivestockHealth.abnormal => 39.8 + Random(info.earTag.hashCode).nextDouble() * 0.5,
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
        LivestockHealth.healthy => '正常（步数 ${1800 + Random(info.earTag.hashCode).nextInt(1200)}）',
        LivestockHealth.watch => '偏低（步数 ${600 + Random(info.earTag.hashCode).nextInt(400)}）',
        LivestockHealth.abnormal => '异常（步数 ${200 + Random(info.earTag.hashCode).nextInt(300)}）',
      },
      ruminationFreq: switch (info.health) {
        LivestockHealth.healthy => '正常（每日 ${(7.5 + Random(info.earTag.hashCode).nextDouble() * 1.5).toStringAsFixed(1)} 小时）',
        LivestockHealth.watch => '偏低（每日 ${(4.5 + Random(info.earTag.hashCode).nextDouble() * 1.0).toStringAsFixed(1)} 小时）',
        LivestockHealth.abnormal => '异常（每日 ${(2.0 + Random(info.earTag.hashCode).nextDouble() * 1.0).toStringAsFixed(1)} 小时）',
      },
      lastLocation: '$fenceName · 区域${1 + Random(info.earTag.hashCode).nextInt(3)}',
    );
  }

  // --- Devices (100) ---

  static final List<DeviceItem> devices = _generateDevices();

  // --- Alerts (18) ---

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

  // --- Dashboard Metrics ---

  static const List<DashboardMetric> dashboardMetrics = [
    DashboardMetric(widgetKey: 'dashboard-metric-animal-total', title: '牲畜总数', value: '50'),
    DashboardMetric(widgetKey: 'dashboard-metric-device-online', title: '在线设备', value: '85'),
    DashboardMetric(widgetKey: 'dashboard-metric-alert-today', title: '今日告警', value: '8'),
    DashboardMetric(widgetKey: 'dashboard-metric-health-rate', title: '健康率', value: '92%'),
  ];

  // --- Stats ---

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
      StatsChartData(label: '周一', value: 2, color: 0xFF4C9A5F),
      StatsChartData(label: '周二', value: 3, color: 0xFF4C9A5F),
      StatsChartData(label: '周三', value: 1, color: 0xFF4C9A5F),
      StatsChartData(label: '周四', value: 4, color: 0xFFD28A2D),
      StatsChartData(label: '周五', value: 3, color: 0xFF4C9A5F),
      StatsChartData(label: '周六', value: 2, color: 0xFF4C9A5F),
      StatsChartData(label: '周日', value: 3, color: 0xFF4C9A5F),
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

  // --- Private Generators ---

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
        while (breedCounts[breedIdx] <= 0) breedIdx++;
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
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/seed_data_test.dart -v`
Expected: All tests PASS

- [x] **Step 5: Run static analysis**

Run: `flutter analyze`
Expected: No errors (there may be warnings in files that reference old `DemoSeed.livestockDetail` — these will be fixed in Task 6)

- [x] **Step 6: Commit**

```bash
git add lib/core/data/demo_seed.dart test/seed_data_test.dart
git commit -m "feat: expand DemoSeed to 50 cattle, 4 fences, 100 devices, 18 alerts"
```

---

## Task 3: Alerts Repository Refactor

**Files:**
- Modify: `lib/features/alerts/domain/alerts_repository.dart`
- Modify: `lib/features/alerts/data/mock_alerts_repository.dart`
- Test: `test/seed_data_test.dart`

- [x] **Step 1: Write failing test**

Append to `test/seed_data_test.dart`:

```dart
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/alerts/data/mock_alerts_repository.dart';
import 'package:smart_livestock_demo/features/alerts/domain/alerts_repository.dart';

// ... in main()

  test('MockAlertsRepository returns alert items list', () {
    const repo = MockAlertsRepository();
    final data = repo.load(
      viewState: ViewState.normal,
      role: DemoRole.owner,
      stage: AlertStage.pending,
    );
    expect(data.items, isNotEmpty);
    expect(data.items.first.earTag, startsWith('SL-2024-'));
  });

  test('AlertsViewData filters by stage', () {
    const repo = MockAlertsRepository();
    final pending = repo.load(
      viewState: ViewState.normal,
      role: DemoRole.owner,
      stage: AlertStage.pending,
    );
    for (final item in pending.items) {
      expect(item.stage, 'pending');
    }
  });
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/seed_data_test.dart --name="alert" -v`
Expected: FAIL — `AlertsViewData` has no `items` field.

- [x] **Step 3: Extend AlertsViewData**

In `lib/features/alerts/domain/alerts_repository.dart`, add `items` field:

```dart
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';

enum AlertStage {
  pending,
  acknowledged,
  handled,
  archived,
}

class AlertsViewData {
  const AlertsViewData({
    required this.viewState,
    required this.role,
    required this.stage,
    required this.title,
    required this.subtitle,
    this.items = const [],
    this.message,
  });

  final ViewState viewState;
  final DemoRole role;
  final AlertStage stage;
  final String title;
  final String subtitle;
  final List<AlertItem> items;
  final String? message;
}

abstract class AlertsRepository {
  AlertsViewData load({
    required ViewState viewState,
    required DemoRole role,
    required AlertStage stage,
  });
}
```

- [x] **Step 4: Update MockAlertsRepository**

Replace `lib/features/alerts/data/mock_alerts_repository.dart`:

```dart
import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/alerts/domain/alerts_repository.dart';

class MockAlertsRepository implements AlertsRepository {
  const MockAlertsRepository();

  static String _stageString(AlertStage stage) => switch (stage) {
        AlertStage.pending => 'pending',
        AlertStage.acknowledged => 'acknowledged',
        AlertStage.handled => 'handled',
        AlertStage.archived => 'archived',
      };

  @override
  AlertsViewData load({
    required ViewState viewState,
    required DemoRole role,
    required AlertStage stage,
  }) {
    final stageStr = _stageString(stage);
    final filtered = DemoSeed.alerts
        .where((a) => a.stage == stageStr)
        .toList();
    final first = filtered.isNotEmpty ? filtered.first : null;

    return AlertsViewData(
      viewState: viewState,
      role: role,
      stage: stage,
      title: first?.title ?? '暂无告警',
      subtitle: first?.subtitle ?? '',
      items: viewState == ViewState.normal ? filtered : const [],
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无告警',
        ViewState.error => '告警列表加载失败（演示）',
        ViewState.forbidden => '无权限处理告警（演示）',
        ViewState.offline => '离线：展示已缓存告警（演示）',
        ViewState.normal => null,
      },
    );
  }
}
```

- [x] **Step 5: Run test to verify it passes**

Run: `flutter test test/seed_data_test.dart --name="alert" -v`
Expected: PASS

- [x] **Step 6: Commit**

```bash
git add lib/features/alerts/domain/alerts_repository.dart lib/features/alerts/data/mock_alerts_repository.dart test/seed_data_test.dart
git commit -m "feat: extend AlertsViewData with items list, refactor MockAlertsRepository"
```

---

## Task 4: Time Series Generators

**Files:**
- Create: `lib/core/data/generators/gps_trajectory_generator.dart`
- Create: `lib/core/data/generators/temperature_generator.dart`
- Create: `lib/core/data/generators/motility_generator.dart`
- Create: `lib/core/data/generators/estrus_score_generator.dart`
- Test: `test/generator_test.dart`

- [x] **Step 1: Write failing tests for all generators**

Create `test/generator_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/core/data/generators/gps_trajectory_generator.dart';
import 'package:smart_livestock_demo/core/data/generators/temperature_generator.dart';
import 'package:smart_livestock_demo/core/data/generators/motility_generator.dart';
import 'package:smart_livestock_demo/core/data/generators/estrus_score_generator.dart';

void main() {
  group('GpsTrajectoryGenerator', () {
    test('generates 168 points for 7 days at 1h interval', () {
      final gen = GpsTrajectoryGenerator(seed: 42);
      final points = gen.generate(
        earTag: 'SL-2024-001',
        fenceBoundary: const [
          LatLng(28.2305, 112.9400),
          LatLng(28.2340, 112.9400),
          LatLng(28.2340, 112.9440),
          LatLng(28.2305, 112.9440),
        ],
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      expect(points.length, 168);
    });

    test('all points stay within fence bounding box', () {
      final gen = GpsTrajectoryGenerator(seed: 42);
      final points = gen.generate(
        earTag: 'SL-2024-001',
        fenceBoundary: const [
          LatLng(28.2305, 112.9400),
          LatLng(28.2340, 112.9400),
          LatLng(28.2340, 112.9440),
          LatLng(28.2305, 112.9440),
        ],
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      for (final p in points) {
        expect(p.lat, greaterThanOrEqualTo(28.2305));
        expect(p.lat, lessThanOrEqualTo(28.2340));
        expect(p.lng, greaterThanOrEqualTo(112.9400));
        expect(p.lng, lessThanOrEqualTo(112.9440));
      }
    });

    test('results are cached per earTag', () {
      final gen = GpsTrajectoryGenerator(seed: 42);
      final fence = const [
        LatLng(28.2305, 112.9400),
        LatLng(28.2340, 112.9440),
      ];
      final a = gen.generate(
        earTag: 'SL-2024-001',
        fenceBoundary: fence,
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      final b = gen.generate(
        earTag: 'SL-2024-001',
        fenceBoundary: fence,
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      expect(identical(a, b), isTrue);
    });
  });

  group('TemperatureGenerator', () {
    test('generates 336 records for 7 days at 30min interval', () {
      final gen = TemperatureGenerator(seed: 42);
      final records = gen.generate(
        livestockId: '0001',
        baselineTemp: 38.5,
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      expect(records.length, 336);
    });

    test('temperatures stay in reasonable range (36-42°C)', () {
      final gen = TemperatureGenerator(seed: 42);
      final records = gen.generate(
        livestockId: '0001',
        baselineTemp: 38.5,
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      for (final r in records) {
        expect(r.temperature, greaterThan(36.0));
        expect(r.temperature, lessThan(42.0));
      }
    });
  });

  group('MotilityGenerator', () {
    test('generates 336 records for 7 days at 30min interval', () {
      final gen = MotilityGenerator(seed: 42);
      final records = gen.generate(
        livestockId: '0001',
        healthLevel: 'normal',
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      expect(records.length, 336);
    });

    test('abnormal cows have lower motility', () {
      final gen = MotilityGenerator(seed: 42);
      final normal = gen.generate(
        livestockId: '0001',
        healthLevel: 'normal',
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      final abnormal = gen.generate(
        livestockId: '0002',
        healthLevel: 'critical',
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      final avgNormal =
          normal.map((r) => r.frequency).reduce((a, b) => a + b) /
              normal.length;
      final avgAbnormal =
          abnormal.map((r) => r.frequency).reduce((a, b) => a + b) /
              abnormal.length;
      expect(avgAbnormal, lessThan(avgNormal));
    });
  });

  group('EstrusScoreGenerator', () {
    test('generates 7 points for 7 days', () {
      final gen = EstrusScoreGenerator(seed: 42);
      final scores = gen.generate(
        livestockId: '0012',
        inEstrus: true,
        cycleDay: 17,
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      expect(scores.length, 7);
    });

    test('estrus cow peaks above 70', () {
      final gen = EstrusScoreGenerator(seed: 42);
      final scores = gen.generate(
        livestockId: '0012',
        inEstrus: true,
        cycleDay: 17,
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      final maxScore = scores.map((s) => s.score).reduce((a, b) => a > b ? a : b);
      expect(maxScore, greaterThan(70.0));
    });

    test('non-estrus cow stays below 40', () {
      final gen = EstrusScoreGenerator(seed: 42);
      final scores = gen.generate(
        livestockId: '0005',
        inEstrus: false,
        cycleDay: 5,
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      final maxScore = scores.map((s) => s.score).reduce((a, b) => a > b ? a : b);
      expect(maxScore, lessThan(40.0));
    });
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/generator_test.dart -v`
Expected: FAIL — generator files don't exist.

- [x] **Step 3: Create generators directory**

Run: `mkdir -p lib/core/data/generators`

- [x] **Step 4: Implement GpsTrajectoryGenerator**

Create `lib/core/data/generators/gps_trajectory_generator.dart`:

```dart
import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';

class GpsTrajectoryGenerator {
  GpsTrajectoryGenerator({this.seed = 42});

  final int seed;
  final Map<String, List<GeoPoint>> _cache = {};

  List<GeoPoint> generate({
    required String earTag,
    required List<LatLng> fenceBoundary,
    required DateTime start,
    required DateTime end,
  }) {
    return _cache.putIfAbsent(earTag, () => _doGenerate(
          earTag: earTag,
          fenceBoundary: fenceBoundary,
          start: start,
          end: end,
        ));
  }

  List<GeoPoint> _doGenerate({
    required String earTag,
    required List<LatLng> fenceBoundary,
    required DateTime start,
    required DateTime end,
  }) {
    final rng = Random(seed + earTag.hashCode);
    final points = <GeoPoint>[];

    final lats = fenceBoundary.map((p) => p.latitude).toList();
    final lngs = fenceBoundary.map((p) => p.longitude).toList();
    final minLat = lats.reduce(min);
    final maxLat = lats.reduce(max);
    final minLng = lngs.reduce(min);
    final maxLng = lngs.reduce(max);

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    var currentLat = centerLat + (rng.nextDouble() - 0.5) * (maxLat - minLat) * 0.3;
    var currentLng = centerLng + (rng.nextDouble() - 0.5) * (maxLng - minLng) * 0.3;

    var t = start;
    while (t.isBefore(end)) {
      final hour = t.hour;
      final isGrazing = hour >= 6 && hour < 18;
      final step = isGrazing ? 0.0003 : 0.00005;

      currentLat += (rng.nextDouble() - 0.5) * step * 2;
      currentLng += (rng.nextDouble() - 0.5) * step * 2;

      final margin = 0.0001;
      currentLat = currentLat.clamp(minLat + margin, maxLat - margin);
      currentLng = currentLng.clamp(minLng + margin, maxLng - margin);

      points.add(GeoPoint(
        lat: double.parse(currentLat.toStringAsFixed(4)),
        lng: double.parse(currentLng.toStringAsFixed(4)),
        timestamp: t.toIso8601String(),
      ));

      t = t.add(const Duration(hours: 1));
    }

    return points;
  }
}
```

- [x] **Step 5: Implement TemperatureGenerator**

Create `lib/core/data/generators/temperature_generator.dart`:

```dart
import 'dart:math';

import 'package:smart_livestock_demo/core/models/twin_models.dart';

class AbnormalTempEvent {
  const AbnormalTempEvent({
    required this.time,
    required this.peakDelta,
    required this.durationHours,
  });

  final DateTime time;
  final double peakDelta;
  final int durationHours;
}

class TemperatureGenerator {
  TemperatureGenerator({this.seed = 42});

  final int seed;
  final Map<String, List<TemperatureRecord>> _cache = {};

  List<TemperatureRecord> generate({
    required String livestockId,
    required double baselineTemp,
    required DateTime start,
    required DateTime end,
    List<AbnormalTempEvent> abnormalEvents = const [],
  }) {
    return _cache.putIfAbsent(livestockId, () => _doGenerate(
          livestockId: livestockId,
          baselineTemp: baselineTemp,
          start: start,
          end: end,
          abnormalEvents: abnormalEvents,
        ));
  }

  List<TemperatureRecord> _doGenerate({
    required String livestockId,
    required double baselineTemp,
    required DateTime start,
    required DateTime end,
    required List<AbnormalTempEvent> abnormalEvents,
  }) {
    final rng = Random(seed + livestockId.hashCode);
    final records = <TemperatureRecord>[];

    var t = start;
    while (t.isBefore(end)) {
      final hour = t.hour;
      final circadian = (hour >= 8 && hour <= 18) ? 0.2 : -0.1;
      final noise = (rng.nextDouble() - 0.5) * 0.2;
      var temp = baselineTemp + circadian + noise;

      for (final event in abnormalEvents) {
        final hoursAfter = t.difference(event.time).inMinutes / 60.0;
        if (hoursAfter >= 0 && hoursAfter < event.durationHours) {
          final progress = hoursAfter / event.durationHours;
          final envelope =
              progress < 0.3 ? progress / 0.3 : 1.0 - (progress - 0.3) / 0.7;
          temp += event.peakDelta * envelope;
        }
      }

      records.add(TemperatureRecord(
        livestockId: livestockId,
        temperature: double.parse(temp.toStringAsFixed(2)),
        timestamp: t,
      ));

      t = t.add(const Duration(minutes: 30));
    }

    return records;
  }
}
```

- [x] **Step 6: Implement MotilityGenerator**

Create `lib/core/data/generators/motility_generator.dart`:

```dart
import 'dart:math';

import 'package:smart_livestock_demo/core/models/twin_models.dart';

class MotilityGenerator {
  MotilityGenerator({this.seed = 42});

  final int seed;
  final Map<String, List<MotilityRecord>> _cache = {};

  List<MotilityRecord> generate({
    required String livestockId,
    required String healthLevel,
    required DateTime start,
    required DateTime end,
  }) {
    final key = '${livestockId}_$healthLevel';
    return _cache.putIfAbsent(key, () => _doGenerate(
          livestockId: livestockId,
          healthLevel: healthLevel,
          start: start,
          end: end,
        ));
  }

  List<MotilityRecord> _doGenerate({
    required String livestockId,
    required String healthLevel,
    required DateTime start,
    required DateTime end,
  }) {
    final rng = Random(seed + livestockId.hashCode);
    final records = <MotilityRecord>[];

    final healthFactor = switch (healthLevel) {
      'critical' => 0.3,
      'warning' => 0.55,
      _ => 1.0,
    };

    var t = start;
    while (t.isBefore(end)) {
      final hour = t.hour;

      double baseFreq;
      if ((hour >= 6 && hour < 8) || (hour >= 17 && hour < 19)) {
        baseFreq = 3.0 + rng.nextDouble() * 2.0;
      } else if ((hour >= 9 && hour < 12) || (hour >= 20 && hour < 23)) {
        baseFreq = 1.0 + rng.nextDouble() * 1.0;
      } else {
        baseFreq = 0.3 + rng.nextDouble() * 0.5;
      }

      final freq = baseFreq * healthFactor;
      final intensity = freq > 0.1 ? 0.5 + rng.nextDouble() * 0.4 : 0.0;

      records.add(MotilityRecord(
        livestockId: livestockId,
        frequency: double.parse(freq.toStringAsFixed(2)),
        intensity: double.parse(intensity.toStringAsFixed(2)),
        timestamp: t,
      ));

      t = t.add(const Duration(minutes: 30));
    }

    return records;
  }
}
```

- [x] **Step 7: Implement EstrusScoreGenerator**

Create `lib/core/data/generators/estrus_score_generator.dart`:

```dart
import 'dart:math';

import 'package:smart_livestock_demo/core/models/twin_models.dart';

class EstrusScoreGenerator {
  EstrusScoreGenerator({this.seed = 42});

  final int seed;
  final Map<String, List<EstrusTrendPoint>> _cache = {};

  List<EstrusTrendPoint> generate({
    required String livestockId,
    required bool inEstrus,
    required int cycleDay,
    required DateTime start,
    required DateTime end,
  }) {
    return _cache.putIfAbsent(livestockId, () => _doGenerate(
          livestockId: livestockId,
          inEstrus: inEstrus,
          cycleDay: cycleDay,
          start: start,
          end: end,
        ));
  }

  List<EstrusTrendPoint> _doGenerate({
    required String livestockId,
    required bool inEstrus,
    required int cycleDay,
    required DateTime start,
    required DateTime end,
  }) {
    final rng = Random(seed + livestockId.hashCode);
    final points = <EstrusTrendPoint>[];

    var t = start;
    var day = cycleDay;
    while (t.isBefore(end)) {
      double score;
      if (!inEstrus || day <= 16 || day == 21) {
        score = 10.0 + rng.nextDouble() * 20.0;
      } else if (day == 17 || day == 18) {
        score = 40.0 + rng.nextDouble() * 20.0;
      } else {
        score = 75.0 + rng.nextDouble() * 25.0;
      }

      score += (rng.nextDouble() - 0.5) * 10.0;
      score = score.clamp(0.0, 100.0);

      points.add(EstrusTrendPoint(
        score: double.parse(score.toStringAsFixed(1)),
        timestamp: t,
      ));

      t = t.add(const Duration(days: 1));
      day = (day % 21) + 1;
    }

    return points;
  }
}
```

- [x] **Step 8: Run tests to verify all pass**

Run: `flutter test test/generator_test.dart -v`
Expected: All tests PASS

- [x] **Step 9: Commit**

```bash
git add lib/core/data/generators/ test/generator_test.dart
git commit -m "feat: add GPS, temperature, motility, estrus generators with fixed seed determinism"
```

---

## Task 5: TwinSeed Expansion

**Files:**
- Modify: `lib/core/data/twin_seed.dart`
- Test: `test/seed_data_test.dart`

- [x] **Step 1: Write failing tests**

Append to `test/seed_data_test.dart`:

```dart
import 'package:smart_livestock_demo/core/data/twin_seed.dart';

// ... in main()

  test('TwinSeed has 30 fever baselines', () {
    expect(TwinSeed.feverBaselines.length, 30);
  });

  test('TwinSeed fever baselines use livestockId 0001-0030', () {
    final ids = TwinSeed.feverBaselines.map((b) => b.livestockId).toSet();
    for (var i = 1; i <= 30; i++) {
      expect(ids.contains(i.toString().padLeft(4, '0')), isTrue);
    }
  });

  test('TwinSeed has 30 digestive items', () {
    expect(TwinSeed.digestiveItems.length, 30);
  });

  test('TwinSeed has 3 estrus items in estrus', () {
    expect(TwinSeed.estrusItems.length, 3);
    final ids = TwinSeed.estrusItems.map((e) => e.livestockId).toSet();
    expect(ids, containsAll(['0012', '0024', '0028']));
  });

  test('TwinSeed fever baselines have temperature records', () {
    for (final b in TwinSeed.feverBaselines) {
      expect(b.recent72h, isNotEmpty);
    }
  });

  test('TwinSeed digestive items have motility records', () {
    for (final d in TwinSeed.digestiveItems) {
      expect(d.recent24h, isNotEmpty);
    }
  });
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/seed_data_test.dart --name="TwinSeed" -v`
Expected: FAIL — current TwinSeed only has 5 fever baselines, 4 digestive items.

- [x] **Step 3: Implement TwinSeed expansion**

Replace the entire content of `lib/core/data/twin_seed.dart`:

```dart
import 'package:smart_livestock_demo/core/data/generators/estrus_score_generator.dart';
import 'package:smart_livestock_demo/core/data/generators/motility_generator.dart';
import 'package:smart_livestock_demo/core/data/generators/temperature_generator.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';

class TwinSeed {
  const TwinSeed._();

  static final _tempGen = TemperatureGenerator(seed: 42);
  static final _motilityGen = MotilityGenerator(seed: 42);
  static final _estrusGen = EstrusScoreGenerator(seed: 42);

  static final DateTime _start = DateTime.utc(2026, 4, 1);
  static final DateTime _end = DateTime.utc(2026, 4, 8);

  static final List<TemperatureBaseline> feverBaselines =
      _buildFeverBaselines();

  static final List<DigestiveHealth> digestiveItems = _buildDigestiveItems();

  static final List<EstrusScore> estrusItems = _buildEstrusItems();

  static final HerdHealthMetrics epidemicMetrics = HerdHealthMetrics(
    avgTemperature: 38.7,
    avgActivity: 72.5,
    abnormalRate: 6.0,
    totalLivestock: 50,
    abnormalCount: 3,
  );

  static final List<ContactTrace> epidemicContacts = [
    ContactTrace(
      fromId: '0048',
      toId: '0049',
      lastContact: DateTime.utc(2026, 4, 7, 8, 30),
      proximity: 5.2,
    ),
    ContactTrace(
      fromId: '0049',
      toId: '0050',
      lastContact: DateTime.utc(2026, 4, 7, 7, 10),
      proximity: 8.1,
    ),
    ContactTrace(
      fromId: '0048',
      toId: '0001',
      lastContact: DateTime.utc(2026, 4, 6, 18, 0),
      proximity: 12.0,
    ),
  ];

  static TwinOverviewStats get overviewStats => TwinOverviewStats(
        totalLivestock: 3847,
        healthyRate: 99.1,
        alertCount: 35,
        criticalCount: 3,
        deviceOnlineRate: 97.8,
        livestockCaption: '牛 2,156 / 羊 1,691',
        alertCaption: '紧急 3 / 一般 32',
        healthCaption: '健康个体 3,812',
        deviceCaption: '传感器 1,247 在线',
        healthTrend: '+0.3%',
        livestockTrend: '+12 本周新增',
      );

  static TwinSceneSummary get sceneSummary => TwinSceneSummary(
        fever: SceneSummaryFever(abnormalCount: 5, criticalCount: 3),
        digestive: SceneSummaryDigestive(abnormalCount: 2, watchCount: 3),
        estrus: SceneSummaryEstrus(highScoreCount: 2, breedingAdvice: true),
        epidemic: SceneSummaryEpidemic(status: 'normal', abnormalRate: 6.0),
      );

  static List<TwinPendingTask> get pendingTasks => [
        const TwinPendingTask(
          id: 'pt1',
          title: '牛#0048 体温紧急',
          subtitle: '较基线升高 1.2°C · 建议立即复核',
          routePath: '/twin/fever/0048',
          severity: 'critical',
        ),
        const TwinPendingTask(
          id: 'pt2',
          title: '牛#0049 蠕动停止',
          subtitle: '消化系统 · 需现场处置',
          routePath: '/twin/digestive/0049',
          severity: 'critical',
        ),
        const TwinPendingTask(
          id: 'pt3',
          title: '牛#0012 发情高分',
          subtitle: '评分 92 · 建议6小时内配种',
          routePath: '/twin/estrus/0012',
          severity: 'warning',
        ),
      ];

  // --- Private builders ---

  static List<TemperatureBaseline> _buildFeverBaselines() {
    final result = <TemperatureBaseline>[];
    for (var i = 1; i <= 30; i++) {
      final id = i.toString().padLeft(4, '0');
      final baseTemp = 38.0 + (i % 6) * 0.25;

      String status;
      String conclusion;
      List<AbnormalTempEvent> events;

      if (i >= 28) {
        status = 'critical';
        conclusion = '温度升高+活动量下降，高概率感染，建议隔离检查';
        events = [
          AbnormalTempEvent(
            time: DateTime.utc(2026, 4, 5, 10),
            peakDelta: 1.5,
            durationHours: 48,
          ),
        ];
      } else if (i >= 26) {
        status = 'warning';
        conclusion = '体温轻度升高，建议持续观察饮水与采食';
        events = [
          AbnormalTempEvent(
            time: DateTime.utc(2026, 4, 6, 14),
            peakDelta: 0.6,
            durationHours: 24,
          ),
        ];
      } else {
        status = 'normal';
        conclusion = '体温稳定，未见异常波动';
        events = [];
      }

      result.add(TemperatureBaseline(
        livestockId: id,
        baselineTemp: double.parse(baseTemp.toStringAsFixed(1)),
        threshold: double.parse((baseTemp + 0.5).toStringAsFixed(1)),
        recent72h: _tempGen.generate(
          livestockId: id,
          baselineTemp: baseTemp,
          start: _start,
          end: _end,
          abnormalEvents: events,
        ),
        status: status,
        conclusion: conclusion,
      ));
    }
    return result;
  }

  static List<DigestiveHealth> _buildDigestiveItems() {
    final result = <DigestiveHealth>[];
    for (var i = 1; i <= 30; i++) {
      final id = i.toString().padLeft(4, '0');
      final baseMot = 1.3 + (i % 5) * 0.05;

      String status;
      String advice;
      String healthLevel;

      if (i >= 29) {
        status = 'critical';
        advice = '蠕动完全停止，疑似瘤胃臌气，需立即处理';
        healthLevel = 'critical';
      } else if (i >= 26) {
        status = 'warning';
        advice = '蠕动频率下降，建议检查饲粮与饮水';
        healthLevel = 'warning';
      } else {
        status = 'normal';
        advice = '蠕动节律正常';
        healthLevel = 'normal';
      }

      result.add(DigestiveHealth(
        livestockId: id,
        motilityBaseline: double.parse(baseMot.toStringAsFixed(2)),
        status: status,
        advice: advice,
        recent24h: _motilityGen.generate(
          livestockId: id,
          healthLevel: healthLevel,
          start: _start,
          end: _end,
        ),
      ));
    }
    return result;
  }

  static List<EstrusScore> _buildEstrusItems() {
    final estrusCows = [
      (id: '0012', cycleDay: 17),
      (id: '0024', cycleDay: 18),
      (id: '0028', cycleDay: 19),
    ];
    final result = <EstrusScore>[];

    for (final cow in estrusCows) {
      final trend = _estrusGen.generate(
        livestockId: cow.id,
        inEstrus: true,
        cycleDay: cow.cycleDay,
        start: _start,
        end: _end,
      );
      final lastScore = trend.last;

      result.add(EstrusScore(
        livestockId: cow.id,
        score: lastScore.score.round(),
        stepIncreasePercent: 180 + (cow.id.hashCode % 200),
        tempDelta: 0.2 + (cow.id.hashCode % 3) * 0.1,
        distanceDelta: 1.5 + (cow.id.hashCode % 30) * 0.1,
        timestamp: _end.subtract(const Duration(hours: 2)),
        advice: lastScore.score > 80
            ? '步数显著增加，建议6小时内配种'
            : '发情信号增强，建议12小时内关注配种窗口',
        trend7d: trend,
      ));
    }

    return result;
  }
}
```

- [x] **Step 4: Run tests to verify they pass**

Run: `flutter test test/seed_data_test.dart --name="TwinSeed" -v`
Expected: All TwinSeed tests PASS

- [x] **Step 5: Commit**

```bash
git add lib/core/data/twin_seed.dart test/seed_data_test.dart
git commit -m "feat: expand TwinSeed to 30 cattle with generator-powered time series"
```

---

## Task 6: Mock Repository Updates (Map, Livestock)

**Files:**
- Modify: `lib/features/map/data/mock_map_repository.dart`
- Modify: `lib/features/livestock/data/mock_livestock_repository.dart`

- [x] **Step 1: Update MockMapRepository**

Replace `lib/features/map/data/mock_map_repository.dart`:

```dart
import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/data/generators/gps_trajectory_generator.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/map/domain/map_repository.dart';

class MockMapRepository implements MapRepository {
  const MockMapRepository();

  static final _gpsGen = GpsTrajectoryGenerator(seed: 42);

  @override
  MapViewData load({
    required ViewState viewState,
    required String selectedAnimal,
    required TrajectoryRange selectedRange,
  }) {
    final rangeLabel = switch (selectedRange) {
      TrajectoryRange.h24 => '24h',
      TrajectoryRange.d7 => '7d',
      TrajectoryRange.d30 => '30d',
    };

    List<GeoPoint> trajectory = const [];
    if (viewState == ViewState.normal) {
      LivestockInfo? cow;
      for (final l in DemoSeed.livestock) {
        if (l.earTag == selectedAnimal) {
          cow = l;
          break;
        }
      }

      if (cow != null) {
        FencePolygon? fence;
        for (final f in DemoSeed.fencePolygons) {
          if (f.id == cow.fenceId) {
            fence = f;
            break;
          }
        }

        if (fence != null) {
          final end = DateTime.utc(2026, 4, 8, 10);
          final start = switch (selectedRange) {
            TrajectoryRange.h24 => end.subtract(const Duration(hours: 24)),
            TrajectoryRange.d7 => end.subtract(const Duration(days: 7)),
            TrajectoryRange.d30 => end.subtract(const Duration(days: 30)),
          };
          final full = _gpsGen.generate(
            earTag: selectedAnimal,
            fenceBoundary: fence.points,
            start: start,
            end: end,
          );
          trajectory = full;
        }
      }
    }

    return MapViewData(
      viewState: viewState,
      availableAnimals: DemoSeed.earTags,
      selectedAnimal: selectedAnimal,
      selectedRange: selectedRange,
      summaryText: '$selectedAnimal · $rangeLabel',
      fallbackItems: DemoSeed.earTags
          .take(5)
          .map((t) => '$t · 最近点')
          .toList(),
      mapCenter: DemoSeed.mapCenter,
      zoom: DemoSeed.defaultZoom,
      livestockLocations: DemoSeed.livestockLocations,
      trajectoryPoints: trajectory,
      fences: DemoSeed.fencePolygons,
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无定位数据',
        ViewState.error => '地图不可用，列表回退（演示）',
        ViewState.forbidden => '无权限查看地图（演示）',
        ViewState.offline => '离线：$selectedAnimal · $rangeLabel（演示）',
        ViewState.normal => null,
      },
    );
  }
}
```

- [x] **Step 2: Update MockLivestockRepository**

Replace `lib/features/livestock/data/mock_livestock_repository.dart`:

```dart
import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/livestock/domain/livestock_repository.dart';

class MockLivestockRepository implements LivestockRepository {
  const MockLivestockRepository();

  @override
  LivestockViewData load(
      {required ViewState viewState, required String earTag}) {
    final detail = DemoSeed.getLivestockDetail(earTag);
    return LivestockViewData(
      viewState: viewState,
      detail: viewState == ViewState.normal ? detail : null,
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '未找到该牲畜',
        ViewState.error => '加载失败（演示）',
        ViewState.forbidden => '无权限查看该牲畜（演示）',
        ViewState.offline => '离线数据（演示）',
        ViewState.normal => null,
      },
    );
  }
}
```

- [x] **Step 3: Run static analysis**

Run: `flutter analyze`
Expected: No errors

- [x] **Step 4: Commit**

```bash
git add lib/features/map/data/mock_map_repository.dart lib/features/livestock/data/mock_livestock_repository.dart
git commit -m "feat: update MockMapRepository with GPS generator, MockLivestockRepository for 50 cattle"
```

---

## Task 7: Live Repository Fixes

**Files:**
- Modify: `lib/features/map/data/live_map_repository.dart`

- [x] **Step 1: Fix LiveMapRepository hardcoded references**

In `lib/features/map/data/live_map_repository.dart`, replace the hardcoded `DemoSeed.livestockLocations` and `DemoSeed.trajectoryPoints` with ApiCache-derived data. Change lines 69-72:

Replace:
```dart
      livestockLocations: DemoSeed.livestockLocations,
      trajectoryPoints: DemoSeed.trajectoryPoints,
```

With:
```dart
      livestockLocations: _parseLocations(cache.animals),
      trajectoryPoints: _parseTrajectory(cache),
```

Add these static helper methods to the `LiveMapRepository` class:

```dart
  static List<GeoPoint> _parseLocations(List<Map<String, dynamic>> animals) {
    return animals
        .map((a) => GeoPoint(
              lat: (a['lat'] as num?)?.toDouble() ?? 0,
              lng: (a['lng'] as num?)?.toDouble() ?? 0,
              timestamp: a['timestamp'] as String? ?? '',
            ))
        .toList();
  }

  static List<GeoPoint> _parseTrajectory(ApiCache cache) {
    final raw = cache.get('trajectoryPoints');
    if (raw is! List) return const [];
    return raw
        .map((p) {
          if (p is! Map) return null;
          return GeoPoint(
            lat: (p['lat'] as num?)?.toDouble() ?? 0,
            lng: (p['lng'] as num?)?.toDouble() ?? 0,
            timestamp: p['ts'] as String? ?? p['timestamp'] as String? ?? '',
          );
        })
        .whereType<GeoPoint>()
        .toList();
  }
```

Also remove the unused `DemoSeed` import if no other references remain. Keep `ApiCache` import.

**Note:** Check `ApiCache` class to verify that `cache.get('trajectoryPoints')` is the correct accessor. If `ApiCache` doesn't have a generic `get` method, adapt to available methods. The key goal is to stop using `DemoSeed.livestockLocations` and `DemoSeed.trajectoryPoints` in the live repository.

- [x] **Step 2: Run static analysis**

Run: `flutter analyze`
Expected: No errors

- [x] **Step 3: Commit**

```bash
git add lib/features/map/data/live_map_repository.dart
git commit -m "fix: remove hardcoded DemoSeed references from LiveMapRepository"
```

---

## Task 8: Backend Seed & Routes Sync

**Files (relative to `Mobile/`):**
- Modify: `backend/data/seed.js`
- Modify: `backend/data/twin_seed.js`
- Modify: `backend/routes/map.js`

- [x] **Step 1: Update backend seed.js**

Replace `backend/data/seed.js` with expanded data. Use JavaScript generation for bulk data:

```javascript
const users = {
  owner: {
    userId: 'u_001', tenantId: 'tenant_001', name: '张三', role: 'owner',
    mobile: '13800000000',
    permissions: [
      'dashboard:view','twin:view','map:view',
      'alert:view','alert:ack','alert:handle','alert:archive','alert:batch',
      'fence:view','fence:manage',
      'tenant:view','tenant:create','tenant:toggle','license:manage','profile:view',
    ],
  },
  worker: {
    userId: 'u_002', tenantId: 'tenant_001', name: '李四', role: 'worker',
    mobile: '13800000001',
    permissions: ['dashboard:view','twin:view','map:view','alert:view','alert:ack','fence:view','profile:view'],
  },
  ops: {
    userId: 'u_003', tenantId: null, name: '运维管理员', role: 'ops',
    mobile: '13800000002',
    permissions: ['tenant:view','tenant:create','tenant:toggle','license:manage'],
  },
};

const dashboardMetrics = [
  { key: 'animal_total', title: '牲畜总数', value: '50' },
  { key: 'device_online', title: '在线设备', value: '85' },
  { key: 'alert_today', title: '今日告警', value: '8' },
  { key: 'health_rate', title: '健康率', value: '92%' },
];

function generateAnimals() {
  const breeds = ['西门塔尔牛', '安格斯牛', '利木赞牛'];
  const breedCounts = [20, 15, 15];
  let breedIdx = 0;
  let breedRemaining = [...breedCounts];

  const fenceConfigs = [
    { id: 'fence_pasture_a', count: 25, latMin: 28.2305, latMax: 28.2340, lngMin: 112.9400, lngMax: 112.9440 },
    { id: 'fence_pasture_b', count: 18, latMin: 28.2240, latMax: 28.2275, lngMin: 112.9320, lngMax: 112.9360 },
    { id: 'fence_rest', count: 4, latMin: 28.2280, latMax: 28.2295, lngMin: 112.9380, lngMax: 112.9400 },
    { id: 'fence_quarantine', count: 3, latMin: 28.2248, latMax: 28.2255, lngMin: 112.9400, lngMax: 112.9410 },
  ];

  const result = [];
  let seed = 42;
  function seededRandom() { seed = (seed * 16807) % 2147483647; return (seed - 1) / 2147483646; }

  for (const fc of fenceConfigs) {
    for (let i = 0; i < fc.count; i++) {
      const n = result.length + 1;
      while (breedRemaining[breedIdx] <= 0) breedIdx++;
      breedRemaining[breedIdx]--;
      const nn = n.toString().padStart(3, '0');
      result.push({
        id: `animal_${nn}`,
        earTag: `SL-2024-${nn}`,
        livestockId: n.toString().padStart(4, '0'),
        breed: breeds[breedIdx],
        fenceId: fc.id,
        lat: +(fc.latMin + seededRandom() * (fc.latMax - fc.latMin)).toFixed(4),
        lng: +(fc.lngMin + seededRandom() * (fc.lngMax - fc.lngMin)).toFixed(4),
      });
    }
  }
  return result;
}

const animals = generateAnimals();

const fences = [
  { id: 'fence_pasture_a', name: '放牧A区', type: 'polygon', status: 'active', alarmEnabled: true,
    coordinates: [[112.9400,28.2340],[112.9440,28.2340],[112.9440,28.2305],[112.9400,28.2305]] },
  { id: 'fence_pasture_b', name: '放牧B区', type: 'polygon', status: 'active', alarmEnabled: true,
    coordinates: [[112.9320,28.2275],[112.9360,28.2275],[112.9360,28.2240],[112.9320,28.2240]] },
  { id: 'fence_rest', name: '夜间休息区', type: 'polygon', status: 'active', alarmEnabled: false,
    coordinates: [[112.9380,28.2295],[112.9400,28.2295],[112.9400,28.2280],[112.9380,28.2280]] },
  { id: 'fence_quarantine', name: '隔离区', type: 'polygon', status: 'active', alarmEnabled: true,
    coordinates: [[112.9400,28.2255],[112.9410,28.2255],[112.9410,28.2248],[112.9400,28.2248]] },
];

const alerts = [
  { id: 'alert-001', type: 'geofence', title: '越界 · SL-2024-003', occurredAt: '2026-04-08T14:23:00+08:00', stage: 'pending', level: 'critical', earTag: 'SL-2024-003', priority: 'P0' },
  { id: 'alert-002', type: 'fever', title: '体温异常 · SL-2024-048', occurredAt: '2026-04-08T11:05:00+08:00', stage: 'acknowledged', level: 'critical', earTag: 'SL-2024-048', priority: 'P0' },
  { id: 'alert-003', type: 'geofence', title: '越界 · SL-2024-017', occurredAt: '2026-04-07T16:30:00+08:00', stage: 'handled', level: 'critical', earTag: 'SL-2024-017', priority: 'P0' },
  { id: 'alert-004', type: 'fever', title: '体温异常 · SL-2024-049', occurredAt: '2026-04-07T09:15:00+08:00', stage: 'handled', level: 'critical', earTag: 'SL-2024-049', priority: 'P0' },
  { id: 'alert-005', type: 'offline', title: '设备离线 · SL-2024-043', occurredAt: '2026-04-08T13:40:00+08:00', stage: 'pending', level: 'warning', earTag: 'SL-2024-043', priority: 'P1' },
  { id: 'alert-006', type: 'lowbattery', title: '低电量 · SL-2024-045', occurredAt: '2026-04-08T12:20:00+08:00', stage: 'pending', level: 'warning', earTag: 'SL-2024-045', priority: 'P1' },
  { id: 'alert-007', type: 'offline', title: '设备离线 · SL-2024-044', occurredAt: '2026-04-08T08:50:00+08:00', stage: 'acknowledged', level: 'warning', earTag: 'SL-2024-044', priority: 'P1' },
  { id: 'alert-008', type: 'lowbattery', title: '低电量 · SL-2024-046', occurredAt: '2026-04-07T15:10:00+08:00', stage: 'handled', level: 'warning', earTag: 'SL-2024-046', priority: 'P1' },
  { id: 'alert-009', type: 'offline', title: '设备离线 · SL-2024-042', occurredAt: '2026-04-07T10:25:00+08:00', stage: 'handled', level: 'warning', earTag: 'SL-2024-042', priority: 'P1' },
  { id: 'alert-010', type: 'behavior', title: '行为异常 · SL-2024-047', occurredAt: '2026-04-08T09:30:00+08:00', stage: 'pending', level: 'info', earTag: 'SL-2024-047', priority: 'P2' },
  { id: 'alert-011', type: 'geofence', title: '围栏接近 · SL-2024-012', occurredAt: '2026-04-07T14:50:00+08:00', stage: 'handled', level: 'info', earTag: 'SL-2024-012', priority: 'P2' },
  { id: 'alert-012', type: 'behavior', title: '行为异常 · SL-2024-050', occurredAt: '2026-04-07T11:35:00+08:00', stage: 'handled', level: 'info', earTag: 'SL-2024-050', priority: 'P2' },
  { id: 'alert-013', type: 'geofence', title: '围栏接近 · SL-2024-008', occurredAt: '2026-04-06T16:45:00+08:00', stage: 'handled', level: 'info', earTag: 'SL-2024-008', priority: 'P2' },
  { id: 'alert-014', type: 'behavior', title: '行为异常 · SL-2024-030', occurredAt: '2026-04-06T10:00:00+08:00', stage: 'archived', level: 'info', earTag: 'SL-2024-030', priority: 'P2' },
  { id: 'alert-015', type: 'geofence', title: '越界 · SL-2024-005', occurredAt: '2026-04-05T09:10:00+08:00', stage: 'archived', level: 'critical', earTag: 'SL-2024-005', priority: 'P0' },
  { id: 'alert-016', type: 'offline', title: '设备离线 · SL-2024-041', occurredAt: '2026-04-04T14:30:00+08:00', stage: 'archived', level: 'warning', earTag: 'SL-2024-041', priority: 'P1' },
  { id: 'alert-017', type: 'lowbattery', title: '低电量 · SL-2024-047', occurredAt: '2026-04-03T11:20:00+08:00', stage: 'archived', level: 'warning', earTag: 'SL-2024-047', priority: 'P1' },
  { id: 'alert-018', type: 'fever', title: '体温异常 · SL-2024-050', occurredAt: '2026-04-02T08:00:00+08:00', stage: 'archived', level: 'critical', earTag: 'SL-2024-050', priority: 'P0' },
];

const tenants = [
  { id: 'tenant_001', name: '华东示范牧场', status: 'active', licenseUsed: 50, licenseTotal: 200 },
  { id: 'tenant_002', name: '西部高原牧场', status: 'active', licenseUsed: 120, licenseTotal: 200 },
];

module.exports = { users, dashboardMetrics, animals, fences, alerts, tenants };
```

- [x] **Step 2: Update backend twin_seed.js**

Replace `backend/data/twin_seed.js`:

```javascript
const overview = {
  stats: {
    totalLivestock: 3847, healthyRate: 99.1, alertCount: 35, criticalCount: 3,
    deviceOnlineRate: 97.8, livestockCaption: '牛 2,156 / 羊 1,691',
    alertCaption: '紧急 3 / 一般 32', healthCaption: '健康个体 3,812',
    deviceCaption: '传感器 1,247 在线', healthTrend: '+0.3%', livestockTrend: '+12 本周新增',
  },
  sceneSummary: {
    fever: { abnormalCount: 5, criticalCount: 3 },
    digestive: { abnormalCount: 2, watchCount: 3 },
    estrus: { highScoreCount: 2, breedingAdvice: true },
    epidemic: { status: 'normal', abnormalRate: 6.0 },
  },
  pendingTasks: [
    { id: 'pt1', title: '牛#0048 体温紧急', subtitle: '较基线升高 1.2°C · 建议立即复核', routePath: '/twin/fever/0048', severity: 'critical' },
    { id: 'pt2', title: '牛#0049 蠕动停止', subtitle: '消化系统 · 需现场处置', routePath: '/twin/digestive/0049', severity: 'critical' },
    { id: 'pt3', title: '牛#0012 发情高分', subtitle: '评分 92 · 建议6小时内配种', routePath: '/twin/estrus/0012', severity: 'warning' },
  ],
};

function tempPoint(t, temp) { return { temperature: temp, timestamp: t }; }

function buildFeverList() {
  const result = [];
  for (let i = 1; i <= 30; i++) {
    const id = i.toString().padStart(4, '0');
    const base = 38.0 + (i % 6) * 0.25;
    let status, conclusion;
    if (i >= 28) { status = 'critical'; conclusion = '温度升高+活动量下降，高概率感染，建议隔离检查'; }
    else if (i >= 26) { status = 'warning'; conclusion = '体温轻度升高，建议持续观察饮水与采食'; }
    else { status = 'normal'; conclusion = '体温稳定，未见异常波动'; }
    result.push({
      livestockId: id, baselineTemp: +base.toFixed(1), threshold: +(base + 0.5).toFixed(1),
      status, conclusion,
      recent72h: [
        tempPoint('2026-04-05T10:00:00Z', base),
        tempPoint('2026-04-06T10:00:00Z', status === 'critical' ? base + 1.0 : base + 0.1),
        tempPoint('2026-04-07T10:00:00Z', status === 'critical' ? base + 1.5 : status === 'warning' ? base + 0.5 : base + 0.05),
      ],
    });
  }
  return result;
}

const feverListItems = buildFeverList();

function buildDigestiveList() {
  const result = [];
  for (let i = 1; i <= 30; i++) {
    const id = i.toString().padStart(4, '0');
    const base = 1.3 + (i % 5) * 0.05;
    let status, advice;
    if (i >= 29) { status = 'critical'; advice = '蠕动完全停止，疑似瘤胃臌气，需立即处理'; }
    else if (i >= 26) { status = 'warning'; advice = '蠕动频率下降，建议检查饲粮与饮水'; }
    else { status = 'normal'; advice = '蠕动节律正常'; }
    result.push({
      livestockId: id, motilityBaseline: +base.toFixed(2), status, advice,
      recent24h: [
        { frequency: status === 'critical' ? 0 : base, intensity: status === 'critical' ? 0 : 0.8, timestamp: '2026-04-07T10:00:00Z' },
      ],
    });
  }
  return result;
}

const digestiveListItems = buildDigestiveList();

const estrusListItems = [
  { livestockId: '0012', score: 92, stepIncreasePercent: 320, tempDelta: 0.4, distanceDelta: 3.5, timestamp: '2026-04-07T09:58:00Z', advice: '步数显著增加，建议6小时内配种',
    trend7d: [{ score: 15, timestamp: '2026-04-01T10:00:00Z' }, { score: 50, timestamp: '2026-04-04T10:00:00Z' }, { score: 92, timestamp: '2026-04-07T10:00:00Z' }] },
  { livestockId: '0024', score: 78, stepIncreasePercent: 180, tempDelta: 0.2, distanceDelta: 2.1, timestamp: '2026-04-07T08:12:00Z', advice: '发情信号增强，建议12小时内关注配种窗口',
    trend7d: [{ score: 20, timestamp: '2026-04-01T10:00:00Z' }, { score: 45, timestamp: '2026-04-04T10:00:00Z' }, { score: 78, timestamp: '2026-04-07T10:00:00Z' }] },
  { livestockId: '0028', score: 85, stepIncreasePercent: 240, tempDelta: 0.3, distanceDelta: 2.8, timestamp: '2026-04-07T07:30:00Z', advice: '步数显著增加，建议6小时内配种',
    trend7d: [{ score: 12, timestamp: '2026-04-01T10:00:00Z' }, { score: 55, timestamp: '2026-04-04T10:00:00Z' }, { score: 85, timestamp: '2026-04-07T10:00:00Z' }] },
];

const epidemicSummary = {
  avgTemperature: 38.7, avgActivity: 72.5, abnormalRate: 6.0,
  totalLivestock: 50, abnormalCount: 3,
};

const epidemicContacts = [
  { fromId: '0048', toId: '0049', lastContact: '2026-04-07T08:30:00Z', proximity: 5.2 },
  { fromId: '0049', toId: '0050', lastContact: '2026-04-07T07:10:00Z', proximity: 8.1 },
];

module.exports = { overview, feverListItems, digestiveListItems, estrusListItems, epidemicSummary, epidemicContacts };
```

- [x] **Step 3: Update map route with range filter**

In `backend/routes/map.js`, the route already accepts `range` query param and validates it. Add trajectory filtering logic. Replace the file:

```javascript
const { Router } = require('express');
const { authMiddleware, requirePermission } = require('../middleware/auth');
const { animals, fences } = require('../data/seed');

const router = Router();

router.get(
  '/trajectories',
  authMiddleware,
  requirePermission('map:view'),
  (req, res) => {
    const { animalId, range } = req.query;

    if (!range || !['24h', '7d', '30d'].includes(range)) {
      return res.fail(422, 'VALIDATION_ERROR', 'range 必须为 24h / 7d / 30d');
    }

    const selected = animals.find((a) => a.id === animalId) || animals[0];

    const now = new Date('2026-04-08T10:00:00Z');
    const rangeMs = { '24h': 86400000, '7d': 604800000, '30d': 2592000000 }[range];
    const since = new Date(now.getTime() - rangeMs);

    const points = generateTrajectory(selected, since, now);

    res.ok({
      animals: animals.map((a) => ({ id: a.id, earTag: a.earTag, lat: a.lat, lng: a.lng })),
      selectedAnimalId: selected.id,
      selectedRange: range,
      summaryText: `${selected.earTag} · ${range}`,
      points,
      fences,
      fallbackList: animals.slice(0, 5).map((a) => ({ label: `${a.earTag} · 最近点` })),
    });
  }
);

function generateTrajectory(animal, start, end) {
  const points = [];
  let lat = animal.lat;
  let lng = animal.lng;
  let seed = 42 + (animal.earTag || '').length;
  function rand() { seed = (seed * 16807) % 2147483647; return (seed - 1) / 2147483646; }

  const t = new Date(start);
  while (t < end) {
    const hour = t.getUTCHours();
    const step = (hour >= 6 && hour < 18) ? 0.0003 : 0.00005;
    lat += (rand() - 0.5) * step * 2;
    lng += (rand() - 0.5) * step * 2;
    points.push({ lat: +lat.toFixed(4), lng: +lng.toFixed(4), ts: t.toISOString() });
    t.setTime(t.getTime() + 3600000);
  }
  return points;
}

module.exports = router;
```

- [x] **Step 4: Test backend starts correctly**

Run: `cd Mobile/backend && node -e "require('./data/seed'); require('./data/twin_seed'); console.log('OK')"`
Expected: `OK`

- [x] **Step 5: Commit**

```bash
git add backend/data/seed.js backend/data/twin_seed.js backend/routes/map.js
git commit -m "feat: sync backend seed data to 50 cattle/100 devices/18 alerts, add trajectory generation"
```

---

## Task 9: Test Fixes & Final Verification

**Files:**
- Modify: `test/mock_repository_state_test.dart`
- Modify: `test/flow_smoke_test.dart`

- [x] **Step 1: Fix mock_repository_state_test.dart**

In `test/mock_repository_state_test.dart`, update earTag references:

Replace `'耳标-002'` with `'SL-2024-002'` (map test selectedAnimal).

The map test block should become:

```dart
  test('Map mock repository 保留筛选条件并支持全部 ViewState', () {
    const repository = MockMapRepository();

    for (final state in ViewState.values) {
      final data = repository.load(
        viewState: state,
        selectedAnimal: 'SL-2024-002',
        selectedRange: TrajectoryRange.d7,
      );
      expect(data.viewState, state);
      expect(data.selectedAnimal, 'SL-2024-002');
      expect(data.selectedRange, TrajectoryRange.d7);
    }
  });
```

- [x] **Step 2: Fix flow_smoke_test.dart**

In `test/flow_smoke_test.dart`, update the map flow test:

Replace `find.text('耳标-002').last` with `find.text('SL-2024-002').last`.

Replace `contains('耳标-002')` with `contains('SL-2024-002')`.

The map flow test should become:

```dart
  testWidgets('流程2：地图 筛选牲畜与切换回放区间', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-map')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('map-animal-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SL-2024-002').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('7d'));
    await tester.pumpAndSettle();

    final summary =
        tester.widget<Text>(find.byKey(const Key('map-flow-summary')));
    expect(summary.data, contains('SL-2024-002'));
    expect(summary.data, contains('7d'));
  });
```

- [x] **Step 3: Run all tests**

Run: `flutter test`
Expected: All tests PASS

If any test fails, investigate the specific failure. Common issues:
- Other files that reference old earTag format (`耳标-NNN`) — search with: `grep -r '耳标-' test/`
- Dashboard widget key changes — if tests look for `dashboard-metric-alert-pending` or `dashboard-metric-health-watch`, update to new keys
- `DemoSeed.livestockDetail` usage outside of `MockLivestockRepository` — check compile errors

- [x] **Step 4: Run static analysis**

Run: `flutter analyze`
Expected: No errors

- [x] **Step 5: Verify data consistency between Dart and JS seeds**

Manual checklist:
1. ✅ Both have 50 animals with earTag `SL-2024-001` to `SL-2024-050`
2. ✅ Both have 4 fences with matching IDs and coordinates (Dart `LatLng(lat, lng)` vs JS `[lng, lat]`)
3. ✅ Both have 18 alerts with matching IDs and content
4. ✅ Both have dashboard metrics: 牲畜总数=50, 在线设备=85, 今日告警=8, 健康率=92%
5. ✅ TwinSeed: 30 fever baselines, 30 digestive items, 3 estrus items (0012, 0024, 0028)
6. ✅ Pending tasks reference new IDs: 0048, 0049, 0012

- [x] **Step 6: Commit**

```bash
git add test/mock_repository_state_test.dart test/flow_smoke_test.dart
git commit -m "fix: update tests for new earTag format SL-2024-NNN"
```

- [x] **Step 7: Final full test run**

Run: `flutter test && flutter analyze`
Expected: All tests pass, no analysis errors.

---

## Data Alignment Checklist

| Item | Dart (`demo_seed.dart`) | JS (`seed.js`) | Match? |
|------|------------------------|----------------|--------|
| Cattle count | 50 | 50 | ✅ |
| earTag format | `SL-2024-NNN` | `SL-2024-NNN` | ✅ |
| Fence count | 4 | 4 | ✅ |
| Fence IDs | `fence_pasture_a/b`, `fence_rest`, `fence_quarantine` | same | ✅ |
| Coord order | `LatLng(lat, lng)` | `[lng, lat]` | ✅ (reversed) |
| Device count | 100 (50+30+20) | N/A (devices in Dart only) | N/A |
| Alert count | 18 | 18 | ✅ |
| Dashboard metrics | 50/85/8/92% | 50/85/8/92% | ✅ |
| Twin baseline count | 30 | 30 | ✅ |
| Estrus IDs | 0012, 0024, 0028 | 0012, 0024, 0028 | ✅ |
| Pending task IDs | 0048, 0049, 0012 | 0048, 0049, 0012 | ✅ |
