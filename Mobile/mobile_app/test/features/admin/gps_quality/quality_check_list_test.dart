import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/quality_check_list.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class _FakeRepo extends GpsQualityApiRepository {
  List<int>? lastCheckIds;
  bool retryAll = false;
  int? deletedDeviceId;

  @override
  Future<List<RowResult>> retryRegistration({List<int>? checkIds}) async {
    if (checkIds == null) {
      retryAll = true;
    } else {
      lastCheckIds = checkIds;
    }
    return [];
  }

  @override
  Future<int> deleteChecksByDevice(int deviceId) async {
    deletedDeviceId = deviceId;
    return 2;
  }

  @override
  Future<GpsQualityReport> fetchReport(int sessionId,
          {bool excludeSuspect = false}) async =>
      GpsQualityReport(
        sessionId: sessionId,
        deviceCode: '847A000000000F03',
        rtkPoint: const RtkPoint(
            id: 11,
            locationName: '北门',
            pointLabel: '11号点',
            latitude: 28.2,
            longitude: 112.9),
        startedAt: DateTime(2026, 7, 18, 9),
        stats: const GpsQualityStats(
            totalPoints: 42,
            suspectPoints: 0,
            effectivePoints: 42,
            meanError: 1.8,
            p50: 2.1,
            p95: 3.2,
            maxError: 5.1,
            jitterDiameter: 5.1,
            outlierCount: 0,
            within15m: 98,
            within25m: 100,
            within40m: 100),
        grade: QualityGrade.excellent,
        scatter: const [],
      );
}

class _FakeChecks extends ChecksController {
  _FakeChecks(this._data);
  final QualityCheckListResult _data;
  @override
  Future<QualityCheckListResult> build() async => _data;
}

class _FakeRtkPoints extends RtkPointsController {
  @override
  Future<List<RtkPoint>> build() async => [];
}

QualityCheck _check({
  required int id,
  required String deviceCode,
  required int deviceId,
  required String status,
  required DateTime startedAt,
  String? errorMessage,
}) =>
    QualityCheck(
      id: id,
      deviceCode: deviceCode,
      deviceId: deviceId,
      checkType: 'STATIC',
      rtkPointId: 11,
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(hours: 1)),
      status: status,
      errorMessage: errorMessage,
    );

QualityCheckListResult _testData() => QualityCheckListResult(items: [
      _check(
          id: 1,
          deviceCode: '847A000000000F03',
          deviceId: 11,
          status: 'READY',
          startedAt: DateTime(2026, 7, 18, 9)),
      _check(
          id: 2,
          deviceCode: '847A000000000F03',
          deviceId: 11,
          status: 'READY',
          startedAt: DateTime(2026, 7, 18, 12)),
      _check(
          id: 3,
          deviceCode: 'F1C2000000000D88',
          deviceId: 12,
          status: 'DEVICE_PENDING',
          startedAt: DateTime(2026, 7, 18, 8)),
      _check(
          id: 4,
          deviceCode: 'EFFF000000000000',
          deviceId: 13,
          status: 'FAILED',
          startedAt: DateTime(2026, 7, 18, 10),
          errorMessage: 'EUI格式无效'),
    ]);

Future<_FakeRepo> _pumpList(WidgetTester tester) async {
  final repo = _FakeRepo();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      checksProvider.overrideWith(() => _FakeChecks(_testData())),
      rtkPointsProvider.overrideWith(() => _FakeRtkPoints()),
      gpsQualityApiRepositoryProvider.overrideWithValue(repo),
    ],
    child: const MaterialApp(
      locale: Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: QualityCheckList()),
    ),
  ));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('搜索框按 EUI 子串过滤设备分组（大小写不敏感）', (tester) async {
    await _pumpList(tester);
    expect(find.byKey(const ValueKey('device-group-847A000000000F03')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('device-group-F1C2000000000D88')),
        findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('device-search-field')), 'f03');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('device-group-847A000000000F03')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('device-group-F1C2000000000D88')),
        findsNothing);
    expect(find.byKey(const ValueKey('device-group-EFFF000000000000')),
        findsNothing);
  });

  testWidgets('搜索无匹配时显示无匹配设备提示', (tester) async {
    await _pumpList(tester);
    await tester.enterText(
        find.byKey(const Key('device-search-field')), 'ZZZ-NO-MATCH');
    await tester.pumpAndSettle();
    expect(find.text('无匹配设备'), findsOneWidget);
  });

  testWidgets('状态下拉过滤为待注册时仅显示待注册设备', (tester) async {
    await _pumpList(tester);
    await tester.tap(find.byKey(const Key('status-filter-dropdown')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.widgetWithText(DropdownMenuItem<String>, '待注册').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('device-group-F1C2000000000D88')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('device-group-847A000000000F03')),
        findsNothing);
  });

  testWidgets('存在待注册检验时显示批量注册按钮，点击调 retryRegistration(全部)',
      (tester) async {
    final repo = await _pumpList(tester);
    expect(find.byKey(const Key('batch-register-btn')), findsOneWidget);
    await tester.tap(find.byKey(const Key('batch-register-btn')));
    await tester.pumpAndSettle();
    expect(repo.retryAll, isTrue);
    expect(repo.lastCheckIds, isNull);
  });

  testWidgets('手动注册按钮调 retryRegistration(checkIds=[该设备待注册检验id])',
      (tester) async {
    final repo = await _pumpList(tester);
    await tester
        .tap(find.byKey(const ValueKey('device-group-F1C2000000000D88')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pending-register-btn')));
    await tester.pumpAndSettle();
    expect(repo.lastCheckIds, [3]);
    expect(repo.retryAll, isFalse);
  });

  testWidgets('删除设备按钮弹确认框，确认后调 deleteChecksByDevice', (tester) async {
    final repo = await _pumpList(tester);
    await tester
        .tap(find.byKey(const ValueKey('device-group-F1C2000000000D88')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-device-btn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('delete-device-confirm-dialog')),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('delete-device-confirm-btn')));
    await tester.pumpAndSettle();
    expect(repo.deletedDeviceId, 12);
  });
}
