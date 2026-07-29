import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/admin/telemetry_import/data/telemetry_import_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/telemetry_import/domain/telemetry_import_models.dart';
import 'package:hkt_livestock_agentic/features/admin/telemetry_import/presentation/telemetry_import_controller.dart';
import 'package:hkt_livestock_agentic/features/admin/telemetry_import/presentation/telemetry_import_page.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class _FakeRepo extends TelemetryImportApiRepository {
  bool parseCalled = false;
  bool importCalled = false;

  TelemetryParseResult parseResult = matchedResult;
  TelemetryImportResult importResult = const TelemetryImportResult(
    telemetryCreated: 5,
    gpsCreated: 5,
    duplicateSkipped: 1,
    skippedRows: 2,
    invalidRows: 1,
    failedRows: 0,
    devEui: '0095690600028577',
    deviceCode: 'GPS-0095690600028577',
  );

  static TelemetryRowPreview _row(
    int rowNo,
    String counter,
    TelemetryRowStatus status, {
    String? error,
  }) =>
      TelemetryRowPreview(
        rowNo: rowNo,
        frameCounter: counter,
        recordTime: DateTime.utc(2026, 7, 23, 16, 9),
        battery: status == TelemetryRowStatus.importable ||
                status == TelemetryRowStatus.duplicate
            ? 99
            : null,
        latitude: status == TelemetryRowStatus.importable ||
                status == TelemetryRowStatus.duplicate
            ? 28.246777
            : null,
        longitude: status == TelemetryRowStatus.importable ||
                status == TelemetryRowStatus.duplicate
            ? 112.851138
            : null,
        stepCount: status == TelemetryRowStatus.importable ? 27 : null,
        status: status,
        error: error,
      );

  /// 9 rows (rowNo 2..10): 5 importable / 1 duplicate / 1 downlink /
  /// 1 unsupported / 1 invalid -- first 8 shown in the preview table.
  static final matchedResult = TelemetryParseResult(
    totalRows: 9,
    uplinkRows: 8,
    decodableRows: 6,
    importableRows: 5,
    gpsPointRows: 5,
    duplicateRows: 1,
    skippedRows: 2,
    invalidRows: 1,
    device: const TelemetryDeviceMatch(
      matched: true,
      devEui: '0095690600028577',
      deviceCode: 'GPS-0095690600028577',
      deviceType: 'TRACKER',
      livestockName: '黄牛 N-1024',
      farmName: '长沙示范牧场',
    ),
    rows: [
      _row(2, '119', TelemetryRowStatus.importable),
      _row(3, '117', TelemetryRowStatus.importable),
      _row(4, '116', TelemetryRowStatus.importable),
      _row(5, '115', TelemetryRowStatus.duplicate),
      _row(6, '114', TelemetryRowStatus.importable),
      _row(7, '', TelemetryRowStatus.skippedDownlink),
      _row(8, '', TelemetryRowStatus.skippedUnsupported),
      _row(9, '112', TelemetryRowStatus.invalid,
          error: 'error.telemetryImport.invalidTime'),
      _row(10, '111', TelemetryRowStatus.importable),
    ],
  );

  static final unmatchedResult = TelemetryParseResult(
    totalRows: 9,
    uplinkRows: 8,
    decodableRows: 6,
    importableRows: 5,
    gpsPointRows: 5,
    duplicateRows: 1,
    skippedRows: 2,
    invalidRows: 1,
    device: const TelemetryDeviceMatch(
      matched: false,
      devEui: '0095690600028577',
      error: 'error.telemetryImport.deviceNotRegistered',
    ),
    rows: matchedResult.rows,
  );

  @override
  Future<TelemetryParseResult> parse(
      List<int> fileBytes, String fileName) async {
    parseCalled = true;
    return parseResult;
  }

  @override
  Future<TelemetryImportResult> importTelemetry(
      List<int> fileBytes, String fileName) async {
    importCalled = true;
    return importResult;
  }
}

Future<_FakeRepo> _pumpPage(
  WidgetTester tester, {
  TelemetryParseResult? parseResult,
}) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repo = _FakeRepo();
  if (parseResult != null) repo.parseResult = parseResult;
  await tester.pumpWidget(ProviderScope(
    overrides: [telemetryImportApiRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TelemetryImportPage(
          debugFileBytes: Uint8List.fromList([1, 2, 3])),
    ),
  ));
  await tester.pumpAndSettle();
  return repo;
}

