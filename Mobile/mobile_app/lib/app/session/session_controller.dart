import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/api/api_exception.dart';
import 'package:smart_livestock_demo/app/session/app_session.dart';
import 'package:smart_livestock_demo/core/models/user_role.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_controller.dart';

class SessionController extends Notifier<AppSession> {
  @override
  AppSession build() => AppSession.loggedOut;

  Future<bool> login({required String phone, required String password}) async {
    try {
      final user = await ApiClient.instance.login(phone: phone, password: password);
      final roleStr = user['role'] as String? ?? '';
      final role = UserRole.fromString(roleStr);

      state = AppSession.authenticated(
        role: role,
        accessToken: await ApiClient.instance.getStoredToken() ?? '',
        userId: user['id'] as int?,
        userName: user['name'] as String?,
        phone: user['phone'] as String?,
        tenantId: user['tenantId'] as int?,
        username: user['username'] as String?,
      );

      if (role == UserRole.owner || role == UserRole.worker) {
        await ref.read(farmSwitcherControllerProvider.notifier).loadFarms();
      }

      return true;
    } on AuthException {
      return false;
    }
  }

  void updateActiveFarm(String farmId) {
    state = state.copyWith(activeFarmId: farmId);
    ApiClient.instance.setActiveFarmId(farmId);
  }

  Future<void> logout() async {
    await ApiClient.instance.logout();
    state = AppSession.loggedOut;
    ApiClient.instance.setActiveFarmId(null);
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, AppSession>(SessionController.new);
