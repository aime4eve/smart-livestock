// ignore_for_file: avoid_print

// Decisive experiment for the NIX-256 5b walkthrough issues: pump the real
// page against the real local backend (http://localhost:8080) with NO data
// provider overrides — the full HTTP → repository → controller → widget
// chain. Skips automatically when the local backend is not running.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/pages/livestock_detail_page.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

void main() {
  testWidgets(
    'real backend: detail page devices + all four trend sections render',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});

      // Reachability probe: skip cleanly when the local stack is down.
      var backendUp = true;
      try {
        ApiClient.instance.setBaseUrl('http://localhost:8080/api/v1');
        await ApiClient.instance.login(
          phone: '13800138000',
          password: '123',
        );
      } catch (_) {
        backendUp = false;
      }
      if (!backendUp) {
        print('SKIP: local backend not reachable on :8080');
        return;
      }
      ApiClient.instance.setActiveFarmId('1');

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Only the session bootstrap is faked (the real token is
            // already in JwtStorage from the real login above); every
            // data provider runs against the real backend.
            initialSessionProvider.overrideWithValue(
              const AppSession.authenticated(
                role: UserRole.owner,
                accessToken: 'stored-by-login',
                activeFarmId: '1',
              ),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LivestockDetailPage(livestockId: '12'),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);

      // ── Issue B: the device card must list the bound capsule ──
      expect(find.text('DEV-RC-003'), findsOneWidget);
      expect(find.text('DEV-GPS-012'), findsOneWidget);

      // ── Issue A: all four trend sections must lay out ──
      expect(find.byKey(const Key('drinking-card')), findsOneWidget);
      expect(find.byKey(const Key('drinking-detail-section')), findsOneWidget);

      for (var i = 0; i < 10; i++) {
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      expect(find.text('生理记录'), findsOneWidget);
    },
  );
}
