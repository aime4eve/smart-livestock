import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';

void main() {
  group('RanchOverviewStats', () {
    test('parses inFenceRate', () {
      final stats = RanchOverviewStats.fromJson({
        'totalLivestock': 256,
        'healthyRate': 0.94,
        'alertCount': 3,
        'criticalCount': 1,
        'deviceOnlineRate': 0.95,
        'inFenceRate': 0.98,
      });
      expect(stats.inFenceRate, 0.98);
    });

    test('inFenceRate defaults to 0 when missing', () {
      final stats = RanchOverviewStats.fromJson({});
      expect(stats.inFenceRate, 0.0);
    });
  });

  group('RanchAlertData', () {
    test('parses read field', () {
      final alert = RanchAlertData.fromJson({
        'id': '1',
        'type': 'FENCE_BREACH',
        'severity': 'CRITICAL',
        'status': 'ACTIVE',
        'message': 'test',
        'read': true,
        'distance': 120.5,
        'direction': 'NW',
      });
      expect(alert.read, true);
      expect(alert.distance, 120.5);
      expect(alert.direction, 'NW');
    });

    test('read defaults to false', () {
      final alert = RanchAlertData.fromJson({
        'id': '1',
        'type': 'TEMPERATURE_ABNORMAL',
        'severity': 'WARNING',
        'status': 'ACTIVE',
        'message': 'test',
      });
      expect(alert.read, false);
      expect(alert.distance, isNull);
    });

    test('parses resolvedType and resolvedAt', () {
      final alert = RanchAlertData.fromJson({
        'id': '1',
        'type': 'FENCE_BREACH',
        'severity': 'WARNING',
        'status': 'AUTO_RESOLVED',
        'message': 'test',
        'resolvedType': 'AUTO',
        'resolvedAt': '2026-06-10T08:30:00Z',
      });
      expect(alert.resolvedType, 'AUTO');
      expect(alert.resolvedAt, '2026-06-10T08:30:00Z');
    });

    test('copyWith works', () {
      final alert = RanchAlertData.fromJson({
        'id': '1',
        'type': 'FENCE_BREACH',
        'severity': 'CRITICAL',
        'status': 'ACTIVE',
        'message': 'test',
      });
      final updated = alert.copyWith(read: true);
      expect(updated.read, true);
      expect(updated.id, '1');
      expect(updated.type, 'FENCE_BREACH');
    });
  });

  group('RanchOverview', () {
    test('parses fence and health summaries', () {
      final overview = RanchOverview.fromJson({
        'overallStats': {
          'totalLivestock': 256,
          'healthyRate': 0.94,
          'alertCount': 5,
          'criticalCount': 1,
          'deviceOnlineRate': 0.95,
          'inFenceRate': 0.98,
        },
        'fenceAlertSummary': {
          'FENCE_BREACH': 1,
          'FENCE_APPROACH': 2,
          'ZONE_APPROACH': 1,
        },
        'healthAlertSummary': {
          'TEMPERATURE_ABNORMAL': 2,
          'DIGESTIVE_ABNORMAL': 1,
          'ESTRUS': 3,
        },
        'alerts': [],
        'fences': [],
        'livestockMarkers': [],
        'sceneSummary': null,
        'pendingTasks': [],
      });
      expect(overview.fenceAlertSummary['FENCE_BREACH'], 1);
      expect(overview.fenceAlertSummary['FENCE_APPROACH'], 2);
      expect(overview.healthAlertSummary['ESTRUS'], 3);
      expect(overview.overallStats.inFenceRate, 0.98);
    });

    test('summaries default to empty map', () {
      final overview = RanchOverview.fromJson({
        'overallStats': {},
        'alerts': [],
        'fences': [],
        'livestockMarkers': [],
        'sceneSummary': null,
        'pendingTasks': [],
      });
      expect(overview.fenceAlertSummary, isEmpty);
      expect(overview.healthAlertSummary, isEmpty);
      expect(overview.fenceZones, isEmpty);
    });
  });

  group('FenceZoneData', () {
    test('parses from JSON', () {
      final zone = FenceZoneData.fromJson({
        'id': 1,
        'fenceId': 2,
        'name': '水源区',
        'zoneType': 'WATER_SOURCE',
        'alertRadius': 30,
        'severity': 'WARNING',
      });
      expect(zone.id, '1');
      expect(zone.fenceId, '2');
      expect(zone.name, '水源区');
      expect(zone.zoneType, 'WATER_SOURCE');
      expect(zone.alertRadius, 30);
    });
  });

  group('RanchOverview copyWith', () {
    test('updates alerts list', () {
      final overview = RanchOverview.fromJson({
        'overallStats': {},
        'alerts': [],
        'fences': [],
        'livestockMarkers': [],
        'sceneSummary': null,
        'pendingTasks': [],
      });
      final newAlerts = [
        RanchAlertData.fromJson({
          'id': '1',
          'type': 'FENCE_BREACH',
          'severity': 'CRITICAL',
          'status': 'ACTIVE',
          'message': 'test',
          'read': true,
        }),
      ];
      final updated = overview.copyWith(alerts: newAlerts);
      expect(updated.alerts.length, 1);
      expect(updated.alerts[0].read, true);
    });
  });
}
