import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/app_router.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/theme/app_theme.dart';
import 'package:hkt_livestock_agentic/features/farm_switcher/farm_switcher_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

void main() {
  group('路由守卫 — worker', () {
    testWidgets('worker 无 admin Tab', (tester) async {
      await _pumpApp(tester, UserRole.worker);
      expect(find.byKey(const Key('nav-admin')), findsNothing);
    });

    testWidgets('worker 导航栏只有 2 个 Tab（牧场 + 我的）', (tester) async {
      await _pumpApp(tester, UserRole.worker);
      expect(find.byKey(const Key('nav-ranch')), findsOneWidget);
      expect(find.byKey(const Key('nav-mine')), findsOneWidget);
      expect(find.byKey(const Key('nav-twin')), findsNothing);
      expect(find.byKey(const Key('nav-fence')), findsNothing);
      expect(find.byKey(const Key('nav-alerts')), findsNothing);
      expect(find.byKey(const Key('nav-admin')), findsNothing);
    });
  });

  group('路由守卫 — platform_admin', () {
    testWidgets('platform_admin 无 App 底部导航', (tester) async {
      await _pumpApp(tester, UserRole.platformAdmin);
      expect(find.byKey(const Key('nav-ranch')), findsNothing);
    });
  });

  group('路由守卫 — b2b_admin', () {
    testWidgets('b2b_admin 无 App 底部导航', (tester) async {
      await _pumpApp(tester, UserRole.b2bAdmin);
      expect(find.byKey(const Key('nav-ranch')), findsNothing);
    });
  });

  group('路由守卫 — owner', () {
    testWidgets('owner 有牧场 Tab', (tester) async {
      await _pumpApp(tester, UserRole.owner);
      expect(find.byKey(const Key('nav-ranch')), findsOneWidget);
    });

    testWidgets('owner 导航栏包含 2 个 Tab（牧场 + 我的）', (tester) async {
      await _pumpApp(tester, UserRole.owner);
      expect(find.byKey(const Key('nav-ranch')), findsOneWidget);
      expect(find.byKey(const Key('nav-mine')), findsOneWidget);
      expect(find.byKey(const Key('nav-twin')), findsNothing);
      expect(find.byKey(const Key('nav-fence')), findsNothing);
      expect(find.byKey(const Key('nav-alerts')), findsNothing);
    });
  });
}

Future<void> _pumpApp(WidgetTester tester, UserRole role) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(() => _TestSession(role)),
        farmSwitcherControllerProvider.overrideWith(() => _TestFarmSwitcher()),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(appRouterProvider);
          return MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    ),
  );
  try {
    await tester.pumpAndSettle(const Duration(seconds: 3));
  } catch (_) {
    await tester.pump();
  }
}

class _TestSession extends SessionController {
  final UserRole _role;
  _TestSession(this._role);
  @override
  AppSession build() => AppSession.authenticated(
        role: _role,
        accessToken: 'test-token',
        userId: 1,
        userName: 'Test User',
        phone: '13800138000',
        tenantId: 1,
        username: 'testuser',
        activeFarmId: '1',
      );
}

class _TestFarmSwitcher extends FarmSwitcherController {
  @override
  FarmSwitcherState build() {
    super.build();
    return const FarmSwitcherState(
      farms: [FarmInfo(id: '1', name: 'Demo 牧场')],
      activeFarmId: '1',
    );
  }
}
