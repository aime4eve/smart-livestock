import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/features/devices/data/devices_api_repository.dart';

void main() {
  group('DevicesApiRepository._parseDeviceItem', () {
    test('GPS tracker with all telemetry fields', () {
      final device = DevicesApiRepository.parseDeviceItemForTest({
        'id': 'dev-1',
        'deviceCode': 'GPS-001',
        'deviceType': 'TRACKER',
        'runtimeStatus': 'ONLINE',
        'batteryLevel': 85,
        'signalStrength': 'strong',
        'lastOnlineAt': '2026-07-01T10:00:00Z',
        'platformDeviceId': 42,
        'rssi': -70,
        'snr': '9.5',
        'lastGateway': 'gw-01',
        'antiDisassemblyStatus': 0,
        'lastTelemetrySyncedAt': '2026-07-01T10:05:00Z',
      });

      expect(device, isNotNull);
      expect(device!.id, 'dev-1');
      expect(device.name, 'GPS-001');
      expect(device.type, DeviceType.gps);
      expect(device.status, DeviceStatus.online);
      expect(device.batteryPercent, 85);
      expect(device.signalStrength, 'strong');
      expect(device.lastSync, '2026-07-01T10:00:00Z');
      expect(device.platformDeviceId, '42');
      expect(device.isPlatformRegistered, isTrue);
      expect(device.rssi, -70);
      expect(device.snr, '9.5');
      expect(device.lastGateway, 'gw-01');
      expect(device.antiDisassemblyStatus, 0);
      expect(device.hasTamperAlert, isFalse);
    });

    test('rumen capsule with capsule alias', () {
      final device = DevicesApiRepository.parseDeviceItemForTest({
        'id': 2,
        'deviceType': 'RUMEN_CAPSULE',
        'runtimeStatus': 'OFFLINE',
        'deviceCode': 'CAP-002',
      });

      expect(device, isNotNull);
      expect(device!.id, '2');
      expect(device.type, DeviceType.rumenCapsule);
      expect(device.status, DeviceStatus.offline);
    });

    test('ear tag type', () {
      final device = DevicesApiRepository.parseDeviceItemForTest({
        'id': '3',
        'deviceType': 'EAR_TAG',
        'runtimeStatus': 'LOW_BATTERY',
        'deviceCode': 'EAR-003',
      });

      expect(device, isNotNull);
      expect(device!.type, DeviceType.earTag);
      expect(device.status, DeviceStatus.lowBattery);
    });

    test('unknown deviceType returns null (graceful skip)', () {
      final device = DevicesApiRepository.parseDeviceItemForTest({
        'id': '4',
        'deviceType': 'UNKNOWN_THING',
        'runtimeStatus': 'ONLINE',
      });
      expect(device, isNull);
    });

    test('missing deviceType returns null', () {
      final device = DevicesApiRepository.parseDeviceItemForTest({
        'id': '5',
        'runtimeStatus': 'ONLINE',
      });
      expect(device, isNull);
    });

    test('status alias ACTIVE maps to online', () {
      final device = DevicesApiRepository.parseDeviceItemForTest({
        'id': '6',
        'deviceType': 'TRACKER',
        'runtimeStatus': 'ACTIVE',
        'deviceCode': 'T-006',
      });
      expect(device, isNotNull);
      expect(device!.status, DeviceStatus.online);
    });

    test('unknown status defaults to offline', () {
      final device = DevicesApiRepository.parseDeviceItemForTest({
        'id': '7',
        'deviceType': 'TRACKER',
        'runtimeStatus': 'WEIRD_STATUS',
        'deviceCode': 'T-007',
      });
      expect(device, isNotNull);
      expect(device!.status, DeviceStatus.offline);
    });

    test('anti-disassembly status non-zero triggers tamper alert', () {
      final device = DevicesApiRepository.parseDeviceItemForTest({
        'id': '8',
        'deviceType': 'EAR_TAG',
        'runtimeStatus': 'ONLINE',
        'deviceCode': 'E-008',
        'antiDisassemblyStatus': 1,
      });
      expect(device, isNotNull);
      expect(device!.hasTamperAlert, isTrue);
    });

    test('GPS alias for deviceType', () {
      final device = DevicesApiRepository.parseDeviceItemForTest({
        'id': '9',
        'deviceType': 'GPS',
        'runtimeStatus': 'ONLINE',
        'deviceCode': 'G-009',
      });
      expect(device, isNotNull);
      expect(device!.type, DeviceType.gps);
    });

    test('CAPSULE alias for deviceType', () {
      final device = DevicesApiRepository.parseDeviceItemForTest({
        'id': '10',
        'deviceType': 'CAPSULE',
        'runtimeStatus': 'ONLINE',
        'deviceCode': 'C-010',
      });
      expect(device, isNotNull);
      expect(device!.type, DeviceType.rumenCapsule);
    });

    test('platformDeviceId as string preserves value', () {
      final device = DevicesApiRepository.parseDeviceItemForTest({
        'id': '11',
        'deviceType': 'TRACKER',
        'runtimeStatus': 'ONLINE',
        'deviceCode': 'T-011',
        'platformDeviceId': '99',
      });
      expect(device, isNotNull);
      expect(device!.platformDeviceId, '99');
    });

    test('large platformDeviceId preserves precision as string', () {
      // blade platform deviceIds exceed JS safe integer range (2^53)
      final device = DevicesApiRepository.parseDeviceItemForTest({
        'id': '14',
        'deviceType': 'TRACKER',
        'runtimeStatus': 'ONLINE',
        'deviceCode': 'T-014',
        'platformDeviceId': '2072879090955759616',
      });
      expect(device, isNotNull);
      expect(device!.platformDeviceId, '2072879090955759616');
      expect(device.isPlatformRegistered, isTrue);
    });

    test('null platformDeviceId means isPlatformRegistered false', () {
      final device = DevicesApiRepository.parseDeviceItemForTest({
        'id': '12',
        'deviceType': 'TRACKER',
        'runtimeStatus': 'ONLINE',
        'deviceCode': 'T-012',
      });
      expect(device, isNotNull);
      expect(device!.isPlatformRegistered, isFalse);
    });

    test('case-insensitive type and status', () {
      final device = DevicesApiRepository.parseDeviceItemForTest({
        'id': '13',
        'deviceType': 'tracker',
        'runtimeStatus': 'online',
        'deviceCode': 'T-013',
      });
      expect(device, isNotNull);
      expect(device!.type, DeviceType.gps);
      expect(device.status, DeviceStatus.online);
    });
  });

  group('parseLicenseForTest', () {
    test('full license data', () {
      final lic = DevicesApiRepository.parseLicenseForTest({
        'id': 'lic-1',
        'deviceId': 'dev-1',
        'licenseKey': 'KEY-ABC123',
        'status': 'active',
      });
      expect(lic.id, 'lic-1');
      expect(lic.deviceId, 'dev-1');
      expect(lic.licenseKey, 'KEY-ABC123');
      expect(lic.status, 'active');
    });

    test('int id converted to string', () {
      final lic = DevicesApiRepository.parseLicenseForTest({
        'id': 100,
        'deviceId': 200,
      });
      expect(lic.id, '100');
      expect(lic.deviceId, '200');
      expect(lic.status, 'active');
    });

    test('missing fields default to empty/active', () {
      final lic = DevicesApiRepository.parseLicenseForTest({});
      expect(lic.id, '');
      expect(lic.deviceId, '');
      expect(lic.licenseKey, '');
      expect(lic.status, 'active');
    });
  });

  group('parseInstallationForTest', () {
    test('full installation data', () {
      final inst = DevicesApiRepository.parseInstallationForTest({
        'id': 'inst-1',
        'deviceId': 'dev-1',
        'livestockId': 'liv-1',
        'installedAt': '2026-06-01T08:00:00Z',
      });
      expect(inst.id, 'inst-1');
      expect(inst.deviceId, 'dev-1');
      expect(inst.livestockId, 'liv-1');
      expect(inst.installedAt, '2026-06-01T08:00:00Z');
    });

    test('int ids converted to string', () {
      final inst = DevicesApiRepository.parseInstallationForTest({
        'id': 1,
        'deviceId': 2,
        'livestockId': 3,
      });
      expect(inst.id, '1');
      expect(inst.deviceId, '2');
      expect(inst.livestockId, '3');
      expect(inst.installedAt, '');
    });
  });

  group('parseGpsPointForTest', () {
    test('lat/lng aliases', () {
      final pt = DevicesApiRepository.parseGpsPointForTest({
        'lat': 28.246,
        'lng': 112.852,
        'timestamp': '2026-07-01T10:00:00Z',
      });
      expect(pt.lat, 28.246);
      expect(pt.lng, 112.852);
      expect(pt.timestamp, '2026-07-01T10:00:00Z');
    });

    test('latitude/longitude full names', () {
      final pt = DevicesApiRepository.parseGpsPointForTest({
        'latitude': 28.246,
        'longitude': 112.852,
        'timestamp': '2026-07-01T10:00:00Z',
        'livestockId': 'liv-1',
      });
      expect(pt.lat, 28.246);
      expect(pt.lng, 112.852);
      expect(pt.livestockId, 'liv-1');
    });

    test('missing coords default to 0.0', () {
      final pt = DevicesApiRepository.parseGpsPointForTest({
        'timestamp': '2026-07-01T10:00:00Z',
      });
      expect(pt.lat, 0.0);
      expect(pt.lng, 0.0);
    });

    test('int coords converted to double', () {
      final pt = DevicesApiRepository.parseGpsPointForTest({
        'lat': 28,
        'lng': 112,
        'timestamp': '',
      });
      expect(pt.lat, 28.0);
      expect(pt.lng, 112.0);
    });
  });
}
