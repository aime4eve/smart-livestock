import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/app/app_router.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/theme/app_theme.dart';
import 'package:hkt_livestock_agentic/features/auth/presentation/context_picker_page.dart';
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

  group('路由守卫 — super_admin（选角色进入，2026-10-19）', () {
    testWidgets('根会话被锁进选择器页（无牧场底部导航）', (tester) async {
      await _pumpApp(tester, UserRole.superAdmin, impersonated: false);
      expect(find.byType(ContextPickerPage), findsOneWidget);
      expect(find.byKey(const Key('nav-ranch')), findsNothing);
    });

    testWidgets('OWNER 上下文会话按上下文角色进牧场页', (tester) async {
      await _pumpApp(tester, UserRole.owner, impersonated: true);
      expect(find.byKey(const Key('nav-ranch')), findsOneWidget);
      expect(find.byType(ContextPickerPage), findsNothing);
    });

    testWidgets('PLATFORM_ADMIN 上下文会话进平台管理台', (tester) async {
      await _pumpApp(tester, UserRole.platformAdmin, impersonated: true);
      expect(find.byKey(const Key('nav-ranch')), findsNothing);
    });

    testWidgets('根会话改密锁优先于选择器', (tester) async {
      await _pumpApp(tester, UserRole.superAdmin,
          impersonated: false, mustChangePassword: true);
      expect(find.byType(ContextPickerPage), findsNothing);
    });

    testWidgets('OWNER 上下文会话在选择器页被送回牧场页（2026-10-20 修复回归）',
        (tester) async {
      await _pumpApp(tester, UserRole.owner, impersonated: true);
      // Reproduce the real flow: after the confirm sheet the session is
      // already a context session while the router still sits on the
      // picker — the redirect must send it to the ranch home.
      final element = tester.element(find.byType(Scaffold).first);
      GoRouter.of(element).go(AppRoute.selectContext.path);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('nav-ranch')), findsOneWidget);
      expect(find.byType(ContextPickerPage), findsNothing);
    });
  });
}

Future<void> _pumpApp(WidgetTester tester, UserRole role,
    {bool impersonated = false, bool mustChangePassword = false}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(
            () => _TestSession(role, impersonated, mustChangePassword)),
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
  final bool _impersonated;
  final bool _mustChangePassword;
  _TestSession(this._role, this._impersonated, this._mustChangePassword);
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
        mustChangePassword: _mustChangePassword,
        impersonated: _impersonated,
        impersonatedTenantName: _impersonated ? '南非-市场' : null,
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
