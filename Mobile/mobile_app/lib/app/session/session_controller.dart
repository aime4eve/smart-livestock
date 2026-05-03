import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/session/app_session.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_controller.dart';

class SessionController extends Notifier<AppSession> {
  @override
  AppSession build() => const AppSession.loggedOut();

  void login(DemoRole role) {
    state = AppSession.authenticated(role);
    _ensureCacheForRole(role);
  }

  Future<void> _ensureCacheForRole(DemoRole role) async {
    final appMode = ref.read(appModeProvider);
    if (!appMode.isLive) return;
    final cache = ApiCache.instance;
    if (!cache.initialized || !cache.hasRoleData(role.wireName)) {
      try {
        await cache.initWithRoleAuth(role.wireName);
        ref.invalidate(b2bDashboardControllerProvider);
        ref.invalidate(b2bContractControllerProvider);
      } catch (e) {
        debugPrint('ApiCache re-init for ${role.wireName} failed: $e');
      }
    }
  }

  void loginWithTokens({
    required DemoRole role,
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? activeFarmTenantId,
  }) {
    state = AppSession.withTokens(
      role: role,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      activeFarmTenantId: activeFarmTenantId,
    );
  }

  DemoRole? _roleFromMockToken(String token) {
    return switch (token) {
      'mock-token-owner' => DemoRole.owner,
      'mock-token-worker' => DemoRole.worker,
      'mock-token-platform-admin' => DemoRole.platformAdmin,
      'mock-token-b2b-admin' => DemoRole.b2bAdmin,
      'mock-token-api-consumer' => DemoRole.apiConsumer,
      _ when token.startsWith('mock-token-u_') => DemoRole.owner,
      _ => null,
    };
  }

  void loginWithToken(String token) {
    final trimmed = token.trim();
    final role = _roleFromMockToken(trimmed);
    if (role == null) return;
    state = AppSession.withTokens(
      role: role,
      accessToken: trimmed,
    );
  }

  void updateActiveFarm(String farmId) {
    state = state.copyWith(activeFarmTenantId: farmId);
  }

  void logout() {
    state = const AppSession.loggedOut();
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, AppSession>(SessionController.new);
