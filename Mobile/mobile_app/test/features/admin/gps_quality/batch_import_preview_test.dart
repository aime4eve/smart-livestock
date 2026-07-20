import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/batch_import_dialog.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class _FakeRepo extends GpsQualityApiRepository {
  List<int>? lastExcludeRows;
  bool importCalled = false;
  List<int>? lastCheckIds;
  bool retryAll = false;

  final parseResult = BatchParseResult(
    totalRows: 4,
    okCount: 2,
    warnCount: 1,
    errorCount: 1,
    rows: [
      BatchParseRow(
        rowIndex: 1,
        eui: '847A000000000F03',
        deviceCode: 'DEV-GPS-001',
        testType: 'STATIC',
        refName: '11号点 - 北门',
        startedAt: DateTime.utc(2026, 7, 18, 9),
        endedAt: DateTime.utc(2026, 7, 18, 10),
        preStatus: 'OK',
      ),
      BatchParseRow(
        rowIndex: 2,
        eui: 'A2B4000000000C19',
        testType: 'DYNAMIC',
        refName: '北门短测线',
        startedAt: DateTime.utc(2026, 7, 18, 14),
        preStatus: 'OK',
      ),
      BatchParseRow(
        rowIndex: 3,
        eui: 'F1C2000000000D88',
        deviceCode: 'DEV-GPS-004',
        testType: 'STATIC',
        refName: '3号 - 猪舍A区',
        startedAt: DateTime.utc(2026, 7, 18, 8),
        preStatus: 'WARN',
      ),
      const BatchParseRow(
        rowIndex: 4,
        eui: 'EFFF',
        testType: 'STATIC',
        refName: '5号点',
        preStatus: 'ERROR',
        message: 'EUI格式无效',
      ),
    ],
  );

  @override
  Future<BatchParseResult> parseBatch(
          List<int> fileBytes, String fileName) async =>
      parseResult;

  @override
  Future<BatchImportResult> batchImport(List<int> fileBytes, String fileName,
      {List<int>? excludeRows}) async {
    importCalled = true;
    lastExcludeRows = excludeRows;
    return const BatchImportResult(
      batchId: 9,
      totalRows: 2,
      totalSuccess: 1,
      totalPending: 1,
      totalFailed: 0,
      rows: [
        RowResult(
            rowIndex: 1,
            status: 'READY',
            eui: '847A000000000F03',
            checkId: 50),
        RowResult(
            rowIndex: 3,
            status: 'DEVICE_PENDING',
            eui: 'F1C2000000000D88',
            checkId: 55),
      ],
    );
  }

  @override
  Future<List<RowResult>> retryRegistration({List<int>? checkIds}) async {
    if (checkIds == null) {
      retryAll = true;
    } else {
      lastCheckIds = checkIds;
    }
    return [];
  }
}

Future<_FakeRepo> _pumpDialog(WidgetTester tester) async {
  final repo = _FakeRepo();
  await tester.pumpWidget(ProviderScope(
    overrides: [gpsQualityApiRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
          body: BatchImportDialog(
              debugFileBytes: Uint8List.fromList([1, 2, 3]))),
    ),
  ));
  await tester.pumpAndSettle();
  return repo;
}

/// Taps a control inside the horizontally scrollable data tables.
Future<void> _tapVisible(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('预览展示真实解析行与汇总，ERROR 行默认排除且不可恢复', (tester) async {
    await _pumpDialog(tester);
    await tester.tap(find.byKey(const Key('batch-import-preview-btn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('preview-table')), findsOneWidget);
    // 汇总卡：总行数 4 / 可出报告 2 / 待注册 1 / 失败 1
    expect(find.text('4'), findsWidgets);
    expect(find.text('847A000000000F03'), findsOneWidget);
    expect(find.text('A2B4000000000C19'), findsOneWidget);
    expect(find.text('F1C2000000000D88'), findsOneWidget);
    // ERROR 行显示"已排除"且无删除按钮
    expect(find.byKey(const Key('preview-excluded-4')), findsOneWidget);
    expect(find.byKey(const Key('preview-remove-row-4')), findsNothing);
  });

  testWidgets('删除预览行后提交携带 excludeRows（含 ERROR 行）', (tester) async {
    final repo = await _pumpDialog(tester);
    await tester.tap(find.byKey(const Key('batch-import-preview-btn')));
    await tester.pumpAndSettle();

    await _tapVisible(tester, const Key('preview-remove-row-2'));
    expect(find.text('A2B4000000000C19'), findsNothing);

    await tester.tap(find.byKey(const Key('batch-import-submit-btn')));
    await tester.pumpAndSettle();

    expect(repo.importCalled, isTrue);
    expect(repo.lastExcludeRows, [2, 4]);
    // 进入结果页
    expect(find.byKey(const Key('batch-register-all-btn')), findsOneWidget);
  });

  testWidgets('结果页手动注册调 retryRegistration(checkIds=[该行checkId])',
      (tester) async {
    final repo = await _pumpDialog(tester);
    await tester.tap(find.byKey(const Key('batch-import-preview-btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('batch-import-submit-btn')));
    await tester.pumpAndSettle();

    await _tapVisible(tester, const Key('batch-row-register-3'));
    expect(repo.lastCheckIds, [55]);
    expect(repo.retryAll, isFalse);
  });

  testWidgets('结果页批量注册调 retryRegistration(全部)', (tester) async {
    final repo = await _pumpDialog(tester);
    await tester.tap(find.byKey(const Key('batch-import-preview-btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('batch-import-submit-btn')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('batch-register-all-btn')));
    await tester.pumpAndSettle();
    expect(repo.retryAll, isTrue);
  });
}
