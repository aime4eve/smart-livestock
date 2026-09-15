/// Diagnostic only — map tile source under a given time zone (login flow).
///
///   flutter test integration_test/map_diagnosis_test.dart -d <udid> \
///     --dart-define=APP_MODE=live \
///     --dart-define=API_BASE_URL=https://ah.hkttech.cn/api/v1 \
///     [--dart-define=DIAG_TZ=UTC]
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:hkt_livestock_agentic/app/demo_app.dart';
import 'package:hkt_livestock_agentic/core/database/app_database.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/timezone/time_zone_controller.dart';

const _diagTz = String.fromEnvironment('DIAG_TZ');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final binding = IntegrationTestWidgetsFlutterBinding.instance;

  testWidgets('map tile source diagnosis', (tester) async {
    // Mimic main(): seed the DB via path_provider before any provider reads it.
    await AppDatabase.createAsync();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        if (_diagTz.isNotEmpty)
          initialTimeZoneIdProvider.overrideWithValue(_diagTz),
      ],
      child: const DemoApp(),
    ));
    await tester.pumpAndSettle();

    // -- login via UI --
    expect(find.byKey(const Key('login-phone')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('login-phone')), '13800138000');
    await tester.enterText(find.byKey(const Key('login-password')), '123');
    await tester.tap(find.byKey(const Key('login-submit')));
    // navigation + farm load + tile provider init + probe settle
    await tester.pump(const Duration(seconds: 40));

    final maps = find.byType(FlutterMap).evaluate().toList();
    debugPrint('=== DIAG_TZ=$_diagTz');
    debugPrint('=== FlutterMap count: ${maps.length}');
    for (final el in maps) {
      final map = el.widget as FlutterMap;
      for (final child in map.children) {
        if (child is TileLayer) {
          final tp = child.tileProvider;
          if (tp is SmartTileProvider) {
            debugPrint('=== SmartTileProvider activeSourceName='
                '${tp.activeSourceName} isOnline=${tp.isOnline} '
                'shouldTransform=${tp.shouldTransformCoordinates()}');
          } else {
            debugPrint('=== TileLayer tileProvider type: ${tp.runtimeType}');
          }
        }
      }
    }

    final shot = await binding.takeScreenshot('ranch-map');
    const out = '/tmp/map_diag_ranch.png';
    await File(out).writeAsBytes(shot);
    debugPrint('=== screenshot saved: $out (${shot.length} bytes)');

    expect(maps, isNotEmpty, reason: 'map page must contain a FlutterMap');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
