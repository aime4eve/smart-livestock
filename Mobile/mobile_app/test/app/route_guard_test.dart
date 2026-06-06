import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/app_router.dart';
import 'package:smart_livestock_demo/app/session/app_session.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/models/user_role.dart';
import 'package:smart_livestock_demo/core/theme/app_theme.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_controller.dart';

void main() {
  group('路由守卫 — worker', () {
    testWidgets('worker 无 admin Tab', (tester) async {
      await _pumpApp(tester, UserRole.worker);
      expect(find.byKey(const Key('nav-admin')), findsNothing);
    });

    testWidgets('worker 导航栏只有 4 个 Tab', (tester) async {
      await _pumpApp(tester, UserRole.worker);
      expect(find.byKey(const Key('nav-twin')), findsOneWidget);
      expect(find.byKey(const Key('nav-fence')), findsOneWidget);
      expect(find.byKey(const Key('nav-alerts')), findsOneWidget);
      expect(find.byKey(const Key('nav-mine')), findsOneWidget);
      expect(find.byKey(const Key('nav-admin')), findsNothing);
    });
  });

  group('路由守卫 — platform_admin', () {
    testWidgets('platform_admin 无 App 底部导航', (tester) async {
      await _pumpApp(tester, UserRole.platformAdmin);
      expect(find.byKey(const Key('nav-twin')), findsNothing);
    });
  });

  group('路由守卫 — b2b_admin', () {
    testWidgets('b2b_admin 无 App 底部导航', (tester) async {
      await _pumpApp(tester, UserRole.b2bAdmin);
      expect(find.byKey(const Key('nav-twin')), findsNothing);
    });
  });

  group('路由守卫 — owner', () {
    testWidgets('owner 有数智孪生 Tab', (tester) async {
      await _pumpApp(tester, UserRole.owner);
      expect(find.byKey(const Key('nav-twin')), findsOneWidget);
    });

    testWidgets('owner 导航栏包含 4 个 Tab', (tester) async {
      await _pumpApp(tester, UserRole.owner);
      expect(find.byKey(const Key('nav-twin')), findsOneWidget);
      expect(find.byKey(const Key('nav-fence')), findsOneWidget);
      expect(find.byKey(const Key('nav-alerts')), findsOneWidget);
      expect(find.byKey(const Key('nav-mine')), findsOneWidget);
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
          return MaterialApp.router(routerConfig: router, theme: AppTheme.light());
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
