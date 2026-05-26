import 'package:smart_livestock_demo/core/models/user_role.dart';

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
  });

  final UserRole? role;
  final String? accessToken;
  final int? userId;
  final String? userName;
  final String? phone;
  final int? tenantId;
  final String? username;
  final String? activeFarmId;

  bool get isLoggedIn => role != null;

  AppSession copyWith({String? activeFarmId}) {
    return AppSession._(
      role: role,
      accessToken: accessToken,
      userId: userId,
      userName: userName,
      phone: phone,
      tenantId: tenantId,
      username: username,
      activeFarmId: activeFarmId ?? this.activeFarmId,
    );
  }
}
