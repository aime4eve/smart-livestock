import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/api/jwt_storage.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';

/// Provider for the initial session state (overridden in main.dart on web).
final initialSessionProvider = Provider<AppSession>((ref) => AppSession.loggedOut);

class SessionController extends Notifier<AppSession> {
  @override
  AppSession build() => ref.read(initialSessionProvider);

  Future<bool> login({required String phone, required String password}) async {
    try {
      final user = await ApiClient.instance.login(phone: phone, password: password);
      final roleStr = user['role'] as String? ?? '';
      final role = UserRole.fromString(roleStr);

      // Set authenticated state first so GoRouter can redirect immediately.
      // Load farms in the background — the main_shell watches farmSwitcherControllerProvider
      // and will update the UI once farms are loaded.
      state = AppSession.authenticated(
        role: role,
        accessToken: await ApiClient.instance.getStoredToken() ?? '',
        userId: user['id'] as int?,
        userName: user['name'] as String?,
        phone: user['phone'] as String?,
        tenantId: user['tenantId'] as int?,
        username: user['username'] as String?,
      );

      return true;
    } on AuthException {
      return false;
    }
  }

  void updateActiveFarm(String farmId) {
    state = state.copyWith(activeFarmId: farmId);
    ApiClient.instance.setActiveFarmId(farmId);
    JwtStorage.instance.saveActiveFarmId(farmId);
  }

  Future<void> logout() async {
    await ApiClient.instance.logout();
    state = AppSession.loggedOut;
    ApiClient.instance.setActiveFarmId(null);
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, AppSession>(SessionController.new);
