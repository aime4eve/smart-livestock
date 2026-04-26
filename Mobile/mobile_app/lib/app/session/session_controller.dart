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

  void logout() {
    state = const AppSession.loggedOut();
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, AppSession>(SessionController.new);
