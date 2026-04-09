import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/alerts/data/mock_alerts_repository.dart';
import 'package:smart_livestock_demo/features/alerts/domain/alerts_repository.dart';

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
}
