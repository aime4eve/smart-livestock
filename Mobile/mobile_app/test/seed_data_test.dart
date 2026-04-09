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