/// Scrolls [key] into view inside the vertical scroll view, then taps it.
Future<void> _tapVisible(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Drives step 0 -> step 1 via the parse button.
Future<void> _goToPreview(WidgetTester tester) async {
  await _tapVisible(tester, const Key('telemetry-import-next-btn'));
}

void main() {
  testWidgets('选中文件后进入解析预览：统计条/设备卡已匹配/预览表前 8 行', (tester) async {
    final repo = await _pumpPage(tester);

    // Step 0: debug file is pre-selected, file name shown.
    expect(find.byKey(const Key('telemetry-import-file-name')), findsOneWidget);
    expect(find.text('test-telemetry-import.xlsx'), findsOneWidget);

    await _goToPreview(tester);
    expect(repo.parseCalled, isTrue);

    // Stats strip: 9 total / 8 uplink / 6 decodable / 5 importable / 1 dup / 2 skipped.
    expect(find.byKey(const Key('telemetry-import-stats')), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('telemetry-import-stat-total')),
            matching: find.text('9')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('telemetry-import-stat-uplink')),
            matching: find.text('8')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('telemetry-import-stat-decodable')),
            matching: find.text('6')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('telemetry-import-stat-importable')),
            matching: find.text('5')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('telemetry-import-stat-duplicate')),
            matching: find.text('1')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('telemetry-import-stat-skipped')),
            matching: find.text('2')),
        findsOneWidget);

    // Device card: matched tag + meta line.
    expect(find.byKey(const Key('telemetry-import-device-card')), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('telemetry-import-device-tag')),
            matching: find.text('✓ 设备已匹配')),
        findsOneWidget);
    expect(find.textContaining('GPS-0095690600028577'), findsWidgets);
    expect(find.textContaining('黄牛 N-1024'), findsOneWidget);
    expect(find.textContaining('长沙示范牧场'), findsOneWidget);

    // Preview table: first 8 rows only, per-status tags.
    expect(find.byKey(const Key('telemetry-import-preview-table')), findsOneWidget);
    expect(
        find.byKey(const Key('telemetry-import-row-status-10')), findsNothing);
    expect(
        find.descendant(
            of: find.byKey(const Key('telemetry-import-row-status-2')),
            matching: find.text('将导入')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('telemetry-import-row-status-5')),
            matching: find.text('重复 · 已存在')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('telemetry-import-row-status-7')),
            matching: find.text('跳过 · 下行帧')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('telemetry-import-row-status-8')),
            matching: find.text('跳过 · 非遥测帧')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('telemetry-import-row-status-9')),
            matching: find.text('错误')),
        findsOneWidget);
    expect(find.byKey(const Key('telemetry-import-preview-note')),
        findsOneWidget);
    expect(find.textContaining('完整 9 行'), findsOneWidget);

    // Import button carries the importable count.
    expect(
        find.descendant(
            of: find.byKey(const Key('telemetry-import-import-btn')),
            matching: find.text('确认导入 5 条')),
        findsOneWidget);
  });

  testWidgets('确认导入进入结果页，「继续导入其他文件」回到上传步', (tester) async {
    final repo = await _pumpPage(tester);
    await _goToPreview(tester);
    await _tapVisible(tester, const Key('telemetry-import-import-btn'));

    expect(repo.importCalled, isTrue);
    expect(find.byKey(const Key('telemetry-import-result-banner')), findsOneWidget);
    expect(find.textContaining('成功写入遥测记录 5 条'), findsOneWidget);
    expect(find.byKey(const Key('telemetry-import-result-card')), findsOneWidget);
    expect(find.text('0095690600028577'), findsOneWidget);
    expect(find.textContaining('黄牛 N-1024 · 长沙示范牧场'), findsOneWidget);

    await _tapVisible(tester, const Key('telemetry-import-another-btn'));
    expect(find.byKey(const Key('telemetry-import-upload-zone')), findsOneWidget);
    expect(find.byKey(const Key('telemetry-import-next-btn')), findsOneWidget);
  });

  testWidgets('设备未匹配：设备卡红态 + 导入按钮禁用且不调 import', (tester) async {
    final repo =
        await _pumpPage(tester, parseResult: _FakeRepo.unmatchedResult);
    await _goToPreview(tester);
    expect(repo.parseCalled, isTrue);

    expect(
        find.descendant(
            of: find.byKey(const Key('telemetry-import-device-tag')),
            matching: find.text('✗ 设备未匹配')),
        findsOneWidget);
    expect(find.textContaining('设备未注册：0095690600028577'), findsOneWidget);
    expect(find.textContaining('整文件不可导入'), findsOneWidget);

    final btn = tester.widget<FilledButton>(
        find.byKey(const Key('telemetry-import-import-btn')));
    expect(btn.onPressed, isNull);
    expect(
        find.descendant(
            of: find.byKey(const Key('telemetry-import-import-btn')),
            matching: find.text('设备未匹配，不可导入')),
        findsOneWidget);
    expect(repo.importCalled, isFalse);
  });
}
