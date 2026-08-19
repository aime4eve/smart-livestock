import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/admin/datagen/domain/datagen_models.dart';

void main() {
  test('parses console response and nullable fields defensively', () {
    final console = DatagenConsoleData.fromJson({
      'farm': {
        'farmId': 1,
        'farmName': 'Main Ranch',
        'tenantId': 2,
        'tenantName': 'Demo',
        'enabled': true,
        'selectedDeviceCount': 1,
      },
      'enabled': true,
      'scenario': {
        'id': 3,
        'name': 'NORMAL',
        'type': 'normal',
      },
      'rules': {
        'trackerIntervalSeconds': 600,
        'capsuleIntervalSeconds': 1200,
        'fenceExcursionProbability': 0.05,
        'fenceExcursionMinMinutes': 10,
        'fenceExcursionMaxMinutes': 20,
        'healthEventProbability': 0.01,
        'feverDurationMinMinutes': 180,
        'feverDurationMaxMinutes': 300,
        'motilityDurationMinMinutes': 480,
        'motilityDurationMaxMinutes': 720,
      },
      'devices': [
        {
          'deviceId': 5,
          'deviceCode': 'TRK-5',
          'devEui': 'eui-5',
          'deviceType': 'TRACKER',
          'livestockId': 10,
          'livestockCode': 'ST-10',
          'runtimeStatus': 'online',
          'selected': true,
          'eligible': true,
          'lastGeneratedAt': '2026-08-17T08:00:00Z',
        },
      ],
      'stats': {
        'statsTimeZone': 'Asia/Shanghai',
        'selectedTotal': 1,
        'selectedTrackerCount': 1,
        'selectedCapsuleCount': 0,
        'todayTelemetryRows': 3,
        'todayGpsRows': 2,
        'todayHealthRows': 1,
        'lastGeneratedAt': '2026-08-17T08:00:00Z',
      },
      'operations': [
        {
          'id': 4,
          'action': 'START',
          'operatorId': 6,
          'operatorRole': 'B2B_ADMIN',
          'occurredAt': '2026-08-17T08:00:00Z',
          'summary': 'datagenConsoleOperationStart',
        },
      ],
    });

    expect(console.farm.farmName, 'Main Ranch');
    expect(console.devices.single.selected, isTrue);
    expect(console.stats.todayTelemetryRows, 3);
    expect(console.rules.trackerIntervalSeconds, 600);
    expect(console.rules.fenceExcursionProbability, 0.05);
    expect(console.rules.feverDurationMinMinutes, 180);
    expect(console.operations.single.summaryKey,
        'datagenConsoleOperationStart');
  });

  test('clear result computes total deleted', () {
    final result = DatagenClearResult.fromJson({
      'telemetryRows': 1,
      'gpsRows': 2,
      'temperatureRows': 3,
      'motilityRows': 4,
      'activityRows': 5,
      'estrusRows': 6,
      'anomalyRows': 7,
      'alertRows': 8,
      'unattributableHealthRows': 9,
      'unattributableAlertRows': 10,
      'limitationKey': 'datagenConsoleCrossFarmLimit',
    });

    expect(result.totalDeleted, 36);
    expect(result.unattributableHealthRows, 9);
  });
}
