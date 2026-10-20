import 'package:hkt_livestock_agentic/core/models/user_role.dart';

class AppSession {
  const AppSession._({
    this.role,
    this.accessToken,
    this.userId,
    this.userName,
    this.phone,
    this.tenantId,
    this.username,
    this.activeFarmId,
    this.mustChangePassword = false,
    this.impersonated = false,
    this.impersonatedTenantName,
  });

  static const loggedOut = AppSession._();

  const AppSession.authenticated({
    required this.role,
    required this.accessToken,
    this.userId,
    this.userName,
    this.phone,
    this.tenantId,
    this.username,
    this.activeFarmId,
    this.mustChangePassword = false,
    this.impersonated = false,
    this.impersonatedTenantName,
  });

  final UserRole? role;
  final String? accessToken;
  final int? userId;
  final String? userName;
  final String? phone;
  final int? tenantId;
  final String? username;
  final String? activeFarmId;

  /// NIX-191: true while the account must replace its initial password
  /// before any other API can be used.
  final bool mustChangePassword;

  /// Super-admin context entry (design 2026-10-19 §4.2): true while this
  /// session runs on a switched context token — role/tenantId describe the
  /// chosen context, and the root token stays in storage for quick switch.
  final bool impersonated;

  /// Display-only tenant name for the acting-as banner (null for the
  /// platform context, where the banner shows just the role).
  final String? impersonatedTenantName;

  bool get isLoggedIn => role != null;

  AppSession copyWith({String? activeFarmId, bool? mustChangePassword}) {
    return AppSession._(
      role: role,
      accessToken: accessToken,
      userId: userId,
      userName: userName,
      phone: phone,
      tenantId: tenantId,
      username: username,
      activeFarmId: activeFarmId ?? this.activeFarmId,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      impersonated: impersonated,
      impersonatedTenantName: impersonatedTenantName,
    );
  }
}
