import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/admin/telemetry_import/domain/telemetry_import_models.dart';

void main() {
  group('TelemetryParseResult.fromJson', () {
    test('完整 JSON 解析：统计 + 设备匹配 + 逐行状态', () {
      final result = TelemetryParseResult.fromJson(const {
        'totalRows': 9,
        'uplinkRows': 8,
        'decodableRows': 6,
        'importableRows': 4,
        'gpsPointRows': 3,
        'duplicateRows': 1,
        'skippedRows': 2,
        'invalidRows': 1,
        'device': {
          'matched': true,
          'devEui': '0095690600028577',
          'deviceCode': 'GPS-0095690600028577',
          'deviceType': 'TRACKER',
          'livestockName': '黄牛 N-1024',
          'farmName': '长沙示范牧场',
          'error': null,
        },
        'rows': [
          {
            'rowNo': 2,
            'frameCounter': '119',
            'recordTime': '2026-07-23T16:09:11Z',
            'battery': 99,
            'latitude': 28.246777,
            'longitude': 112.851138,
            'stepCount': 27,
            'status': 'IMPORTABLE',
            'error': null,
          },
          {
            'rowNo': 7,
            'frameCounter': '',
            'recordTime': '2026-07-23T16:03:40Z',
            'battery': null,
            'latitude': null,
            'longitude': null,
            'stepCount': null,
            'status': 'SKIPPED_DOWNLINK',
            'error': null,
          },
          {
            'rowNo': 9,
            'frameCounter': '111',
            'recordTime': '2026-07-23T16:02:58Z',
            'battery': 99,
            'latitude': 28.245401,
            'longitude': 112.852496,
            'stepCount': 17,
            'status': 'INVALID',
            'error': 'error.telemetryImport.invalidTime',
          },
        ],
      });

      expect(result.totalRows, 9);
      expect(result.uplinkRows, 8);
      expect(result.decodableRows, 6);
      expect(result.importableRows, 4);
      expect(result.gpsPointRows, 3);
      expect(result.duplicateRows, 1);
      expect(result.skippedRows, 2);
      expect(result.invalidRows, 1);

      final device = result.device;
      expect(device.matched, isTrue);
      expect(device.devEui, '0095690600028577');
      expect(device.deviceCode, 'GPS-0095690600028577');
      expect(device.deviceType, 'TRACKER');
      expect(device.livestockName, '黄牛 N-1024');
      expect(device.farmName, '长沙示范牧场');
      expect(device.error, isNull);

      expect(result.rows, hasLength(3));
      final first = result.rows[0];
      expect(first.rowNo, 2);
      expect(first.frameCounter, '119');
      expect(first.recordTime, DateTime.utc(2026, 7, 23, 16, 9, 11));
      expect(first.battery, 99);
      expect(first.latitude, closeTo(28.246777, 1e-9));
      expect(first.longitude, closeTo(112.851138, 1e-9));
      expect(first.stepCount, 27);
      expect(first.status, TelemetryRowStatus.importable);
      expect(first.error, isNull);

      expect(result.rows[1].status, TelemetryRowStatus.skippedDownlink);
      expect(result.rows[1].battery, isNull);
      expect(result.rows[1].latitude, isNull);

      final invalid = result.rows[2];
      expect(invalid.status, TelemetryRowStatus.invalid);
      expect(invalid.error, 'error.telemetryImport.invalidTime');
    });

    test('状态枚举映射：五态 + 未知兜底 unknown', () {
      TelemetryRowStatus statusOf(String s) => TelemetryRowPreview.fromJson(
          {'rowNo': 1, 'status': s}).status;
      expect(statusOf('IMPORTABLE'), TelemetryRowStatus.importable);
      expect(statusOf('DUPLICATE'), TelemetryRowStatus.duplicate);
      expect(statusOf('SKIPPED_DOWNLINK'), TelemetryRowStatus.skippedDownlink);
      expect(statusOf('SKIPPED_UNSUPPORTED'),
          TelemetryRowStatus.skippedUnsupported);
      expect(statusOf('INVALID'), TelemetryRowStatus.invalid);
      expect(statusOf('SOMETHING_NEW'), TelemetryRowStatus.unknown);
      expect(statusOf(''), TelemetryRowStatus.unknown);
    });

    test('防御性解析：缺字段/类型偏差不抛异常', () {
      final result = TelemetryParseResult.fromJson(const {
        'totalRows': '408', // string form is coerced
        'rows': [
          {'rowNo': 2}, // everything else missing
          'not-a-map', // filtered out
        ],
        // no device, no counters
      });
      expect(result.totalRows, 408);
      expect(result.device.matched, isFalse);
      expect(result.rows, hasLength(1));
      expect(result.rows[0].rowNo, 2);
      expect(result.rows[0].recordTime, isNull);
      expect(result.rows[0].status, TelemetryRowStatus.unknown);

      final empty = TelemetryParseResult.fromJson(const {});
      expect(empty.totalRows, 0);
      expect(empty.rows, isEmpty);
      expect(empty.device.matched, isFalse);
    });

    test('设备未匹配：error key 保留', () {
      final device = TelemetryDeviceMatch.fromJson(const {
        'matched': false,
        'devEui': '0095690600028577',
        'error': 'error.telemetryImport.deviceNotRegistered',
      });
      expect(device.matched, isFalse);
      expect(device.error, 'error.telemetryImport.deviceNotRegistered');
      expect(device.deviceCode, '');
    });

    test('数值强转：int 经纬度转 double、num 计数转 int', () {
      final row = TelemetryRowPreview.fromJson(const {
        'rowNo': 2.0,
        'battery': 99.0,
        'latitude': 28, // int literal
        'longitude': 112,
        'stepCount': 27.0,
      });
      expect(row.rowNo, 2);
      expect(row.battery, 99);
      expect(row.latitude, 28.0);
      expect(row.longitude, 112.0);
      expect(row.stepCount, 27);
    });
  });

  group('TelemetryImportResult.fromJson', () {
    test('完整 JSON 解析', () {
      final result = TelemetryImportResult.fromJson(const {
        'telemetryCreated': 387,
        'gpsCreated': 387,
        'duplicateSkipped': 3,
        'skippedRows': 18,
        'invalidRows': 0,
        'failedRows': 0,
        'devEui': '0095690600028577',
        'deviceCode': 'GPS-0095690600028577',
      });
      expect(result.telemetryCreated, 387);
      expect(result.gpsCreated, 387);
      expect(result.duplicateSkipped, 3);
      expect(result.skippedRows, 18);
      expect(result.invalidRows, 0);
      expect(result.failedRows, 0);
      expect(result.devEui, '0095690600028577');
      expect(result.deviceCode, 'GPS-0095690600028577');
    });

    test('防御性解析：空 JSON 全默认值', () {
      final result = TelemetryImportResult.fromJson(const {});
      expect(result.telemetryCreated, 0);
      expect(result.gpsCreated, 0);
      expect(result.devEui, '');
      expect(result.deviceCode, '');
    });
  });
}
