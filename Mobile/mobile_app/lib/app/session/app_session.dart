import 'package:smart_livestock_demo/core/models/demo_role.dart';

class AppSession {
  const AppSession._({
    this.role,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  const AppSession.loggedOut() : this._();

  const AppSession.authenticated(DemoRole role) : this._(role: role);

  const AppSession.withTokens({
    required DemoRole role,
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) : this._(
          role: role,
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAt: expiresAt,
        );

  final DemoRole? role;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  bool get isLoggedIn => role != null;

  bool get isOps => role == DemoRole.ops;

  bool get canAccessAdminTab => role == DemoRole.owner;
}
