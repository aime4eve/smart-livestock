import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/app_router.dart';
import 'package:smart_livestock_demo/app/session/app_session.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/models/user_role.dart';
import 'package:smart_livestock_demo/core/theme/app_theme.dart';

/// Pumps the app with an authenticated session for the given [role].
///
/// Replaces the old pattern of tapping `Key('role-owner')` which no longer
/// exists after the DemoRole removal.
Future<void> pumpAppWithRole(
  WidgetTester tester,
  UserRole role,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(() => _FakeSessionController(role)),
      ],
      child: const _TestApp(),
    ),
  );
  await tester.pumpAndSettle();
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
        activeFarmId: 'tenant_001',
      );
}
