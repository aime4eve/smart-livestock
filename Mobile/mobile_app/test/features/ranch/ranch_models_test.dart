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

    test('inFenceRate is null when missing', () {
      final stats = RanchOverviewStats.fromJson({});
      expect(stats.inFenceRate, isNull);
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

  group('RanchSceneSummary calving/gating (NIX-389)', () {
    test('parses calving counts and three-state gating', () {
      final scene = RanchSceneSummary.fromJson({
        'calving': {'highRiskCount': 3, 'watchCount': 5},
        'gating': {
          'fever': 'OPEN',
          'digestive': 'LOCKED',
          'estrus': 'HIDDEN',
          'epidemic': 'OPEN',
          'ai': 'LOCKED',
          'calving': 'OPEN',
        },
      });
      expect(scene.calving.highRiskCount, 3);
      expect(scene.calving.watchCount, 5);
      expect(scene.gating.fever, SceneGatingState.open);
      expect(scene.gating.digestive, SceneGatingState.locked);
      expect(scene.gating.estrus, SceneGatingState.hidden);
      expect(scene.gating.epidemic, SceneGatingState.open);
      expect(scene.gating.ai, SceneGatingState.locked);
      expect(scene.gating.calving, SceneGatingState.open);
    });

    test('unknown gating value falls back to locked (fail closed)', () {
      final scene = RanchSceneSummary.fromJson({
        'gating': {'calving': 'MAYBE', 'fever': 42},
      });
      expect(scene.gating.calving, SceneGatingState.locked);
      expect(scene.gating.fever, SceneGatingState.locked);
    });

    test('missing gating object means all open (legacy payload)', () {
      final scene = RanchSceneSummary.fromJson({});
      expect(scene.gating.fever, SceneGatingState.open);
      expect(scene.gating.digestive, SceneGatingState.open);
      expect(scene.gating.estrus, SceneGatingState.open);
      expect(scene.gating.epidemic, SceneGatingState.open);
      expect(scene.gating.ai, SceneGatingState.open);
      expect(scene.gating.calving, SceneGatingState.open);
      expect(scene.calving.highRiskCount, 0);
      expect(scene.calving.watchCount, 0);
    });

    test('missing gating field inside the object locks that scene', () {
      final scene = RanchSceneSummary.fromJson({
        'gating': {'fever': 'OPEN'},
      });
      expect(scene.gating.fever, SceneGatingState.open);
      expect(scene.gating.estrus, SceneGatingState.locked);
      expect(scene.gating.calving, SceneGatingState.locked);
    });
  });

  group('RanchFenceData buffer geometry (NIX-412)', () {
    test('parses backend bufferPolygon and bufferDistance', () {
      final fence = RanchFenceData.fromJson({
        'id': '6',
        'name': 'Watering Zone',
        'points': [
          {'lat': 28.2, 'lng': 112.9},
          {'lat': 28.21, 'lng': 112.9},
          {'lat': 28.21, 'lng': 112.91},
        ],
        'bufferPolygon': [
          {'lat': 28.199, 'lng': 112.899},
          {'lat': 28.211, 'lng': 112.899},
          {'lat': 28.211, 'lng': 112.911},
        ],
        'bufferDistance': 50,
      });
      expect(fence.bufferPoints, hasLength(3));
      expect(fence.bufferPoints.first.latitude, closeTo(28.199, 1e-9));
      expect(fence.bufferDistance, 50);
    });

    test('missing bufferPolygon degrades to empty, distance defaults to 50',
        () {
      final fence = RanchFenceData.fromJson({'id': '1', 'name': 'legacy'});
      expect(fence.bufferPoints, isEmpty);
      expect(fence.bufferDistance, 50);
    });
  });
}
