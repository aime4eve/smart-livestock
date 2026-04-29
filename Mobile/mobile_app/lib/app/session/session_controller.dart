import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/session/app_session.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';

class SessionController extends Notifier<AppSession> {
  @override
  AppSession build() => const AppSession.loggedOut();

  void login(DemoRole role) {
    state = AppSession.authenticated(role);
  }

  void loginWithTokens({
    required DemoRole role,
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    state = AppSession.withTokens(
      role: role,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  DemoRole? _roleFromMockToken(String token) {
    return switch (token) {
      'mock-token-owner' => DemoRole.owner,
      'mock-token-worker' => DemoRole.worker,
      'mock-token-platform-admin' => DemoRole.platformAdmin,
      'mock-token-b2b-admin' => DemoRole.b2bAdmin,
      'mock-token-api-consumer' => DemoRole.apiConsumer,
      _ when token.startsWith('mock-token-u_') => DemoRole.owner,
      _ => null,
    };
  }

  void loginWithToken(String token) {
    final trimmed = token.trim();
    final role = _roleFromMockToken(trimmed);
    if (role == null) return;
    state = AppSession.withTokens(
      role: role,
      accessToken: trimmed,
    );
  }

  void logout() {
    state = const AppSession.loggedOut();
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, AppSession>(SessionController.new);
