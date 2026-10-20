import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/api/jwt_decoder.dart';
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

  /// Super-admin context entry (design 2026-10-19 §4.2/§4.7): swap the
  /// session onto a switched context token. The first switch after login
  /// preserves the root token; later switches reuse it (ruling #3, direct
  /// switch). Returns null on success, otherwise a user-facing message.
  Future<String?> enterContext({
    required String role,
    int? tenantId,
    String? tenantName,
  }) async {
    try {
      if (await JwtStorage.instance.getRootToken() == null) {
        final currentToken = await ApiClient.instance.getStoredToken();
        final currentInfo = await JwtStorage.instance.getUserInfo();
        if (currentToken != null) {
          await JwtStorage.instance.saveRootToken(currentToken);
        }
        if (currentInfo != null) {
          await JwtStorage.instance.saveRootUserInfo(currentInfo);
        }
      }
      final data = await ApiClient.instance.switchContext(
        role: role,
        tenantId: tenantId,
        tenantName: tenantName,
      );
      final user = data['user'] as Map<String, dynamic>;
      final contextRole = UserRole.fromString(user['role'] as String? ?? '');
      state = AppSession.authenticated(
        role: contextRole,
        accessToken: await ApiClient.instance.getStoredToken() ?? '',
        userId: user['id'] as int?,
        userName: user['name'] as String?,
        phone: user['phone'] as String?,
        tenantId: user['tenantId'] as int?,
        username: user['username'] as String?,
        impersonated: true,
        impersonatedTenantName: tenantName,
      );
      if (contextRole == UserRole.owner || contextRole == UserRole.worker) {
        ref.read(farmSwitcherControllerProvider.notifier).loadFarms();
      }
      await _rememberRecent(
          role: role, tenantId: tenantId, tenantName: tenantName);
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  /// Keeps the quick-switch history fresh: newest first, at most three,
  /// deduplicated by role+tenant (picker sheet §2.5). Best-effort only.
  Future<void> _rememberRecent({
    required String role,
    int? tenantId,
    String? tenantName,
  }) async {
    try {
      final recents = await JwtStorage.instance.getRecentContexts();
      final entry = <String, dynamic>{
        'role': role,
        if (tenantId != null) 'tenantId': tenantId,
        if (tenantName != null) 'tenantName': tenantName,
      };
      final key = '$role@$tenantId';
      final filtered = recents
          .where((m) => '${m['role']}@${m['tenantId']}' != key)
          .toList();
      filtered.insert(0, entry);
      await JwtStorage.instance.saveRecentContexts(filtered.take(3).toList());
    } catch (_) {
      // History is a convenience; ignore storage failures.
    }
  }

  /// Leave the switched context and restore the root (picker) session
  /// without a re-login while the root token is alive (ruling #2).
  Future<void> exitContext() async {
    final rootToken = await JwtStorage.instance.getRootToken();
    final rootInfo = await JwtStorage.instance.getRootUserInfo();
    final payload = rootToken == null ? null : JwtDecoder.tryDecode(rootToken);
    if (rootToken == null || rootInfo == null || payload == null || JwtDecoder.isExpired(payload)) {
      await logout();
      return;
    }
    await JwtStorage.instance.saveAccessToken(rootToken);
    await JwtStorage.instance.saveUserInfo(rootInfo);
    await JwtStorage.instance.clearRoot();
    await JwtStorage.instance.deleteActiveFarmId();
    ApiClient.instance.setActiveFarmId(null);
    state = AppSession.authenticated(
      role: UserRole.fromString(payload['role'] as String? ?? ''),
      accessToken: rootToken,
      userId: rootInfo['id'] as int?,
      userName: rootInfo['name'] as String?,
      phone: rootInfo['phone'] as String?,
      tenantId: rootInfo['tenantId'] as int?,
      username: rootInfo['username'] as String?,
    );
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
