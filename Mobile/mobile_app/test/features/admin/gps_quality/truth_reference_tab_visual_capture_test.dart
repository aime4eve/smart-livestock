import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/theme/app_theme.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/truth_reference_tab.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

const _seedData = '''
宿舍楼顶,1号点,28.2453909,112.8507819
宿舍楼顶,2号点,28.2455344,112.8507807
宿舍楼顶,3号点,28.2455843,112.8505580
宿舍楼顶,4号点,28.2454514,112.8505182
西南门,5号点,28.2454077,112.8504692
西南门,6号点,28.2453967,112.8505024
东南门,7号点,28.2451891,112.8512999
东南门,8号点,28.2451752,112.8513665
北门,9号点,28.2467991,112.8517161
北门,10号点,28.2468189,112.8516268
一期楼顶,11号点,28.2465940,112.8516104
一期楼顶,12号点,28.2465306,112.8515918
一期楼顶,13号点,28.2465423,112.8515446
一期楼顶,14号点,28.2465773,112.8515541
一期楼顶,15号点,28.2466024,112.8515760
一期楼顶,16号点,28.2466361,112.8514458
一期楼顶,17号点,28.2466571,112.8513552
一期楼顶,18号点,28.2465998,112.8513146
一期楼顶,19号点,28.2465576,112.8512925
一期楼顶,20号点,28.2465651,112.8511910
一期楼顶,21号点,28.2465803,112.8511422
一期楼顶,22号点,28.2465892,112.8510874
一期楼顶,23号点,28.2465939,112.8513259
一期楼顶,24号点,28.2465976,112.8509989
一期楼顶,25号点,28.2466036,112.8509648
一期楼顶,26号点,28.2466344,112.8510530
一期楼顶,27号点,28.2466735,112.8510666
一期楼顶,28号点,28.2466218,112.8511026
一期楼顶,29号点,28.2466114,112.8511535
一期楼顶,30号点,28.2466007,112.8511949
一期电梯楼顶（西中）,31号点,28.2465617,112.8513945
一期电梯楼顶（东中）,32号点,28.2464889,112.8515712
一期电梯楼顶（东南）,33号点,28.2464447,112.8515829
''';

class _FakeRtkPoints extends RtkPointsController {
  @override
  Future<List<RtkPoint>> build() async => _seedPoints();
}

class _FakeDynamicRoutes extends DynamicRoutesController {
  @override
  Future<List<DynamicRoute>> build() async => [];
}

class _FakeTrackLines extends TrackLinesController {
  @override
  Future<List<StandardTrackLine>> build() async => [];
}

List<RtkPoint> _seedPoints() {
  final rows = _seedData.trim().split('\n');
  return rows.asMap().entries.map((entry) {
    final parts = entry.value.split(',');
    return RtkPoint(
      id: entry.key + 1,
      locationName: parts[0],
      pointLabel: parts[1],
      latitude: double.parse(parts[2]),
      longitude: double.parse(parts[3]),
    );
  }).toList();
}

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = await File(path).readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> _loadFonts() => Future.wait([
  _loadFont('NotoSansSC', [
    'assets/fonts/NotoSansSC-Regular.ttf',
    'assets/fonts/NotoSansSC-Medium.ttf',
    'assets/fonts/NotoSansSC-Bold.ttf',
  ]),
  _loadFont('Roboto', [
    'assets/fonts/Roboto-Regular.ttf',
    'assets/fonts/Roboto-Medium.ttf',
    'assets/fonts/Roboto-Bold.ttf',
  ]),
  _loadFont('MaterialIcons', [
    '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/homebrew/share/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]),
]);

Widget _buildApp() => ProviderScope(
  overrides: [
    rtkPointsProvider.overrideWith(_FakeRtkPoints.new),
    dynamicRoutesProvider.overrideWith(_FakeDynamicRoutes.new),
    trackLinesProvider.overrideWith(_FakeTrackLines.new),
  ],
  child: MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(body: TruthReferenceTab()),
  ),
);

void main() {
  // Golden pixels depend on local font rasterization; generate and compare locally.
  final bool isCi = Platform.environment['CI'] == 'true';
  testWidgets('capture RTK panel visual states', skip: isCi, (tester) async {
    await tester.runAsync(_loadFonts);
    tester.view.physicalSize = const Size(1264, 746);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    final panel = find.byKey(const Key('rtk-points-panel'));
    debugPrint('RTK panel size: ${tester.getSize(panel)}');
    await expectLater(
      panel,
      matchesGoldenFile('goldens/rtk-default-actual.png'),
    );

    await tester.tap(find.byKey(const Key('rtk-location-__all__')));
    await tester.pumpAndSettle();
    await expectLater(panel, matchesGoldenFile('goldens/rtk-all-actual.png'));

    await tester.enterText(
      find.byKey(const Key('rtk-point-search-field')),
      '24号点',
    );
    await tester.pumpAndSettle();
    await expectLater(
      panel,
      matchesGoldenFile('goldens/rtk-search-actual.png'),
    );

    // Changing only view metrics can preserve the desktop RepaintBoundary.
    // Remount the app after resizing so the mobile layout is captured.
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.physicalSize = const Size(390, 1055);
    await tester.pumpAndSettle();
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    final mobilePanel = find.byKey(const Key('rtk-points-panel'));
    // The HTML prototype screenshot includes its vertically overflowing rows.
    // Match that captured element height while preserving the 390px width.
    await expectLater(
      mobilePanel,
      matchesGoldenFile('goldens/rtk-mobile-actual.png'),
    );
  });
}
