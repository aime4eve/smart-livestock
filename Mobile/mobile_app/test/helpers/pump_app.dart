import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/app_router.dart';
import 'package:smart_livestock_demo/app/session/app_session.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/models/user_role.dart';
import 'package:smart_livestock_demo/core/theme/app_theme.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_controller.dart';

/// Pumps the app with an authenticated session for the given [role].
///
/// Overrides both session and farm switcher so the shell renders
/// real page content instead of the "no farms" guidance.
Future<void> pumpAppWithRole(
  WidgetTester tester,
  UserRole role,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(() => _FakeSessionController(role)),
        farmSwitcherControllerProvider.overrideWith(() => _FakeFarmSwitcherController()),
      ],
      child: const _TestApp(),
    ),
  );
  // Guard against pumpAndSettle timeout (animations / periodic rebuilds)
  try {
    await tester.pumpAndSettle(const Duration(seconds: 3));
  } catch (_) {
    await tester.pump();
  }
}

class _TestApp extends ConsumerWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(),
    );
  }
}

class _FakeSessionController extends SessionController {
  final UserRole _role;

  _FakeSessionController(this._role);

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

class _FakeFarmSwitcherController extends FarmSwitcherController {
  @override
  FarmSwitcherState build() {
    super.build();
    return const FarmSwitcherState(
      farms: [FarmInfo(id: '1', name: 'Demo 牧场')],
      activeFarmId: '1',
    );
  }
}
