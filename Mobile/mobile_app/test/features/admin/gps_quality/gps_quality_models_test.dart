import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';

void main() {
  group('BatchParseResult.fromJson', () {
    test('parses counts and rows per backend contract', () {
      final result = BatchParseResult.fromJson({
        'totalRows': 8,
        'okCount': 5,
        'warnCount': 2,
        'errorCount': 1,
        'rows': [
          {
            'rowIndex': 1,
            'eui': '847A000000000F03',
            'deviceCode': 'DEV-GPS-001',
            'testType': 'STATIC',
            'refName': '11号点 - 北门',
            'rtkPointId': 11,
            'routeId': null,
            'startedAt': '2026-07-18T09:00:00Z',
            'endedAt': '2026-07-18T10:00:00Z',
            'preStatus': 'OK',
            'message': null,
          },
          {
            'rowIndex': 2,
            'eui': 'A2B4000000000C19',
            'deviceCode': null,
            'testType': 'DYNAMIC',
            'refName': '北门短测线',
            'rtkPointId': null,
            'routeId': 5,
            'startedAt': '2026-07-18T14:00:00Z',
            'endedAt': null,
            'preStatus': 'WARN',
            'message': '设备未激活',
          },
        ],
      });

      expect(result.totalRows, 8);
      expect(result.okCount, 5);
      expect(result.warnCount, 2);
      expect(result.errorCount, 1);
      expect(result.rows, hasLength(2));

      final r1 = result.rows[0];
      expect(r1.rowIndex, 1);
      expect(r1.eui, '847A000000000F03');
      expect(r1.deviceCode, 'DEV-GPS-001');
      expect(r1.testType, 'STATIC');
      expect(r1.rtkPointId, 11);
      expect(r1.routeId, isNull);
      expect(r1.preStatus, 'OK');
      expect(r1.startedAt, DateTime.parse('2026-07-18T09:00:00Z'));
      expect(r1.endedAt, isNotNull);

      final r2 = result.rows[1];
      expect(r2.deviceCode, isNull);
      expect(r2.routeId, 5);
      expect(r2.preStatus, 'WARN');
      expect(r2.message, '设备未激活');
      expect(r2.endedAt, isNull);
    });

    test('tolerates missing optional fields', () {
      final result = BatchParseResult.fromJson(const {});
      expect(result.totalRows, 0);
      expect(result.rows, isEmpty);
    });
  });

  group('DynamicComparisonResult.fromJson', () {
    test('parses device summaries per backend contract', () {
      final result = DynamicComparisonResult.fromJson({
        'routeId': 5,
        'routeName': '线路1',
        'devices': [
          {
            'deviceId': 12,
            'deviceCode': 'DEV-GPS-001',
            'checkId': 64,
            'coverage': 0.833,
            'matchedCount': 5,
            'missedCount': 1,
            'ambiguousCount': 0,
            'inOrder': true,
            'meanError': 7.8,
            'p50': 6.2,
            'p95': 12.1,
            'startedAt': '2026-07-18T09:00:00Z',
            'endedAt': '2026-07-18T10:00:00Z',
          },
        ],
      });

      expect(result.routeId, 5);
      expect(result.routeName, '线路1');
      expect(result.devices, hasLength(1));
      final d = result.devices.first;
      expect(d.deviceId, 12);
      expect(d.deviceCode, 'DEV-GPS-001');
      expect(d.checkId, 64);
      expect(d.coverage, closeTo(0.833, 1e-9));
      expect(d.matchedCount, 5);
      expect(d.missedCount, 1);
      expect(d.ambiguousCount, 0);
      expect(d.inOrder, isTrue);
      expect(d.meanError, closeTo(7.8, 1e-9));
      expect(d.p50, closeTo(6.2, 1e-9));
      expect(d.p95, closeTo(12.1, 1e-9));
      expect(d.startedAt, isNotNull);
    });
  });
}
