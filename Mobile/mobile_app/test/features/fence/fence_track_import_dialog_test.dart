import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/fence/data/fence_track_parse_repository.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_point.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/widgets/fence_track_import_dialog.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// 测试体内回传值取回句柄。
FenceTrackImportResult? Function() _capturedResult = () => null;

/// 导入向导 widget 测试（NIX-213）：三步流转、禁用条件、解析失败提示、
/// 结果回传。parseOverride 模拟服务端 /track-parse 响应。
void main() {
  final squareBytes = List<int>.filled(8, 0); // 内容不重要：解析被 override

  FenceTrackParseResult parseResult({
    String defaultName = '北围栏',
    int raw = 100,
    int pointCount = 98,
    int removed = 2,
    String? warning,
    List<(double, double)>? points,
  }) {
    final pts = points ?? const [(28.2, 112.9), (28.21, 112.9), (28.22, 112.91), (28.21, 112.92)];
    return FenceTrackParseResult(
      defaultName: defaultName,
      rawPointCount: raw,
      pointCount: pointCount,
      removedDuplicates: removed,
      invalidPoints: 0,
      lengthMeters: 4321.5,
      metadataWarning: warning,
      trackPoints: [
        for (final p in pts) TrackPoint(lat: p.$1, lng: p.$2),
      ],
    );
  }

  Future<void> pumpDialog(
    WidgetTester tester, {
    Future<FenceTrackParseResult> Function(List<int>, String)? parseOverride,
    ({String name, List<int> bytes})? debugFileBytes,
  }) async {
    FenceTrackImportResult? captured;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () async {
                captured = await showDialog<FenceTrackImportResult>(
                  context: context,
                  builder: (_) => FenceTrackImportDialog(
                    debugFileBytes: debugFileBytes,
                    parseOverride: parseOverride,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    _capturedResult = () => captured;
  }

  testWidgets('full flow: pick → preview → envelope → apply', (tester) async {
    await pumpDialog(
      tester,
      debugFileBytes: (name: 'track.gpx', bytes: squareBytes),
      parseOverride: (bytes, fileName) async => parseResult(),
    );

    // Step 0：选择文件（debugFileBytes 直通解析）
    await tester.tap(find.byKey(const Key('fence-import-pick-file')));
    await tester.pumpAndSettle();

    // Step 1：预览统计
    expect(find.byKey(const Key('fence-import-preview')), findsOneWidget);
    expect(find.text('98'), findsOneWidget);
    expect(find.byKey(const Key('fence-import-generate')), findsOneWidget);

    // Step 2：包络结果（4 点正方形 → 4 顶点内面）
    await tester.tap(find.byKey(const Key('fence-import-generate')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fence-import-result')), findsOneWidget);

    await tester.tap(find.byKey(const Key('fence-import-apply')));
    await tester.pumpAndSettle();

    final result = _capturedResult();
    expect(result, isNotNull);
    expect(result!.vertices.length, greaterThanOrEqualTo(3));
    expect(result.defaultName, '北围栏');
  });

  testWidgets('generate disabled when cleaned points < 3', (tester) async {
    await pumpDialog(
      tester,
      debugFileBytes: (name: 'tiny.gpx', bytes: squareBytes),
      parseOverride: (bytes, fileName) async =>
          parseResult(pointCount: 2, points: const [(28.2, 112.9), (28.21, 112.9)]),
    );

    await tester.tap(find.byKey(const Key('fence-import-pick-file')));
    await tester.pumpAndSettle();

    final generate = tester.widget<FilledButton>(
        find.byKey(const Key('fence-import-generate')));
    expect(generate.onPressed, isNull);
  });

  testWidgets('parse failure shows snackbar and stays on upload step',
      (tester) async {
    await pumpDialog(
      tester,
      debugFileBytes: (name: 'bad.gpx', bytes: squareBytes),
      parseOverride: (bytes, fileName) async =>
          throw Exception('error.gpxParseFailed'),
    );

    await tester.tap(find.byKey(const Key('fence-import-pick-file')));
    await tester.pumpAndSettle();

    expect(find.textContaining('GPX 导入失败'), findsOneWidget);
    expect(find.byKey(const Key('fence-import-pick-file')), findsOneWidget);
  });
}
