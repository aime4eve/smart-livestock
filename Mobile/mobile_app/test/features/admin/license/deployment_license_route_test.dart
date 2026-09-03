import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_router.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/theme/app_theme.dart';
import 'package:hkt_livestock_agentic/features/farm_switcher/farm_switcher_controller.dart';
import 'package:hkt_livestock_agentic/features/admin/license/presentation/deployment_license_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

import 'fake_license_repo.dart';

/// Route guard tests for the deployment-license page (NIX-184 T7):
/// platform_admin reaches the page; other roles are redirected away from
/// /admin/** (owner/worker branch of the router redirect).

class _TestSession extends SessionController {
  _TestSession(this._role);
  final UserRole _role;
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

Future<(GoRouter, ProviderContainer)> _pumpApp(
  WidgetTester tester,
  UserRole role,
  FakeLicenseRepo? licenseRepo,
) async {
  final overrides = [
    sessionControllerProvider.overrideWith(() => _TestSession(role)),
    farmSwitcherControllerProvider.overrideWith(() => _TestFarmSwitcher()),
    if (licenseRepo != null)
      deploymentLicenseRepositoryProvider.overrideWithValue(licenseRepo),
  ];
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  final router = container.read(appRouterProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await _settle(tester);
  return (router, container);
}

Future<void> _settle(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle(const Duration(seconds: 3));
  } catch (_) {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

void main() {
  testWidgets('platform_admin can open /admin/deployment-license', (tester) async {
    final repo = FakeLicenseRepo();
    final (router, _) = await _pumpApp(tester, UserRole.platformAdmin, repo);

    router.go('/admin/deployment-license');
    await _settle(tester);

    expect(find.byKey(const Key('page-deployment-license')), findsOneWidget);
    expect(find.byKey(const Key('enrollment-card')), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path,
        '/admin/deployment-license');
  });

  testWidgets('owner navigating to /admin/deployment-license is redirected to ranch', (tester) async {
    final (router, _) = await _pumpApp(tester, UserRole.owner, FakeLicenseRepo());

    router.go('/admin/deployment-license');
    await _settle(tester);

    expect(find.byKey(const Key('page-deployment-license')), findsNothing);
    expect(router.routeInformationProvider.value.uri.path, '/ranch');
  });

  testWidgets('worker navigating to /admin/deployment-license is redirected to ranch', (tester) async {
    final (router, _) = await _pumpApp(tester, UserRole.worker, FakeLicenseRepo());

    router.go('/admin/deployment-license');
    await _settle(tester);

    expect(find.byKey(const Key('page-deployment-license')), findsNothing);
    expect(router.routeInformationProvider.value.uri.path, '/ranch');
  });
}
