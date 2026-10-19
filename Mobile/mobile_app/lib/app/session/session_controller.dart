import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/api/jwt_storage.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/farm_switcher/farm_switcher_controller.dart';

/// Provider for the initial session state (overridden in main.dart on web).
final initialSessionProvider = Provider<AppSession>((ref) => AppSession.loggedOut);

class SessionController extends Notifier<AppSession> {
  @override
  AppSession build() => ref.read(initialSessionProvider);

  Future<bool> login({required String identifier, required String password}) async {
    try {
      final user = await ApiClient.instance.login(identifier: identifier, password: password);
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
        mustChangePassword: user['mustChangePassword'] == true,
      );

      // Prefetch farm list for farm-scoped roles so the ranch page doesn't
      // wait for a serial round-trip through MainShell's microtask.
      if ((role == UserRole.owner || role == UserRole.worker) &&
          !(user['mustChangePassword'] == true)) {
        ref.read(farmSwitcherControllerProvider.notifier).loadFarms();
      }

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

  /// NIX-191: re-arms the forced password-change lock when a restored session
  /// turns out to still carry must_change_password (first PASSWORD_CHANGE_REQUIRED
  /// 403 after a page refresh). The router sends the user to the change page.
  void lockForPasswordChange() {
    if (!state.isLoggedIn || state.mustChangePassword) return;
    state = state.copyWith(mustChangePassword: true);
  }

  /// NIX-191: clears the forced password-change lock after the initial
  /// password has been replaced successfully.
  void markPasswordChanged() {
    state = state.copyWith(mustChangePassword: false);
    // 改密锁生效期间 /farms 会被拦截器拒掉，loadFarms 以 loadFailed 终态收场；
    // 锁一解除就补一次加载，牧场页无需重启应用。
    final role = state.role;
    if (role == UserRole.owner || role == UserRole.worker) {
      final farms = ref.read(farmSwitcherControllerProvider);
      if (!farms.hasFarms && !farms.isLoading) {
        ref.read(farmSwitcherControllerProvider.notifier).loadFarms();
      }
    }
  }

  Future<void> logout() async {
    await ApiClient.instance.logout();
    state = AppSession.loggedOut;
    ApiClient.instance.setActiveFarmId(null);
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, AppSession>(SessionController.new);
