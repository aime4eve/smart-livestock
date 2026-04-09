import 'package:smart_livestock_demo/core/models/demo_role.dart';

class AppSession {
  const AppSession._({this.role});

  const AppSession.loggedOut() : this._();

  const AppSession.authenticated(DemoRole role) : this._(role: role);

  final DemoRole? role;

  bool get isLoggedIn => role != null;

  bool get isOps => role == DemoRole.ops;

  bool get canAccessAdminTab => role == DemoRole.owner;
}
