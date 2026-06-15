import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/features/admin/data/admin_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/domain/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return const AdminApiRepository();
});

// --- Overview ---

class AdminOverviewController extends AsyncNotifier<AdminOverviewData> {
  @override
  Future<AdminOverviewData> build() async {
    return ref.read(adminRepositoryProvider).loadOverview();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(adminRepositoryProvider).loadOverview());
  }
}

final adminOverviewControllerProvider =
    AsyncNotifierProvider<AdminOverviewController, AdminOverviewData>(
  AdminOverviewController.new,
);

// --- Tenants ---

class TenantListController extends AsyncNotifier<AdminListResult<TenantSummary>> {
  @override
  Future<AdminListResult<TenantSummary>> build() async {
    return ref.read(adminRepositoryProvider).loadTenants();
  }

  Future<void> refresh({String? status, String? keyword}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).loadTenants(status: status, keyword: keyword),
    );
  }

  Future<void> updateStatus(String tenantId, String status) async {
    await ref.read(adminRepositoryProvider).updateTenantStatus(tenantId, status);
    ref.invalidateSelf();
  }
}

final tenantListControllerProvider =
    AsyncNotifierProvider<TenantListController, AdminListResult<TenantSummary>>(
  TenantListController.new,
);

// --- Users ---

class UserListController extends AsyncNotifier<AdminListResult<UserSummary>> {
  @override
  Future<AdminListResult<UserSummary>> build() async {
    return ref.read(adminRepositoryProvider).loadUsers();
  }

  Future<void> refresh({String? tenantId, String? role, String? keyword}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).loadUsers(tenantId: tenantId, role: role, keyword: keyword),
    );
  }

  Future<void> updateStatus(String userId, String status) async {
    await ref.read(adminRepositoryProvider).updateUserStatus(userId, status);
    ref.invalidateSelf();
  }

  Future<void> resetPassword(String userId, String newPassword) async {
    await ref.read(adminRepositoryProvider).resetPassword(userId, newPassword);
  }
}

final userListControllerProvider =
    AsyncNotifierProvider<UserListController, AdminListResult<UserSummary>>(
  UserListController.new,
);

// --- Farms ---

class FarmListController extends AsyncNotifier<AdminListResult<FarmSummary>> {
  @override
  Future<AdminListResult<FarmSummary>> build() async {
    return ref.read(adminRepositoryProvider).loadFarms();
  }

  Future<void> refresh({String? tenantId, String? keyword}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).loadFarms(tenantId: tenantId, keyword: keyword),
    );
  }
}

final farmListControllerProvider =
    AsyncNotifierProvider<FarmListController, AdminListResult<FarmSummary>>(
  FarmListController.new,
);

// --- API Keys ---

class ApiKeyListController extends AsyncNotifier<AdminListResult<ApiKeyInfo>> {
  @override
  Future<AdminListResult<ApiKeyInfo>> build() async {
    return ref.read(adminRepositoryProvider).loadApiKeys();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(adminRepositoryProvider).loadApiKeys());
  }

  Future<ApiKeyCreateResult?> createApiKey(Map<String, dynamic> body) async {
    try {
      final result = await ref.read(adminRepositoryProvider).createApiKey(body);
      ref.invalidateSelf();
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateStatus(String keyId, String status) async {
    await ref.read(adminRepositoryProvider).updateApiKeyStatus(keyId, status);
    ref.invalidateSelf();
  }

  Future<void> revoke(String keyId) async {
    await ref.read(adminRepositoryProvider).revokeApiKey(keyId);
    ref.invalidateSelf();
  }
}

final apiKeyListControllerProvider =
    AsyncNotifierProvider<ApiKeyListController, AdminListResult<ApiKeyInfo>>(
  ApiKeyListController.new,
);
