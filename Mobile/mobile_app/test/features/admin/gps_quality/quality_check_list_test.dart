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
  int? deletedCheckId;

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
  Future<void> deleteCheck(int id) async {
    deletedCheckId = id;
  }

  @override
  Future<TrajectoryQualityReport> fetchTrajectoryReport(int testId) async =>
      TrajectoryQualityReport(
        testId: testId,
        deviceCode: 'DEV001',
        startedAt: DateTime(2026, 7, 18, 9),
        endedAt: DateTime(2026, 7, 18, 10),
        toleranceSec: 60,
        grade: QualityGrade.usable,
        totalPoints: 10,
        filePaired: 8,
        logPaired: 2,
        unpaired: 0,
        pairRate: 100,
        meanError: 3.5,
        p50: 3.0,
        p95: 5.2,
        maxError: 6.1,
        points: const [],
      );

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
  String checkType = 'STATIC',
}) =>
    QualityCheck(
      id: id,
      deviceCode: deviceCode,
      deviceId: deviceId,
      checkType: checkType,
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

/// Pump the list with custom test data (for swimlane-specific tests).
Future<_FakeRepo> _pumpListWithData(
    WidgetTester tester, QualityCheckListResult data) async {
  final repo = _FakeRepo();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      checksProvider.overrideWith(() => _FakeChecks(data)),
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

  testWidgets('READY 状态设备也显示删除设备按钮', (tester) async {
    await _pumpList(tester);
    await tester
        .tap(find.byKey(const ValueKey('device-group-847A000000000F03')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('delete-device-btn')), findsOneWidget);
  });

  testWidgets('时间线段删除图标弹确认框，确认后调 deleteCheck(该检验id)',
      (tester) async {
    final repo = await _pumpList(tester);
    await tester
        .tap(find.byKey(const ValueKey('device-group-847A000000000F03')));
    await tester.pumpAndSettle();
    // 时间线上该设备的每次检验各有一个删除图标
    expect(find.byKey(const ValueKey('delete-check-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-check-2')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('delete-check-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-check-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('delete-check-confirm-dialog')),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('delete-check-confirm-btn')));
   await tester.pumpAndSettle();
   expect(repo.deletedCheckId, 2);
 });

  testWidgets('静态+轨迹泳道：两段均可独立点击选中', (tester) async {
    // Same device with overlapping STATIC and TRAJECTORY checks.
    final base = DateTime(2026, 7, 18, 9);
    final data = QualityCheckListResult(items: [
      _check(
          id: 10,
          deviceCode: 'DEV001',
          deviceId: 50,
          status: 'READY',
          startedAt: base),
      _check(
          id: 11,
          deviceCode: 'DEV001',
          deviceId: 50,
          status: 'READY',
          startedAt: base.add(const Duration(minutes: 30)),
          checkType: 'TRAJECTORY'),
    ]);
    await _pumpListWithData(tester, data);

    // Both timeline segments exist and are independently tappable.
    expect(find.byKey(const ValueKey('timeline-segment-10')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('timeline-segment-11')),
        findsOneWidget);

    // Tap the TRAJECTORY segment — it should become selected.
    await tester.tap(find.byKey(const ValueKey('timeline-segment-11')));
    await tester.pumpAndSettle();

    // Tap the STATIC segment — it should switch back.
    await tester.tap(find.byKey(const ValueKey('timeline-segment-10')));
    await tester.pumpAndSettle();
  });

  testWidgets('静态+轨迹泳道：轨迹段删除图标可正常触发', (tester) async {
    final base = DateTime(2026, 7, 18, 9);
    final data = QualityCheckListResult(items: [
      _check(
          id: 20,
          deviceCode: 'DEV002',
          deviceId: 60,
          status: 'READY',
          startedAt: base),
      _check(
          id: 21,
          deviceCode: 'DEV002',
          deviceId: 60,
          status: 'READY',
          startedAt: base.add(const Duration(minutes: 15)),
          checkType: 'TRAJECTORY'),
    ]);
    final repo = await _pumpListWithData(tester, data);

    // Both delete badges exist.
    expect(find.byKey(const ValueKey('delete-check-20')), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-check-21')), findsOneWidget);

    // Delete the TRAJECTORY check.
    await tester.ensureVisible(find.byKey(const ValueKey('delete-check-21')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-check-21')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('delete-check-confirm-dialog')),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('delete-check-confirm-btn')));
    await tester.pumpAndSettle();
    expect(repo.deletedCheckId, 21);
  });
}
