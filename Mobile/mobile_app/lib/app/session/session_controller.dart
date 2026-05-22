import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/session/app_session.dart';
import 'package:smart_livestock_demo/core/api/api_auth.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_controller.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';

class FarmDataReadyNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void markReady() => state = true;
  void reset() => state = false;
}

final farmDataReadyProvider =
    NotifierProvider<FarmDataReadyNotifier, bool>(FarmDataReadyNotifier.new);

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
        ref.invalidate(tenantListControllerProvider);
        ref.read(farmDataReadyProvider.notifier).markReady();
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
    ApiCache.instance.setRoleToken(
      role.wireName,
      ApiAuthTokens(accessToken: accessToken, refreshToken: refreshToken, expiresAt: expiresAt),
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
    ApiCache.instance.setRoleToken(
      role.wireName,
      ApiAuthTokens(accessToken: trimmed),
    );
  }

  void updateActiveFarm(String farmId) {
    state = state.copyWith(activeFarmTenantId: farmId);
  }

  void logout() {
    state = const AppSession.loggedOut();
    ApiCache.instance.reset();
  }

  Future<bool> loginWithCredentials({
    required String phone,
    required String password,
  }) async {
    final cache = ApiCache.instance;
    final result = await cache.authenticateWithCredentials(
      phone: phone,
      password: password,
    );
    if (result == null) return false;

    final user = result.user;
    final roleStr = user['role'] as String? ?? '';
    final role = _roleFromWireName(roleStr);
    if (role == null) return false;

    // Set session state first so UI responds immediately.
    state = AppSession.withCredentials(
      role: role,
      accessToken: result.accessToken,
      userId: user['id'] as int?,
      userName: user['name'] as String?,
      phone: user['phone'] as String?,
      tenantId: user['tenantId'] as int?,
    );

    // Preload data; failure does not block login.
    try {
      final tokens = ApiAuthTokens(accessToken: result.accessToken);
      cache.setRoleToken(role.wireName, tokens);
      cache.skipPhase2Endpoints = true;

      // For owner/worker: load farms first, set activeFarmId, then init
      if (role == DemoRole.owner || role == DemoRole.worker) {
        final farmData = await cache.fetchFarms(
          role.wireName,
          tokens: tokens,
        );
        if (farmData != null) {
          final rawItems = farmData['items'];
          if (rawItems is List && rawItems.isNotEmpty) {
            final firstFarm = rawItems.first;
            if (firstFarm is Map<String, dynamic>) {
              final rawId = firstFarm['id'];
              final farmId = rawId is int ? rawId.toString() : rawId as String?;
              if (farmId != null && (cache.activeFarmId == null || cache.activeFarmId!.isEmpty)) {
                cache.activeFarmId = farmId;
              }
            }
          }
        }
      }

      await cache.init(
        role.wireName,
        tokens: tokens,
        allowMockTokenFallback: false,
      );
      ref.invalidate(b2bDashboardControllerProvider);
      ref.invalidate(b2bContractControllerProvider);
      // Invalidate tenant list so platform_admin page picks up loaded data.
      // Without this, the page renders before cache.init completes and shows
      // "Live API 未连接" because the controller was built with an empty cache.
      ref.invalidate(tenantListControllerProvider);
      ref.read(farmDataReadyProvider.notifier).markReady();
    } catch (e) {
      debugPrint('Data preload failed: $e');
    }

    return true;
  }

  DemoRole? _roleFromWireName(String wireName) {
    return switch (wireName.toUpperCase()) {
      'OWNER' => DemoRole.owner,
      'WORKER' => DemoRole.worker,
      'PLATFORM_ADMIN' => DemoRole.platformAdmin,
      'B2B_ADMIN' => DemoRole.b2bAdmin,
      'API_CONSUMER' => DemoRole.apiConsumer,
      _ => null,
    };
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, AppSession>(SessionController.new);
