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
    );
  }
}
