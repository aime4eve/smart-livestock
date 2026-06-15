import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';

void main() {
  group('RanchOverview', () {
    test('fromJson 正确解析完整响应', () {
      final json = {
        'overallStats': {
          'totalLivestock': 42,
          'healthyRate': 0.928,
          'alertCount': 3,
          'criticalCount': 1,
          'deviceOnlineRate': 0.85,
        },
        'sceneSummary': {
          'fever': {'abnormalCount': 1, 'criticalCount': 1},
          'digestive': {'abnormalCount': 0, 'watchCount': 1},
          'estrus': {'highScoreCount': 0},
          'epidemic': {'abnormalRate': 0.02},
        },
        'pendingTasks': [
          {
            'id': 't1',
            'title': '牛#023 高烧',
            'subtitle': '体温异常',
            'routePath': '/twin/fever/23',
            'severity': 'CRITICAL',
          },
        ],
        'fences': [
          {
            'id': 1,
            'name': '东区',
            'active': true,
            'type': 'POLYGON',
            'color': '#FF4C9A5F',
            'points': [
              {'lat': 28.246, 'lng': 112.852},
              {'lat': 28.247, 'lng': 112.853},
              {'lat': 28.245, 'lng': 112.854},
            ],
            'areaHectares': 12.5,
            'livestockCount': 12,
            'version': 1,
          },
        ],
        'livestockMarkers': [
          {
            'livestockId': '23',
            'livestockCode': 'SL-2024-023',
            'latitude': 28.246,
            'longitude': 112.852,
            'healthStatus': 'CRITICAL',
            'primaryAlert': 'FEVER',
          },
        ],
        'alerts': [
          {
            'id': 5,
            'type': 'FENCE_BREACH',
            'severity': 'HIGH',
            'status': 'PENDING',
            'message': '耳标-001 越界',
            'livestockId': 1,
            'fenceId': 3,
            'occurredAt': null,
          },
        ],
      };

      final overview = RanchOverview.fromJson(json);

      expect(overview.overallStats.totalLivestock, 42);
      expect(overview.overallStats.healthyRate, 0.928);
      expect(overview.overallStats.alertCount, 3);
      expect(overview.overallStats.criticalCount, 1);
      expect(overview.overallStats.deviceOnlineRate, 0.85);

      expect(overview.sceneSummary.fever.abnormalCount, 1);
      expect(overview.sceneSummary.fever.criticalCount, 1);
      expect(overview.sceneSummary.digestive.abnormalCount, 0);
      expect(overview.sceneSummary.digestive.watchCount, 1);
      expect(overview.sceneSummary.estrus.highScoreCount, 0);
      expect(overview.sceneSummary.epidemic.abnormalRate, 0.02);

      expect(overview.pendingTasks.length, 1);
      expect(overview.pendingTasks[0].severity, 'CRITICAL');

      expect(overview.fences.length, 1);
      expect(overview.fences[0].name, '东区');
      expect(overview.fences[0].points.length, 3);

      expect(overview.livestockMarkers.length, 1);
      expect(overview.livestockMarkers[0].healthStatus, 'CRITICAL');
      expect(overview.livestockMarkers[0].primaryAlert, 'FEVER');

      expect(overview.alerts.length, 1);
      expect(overview.alerts[0].type, 'FENCE_BREACH');
    });

    test('livestockMarkers healthStatus 映射 NORMAL/WARNING/CRITICAL', () {
      for (final status in ['NORMAL', 'WARNING', 'CRITICAL']) {
        final m = RanchLivestockMarker.fromJson({
          'livestockId': '1',
          'livestockCode': 'SL-001',
          'latitude': 28.0,
          'longitude': 112.0,
          'healthStatus': status,
          'primaryAlert': '',
        });
        expect(m.healthStatus, status);
      }
    });

    test('RanchFenceData 颜色解析支持多种格式', () {
      // #RRGGBB
      expect(
        RanchFenceData.fromJson({
          'id': 1, 'name': 'a', 'active': true, 'type': 'POLYGON',
          'color': '#4C9A5F', 'points': [], 'areaHectares': 0, 'livestockCount': 0, 'version': 1,
        }).colorValue,
        0xFF4C9A5F,
      );
      // 0xFFRRGGBB
      expect(
        RanchFenceData.fromJson({
          'id': 2, 'name': 'b', 'active': true, 'type': 'POLYGON',
          'color': '0xFF4C9A5F', 'points': [], 'areaHectares': 0, 'livestockCount': 0, 'version': 1,
        }).colorValue,
        0xFF4C9A5F,
      );
      // #AARRGGBB
      expect(
        RanchFenceData.fromJson({
          'id': 3, 'name': 'c', 'active': true, 'type': 'POLYGON',
          'color': '#804C9A5F', 'points': [], 'areaHectares': 0, 'livestockCount': 0, 'version': 1,
        }).colorValue,
        0x804C9A5F,
      );
    });

    test('空列表安全 — fences/markers/alerts 为空不抛异常', () {
      final overview = RanchOverview.fromJson({
        'overallStats': {
          'totalLivestock': 0,
          'healthyRate': 0.0,
          'alertCount': 0,
          'criticalCount': 0,
          'deviceOnlineRate': 0.0,
        },
        'sceneSummary': null,
        'pendingTasks': null,
        'fences': null,
        'livestockMarkers': null,
        'alerts': null,
      });

      expect(overview.fences, isEmpty);
      expect(overview.livestockMarkers, isEmpty);
      expect(overview.alerts, isEmpty);
      expect(overview.pendingTasks, isEmpty);
    });

    test('null 字段兜底为默认值', () {
      final m = RanchLivestockMarker.fromJson({});
      expect(m.livestockId, '');
      expect(m.livestockCode, '');
      expect(m.latitude, 0.0);
      expect(m.longitude, 0.0);
      expect(m.healthStatus, 'NORMAL');
      expect(m.primaryAlert, '');
    });

    test('RanchAlertData 类型解析', () {
      final a = RanchAlertData.fromJson({
        'id': 10,
        'type': 'TEMPERATURE_ABNORMAL',
        'severity': 'WARNING',
        'status': 'ACKNOWLEDGED',
        'message': '温度偏高',
        'livestockId': 5,
        'fenceId': null,
        'occurredAt': '2026-06-08T10:30:00Z',
      });
      expect(a.id, '10');
      expect(a.type, 'TEMPERATURE_ABNORMAL');
      expect(a.severity, 'WARNING');
      expect(a.status, 'ACKNOWLEDGED');
      expect(a.message, '温度偏高');
      expect(a.livestockId, '5');
      expect(a.fenceId, isNull);
    });

    test('RanchPendingTask 完整性', () {
      final t = RanchPendingTask.fromJson({
        'id': 'task-1',
        'title': '牛#023 发热预警',
        'subtitle': '体温异常需关注',
        'routePath': '/twin/fever/23',
        'severity': 'WARNING',
      });
      expect(t.id, 'task-1');
      expect(t.title, '牛#023 发热预警');
      expect(t.subtitle, '体温异常需关注');
      expect(t.routePath, '/twin/fever/23');
      expect(t.severity, 'WARNING');
    });
  });
}
