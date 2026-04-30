import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/session/app_session.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';

void main() {
  test('AppSession copyWith updates active farm without losing tokens', () {
    final expiresAt = DateTime.utc(2999);
    final session = AppSession.withTokens(
      role: DemoRole.owner,
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: expiresAt,
      activeFarmTenantId: 'tenant_001',
    );

    final updated = session.copyWith(activeFarmTenantId: 'tenant_007');

    expect(updated.role, DemoRole.owner);
    expect(updated.accessToken, 'access-token');
    expect(updated.refreshToken, 'refresh-token');
    expect(updated.expiresAt, expiresAt);
    expect(updated.activeFarmTenantId, 'tenant_007');
  });

  test('SessionController updateActiveFarm preserves current session', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final expiresAt = DateTime.utc(2999);
    container.read(sessionControllerProvider.notifier).loginWithTokens(
          role: DemoRole.worker,
          accessToken: 'worker-token',
          refreshToken: 'worker-refresh',
          expiresAt: expiresAt,
        );

    container
        .read(sessionControllerProvider.notifier)
        .updateActiveFarm('tenant_007');

    final session = container.read(sessionControllerProvider);
    expect(session.role, DemoRole.worker);
    expect(session.accessToken, 'worker-token');
    expect(session.refreshToken, 'worker-refresh');
    expect(session.expiresAt, expiresAt);
    expect(session.activeFarmTenantId, 'tenant_007');
  });
}
