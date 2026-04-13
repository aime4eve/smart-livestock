import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/features/devices/data/live_devices_repository.dart';

void main() {
  test('parseDeviceMap 与 DemoSeed 首条 GPS 设备一致', () {
    final expected = DemoSeed.devices.first;
    final m = <String, dynamic>{
      'id': expected.id,
      'name': expected.name,
      'type': 'gps',
      'status': 'online',
      'boundEarTag': expected.boundEarTag,
      'batteryPercent': expected.batteryPercent,
      'signalStrength': expected.signalStrength,
      'lastSync': expected.lastSync,
    };
    final parsed = LiveDevicesRepository.parseDeviceMap(m);
    expect(parsed, isNotNull);
    expect(parsed!.id, expected.id);
    expect(parsed.name, expected.name);
    expect(parsed.type, DeviceType.gps);
    expect(parsed.status, DeviceStatus.online);
    expect(parsed.boundEarTag, expected.boundEarTag);
  });
}
