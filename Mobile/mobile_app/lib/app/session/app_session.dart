import 'package:smart_livestock_demo/core/models/demo_role.dart';

class AppSession {
  const AppSession._({
    this.role,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.activeFarmTenantId,
    this.userId,
    this.userName,
    this.phone,
    this.tenantId,
  });

  const AppSession.loggedOut() : this._();

  const AppSession.authenticated(DemoRole role) : this._(role: role);

  const AppSession.withTokens({
    required DemoRole role,
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? activeFarmTenantId,
  }) : this._(
          role: role,
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAt: expiresAt,
          activeFarmTenantId: activeFarmTenantId,
        );

  const AppSession.withCredentials({
    required DemoRole role,
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? activeFarmTenantId,
    int? userId,
    String? userName,
    String? phone,
    int? tenantId,
  }) : this._(
          role: role,
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAt: expiresAt,
          activeFarmTenantId: activeFarmTenantId,
          userId: userId,
          userName: userName,
          phone: phone,
          tenantId: tenantId,
        );

  final DemoRole? role;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? activeFarmTenantId;
  final int? userId;
  final String? userName;
  final String? phone;
  final int? tenantId;

  AppSession copyWith({
    DemoRole? role,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? activeFarmTenantId,
    int? userId,
    String? userName,
    String? phone,
    int? tenantId,
  }) {
    return AppSession._(
      role: role ?? this.role,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      activeFarmTenantId: activeFarmTenantId ?? this.activeFarmTenantId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      phone: phone ?? this.phone,
      tenantId: tenantId ?? this.tenantId,
    );
  }

  bool get isLoggedIn => role != null;

  bool get isPlatformAdmin => role == DemoRole.platformAdmin;

  bool get isB2bAdmin => role == DemoRole.b2bAdmin;

  bool get isApiConsumer => role == DemoRole.apiConsumer;

  bool get canAccessAdminTab => role == DemoRole.owner;
}
