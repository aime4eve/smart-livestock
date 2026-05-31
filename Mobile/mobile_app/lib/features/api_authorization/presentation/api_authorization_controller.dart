import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/api_authorization/data/api_authorization_api_repository.dart';
import 'package:smart_livestock_demo/features/api_authorization/domain/api_authorization_repository.dart';

final apiAuthorizationRepositoryProvider = Provider<ApiAuthorizationRepository>((ref) {
  return const ApiAuthorizationApiRepository();
});

class ApiAuthorizationController extends AsyncNotifier<ApiKeyListResult> {
  @override
  Future<ApiKeyListResult> build() async {
    return ref.read(apiAuthorizationRepositoryProvider).loadApiKeys();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(apiAuthorizationRepositoryProvider).loadApiKeys());
  }

  Future<void> updateStatus(String keyId, String status) async {
    await ref.read(apiAuthorizationRepositoryProvider).updateApiKeyStatus(keyId, status);
    ref.invalidateSelf();
  }

  Future<void> revoke(String keyId) async {
    await ref.read(apiAuthorizationRepositoryProvider).revokeApiKey(keyId);
    ref.invalidateSelf();
  }

  Future<ApiKeyCreateResult?> createApiKey(Map<String, dynamic> body) async {
    try {
      final result = await ref.read(apiAuthorizationRepositoryProvider).createApiKey(body);
      ref.invalidateSelf();
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<UsageOverview> loadDashboard(String from, String to) {
    return ref.read(apiAuthorizationRepositoryProvider).loadDashboard(from, to);
  }
}

final apiAuthorizationControllerProvider =
    AsyncNotifierProvider<ApiAuthorizationController, ApiKeyListResult>(
  ApiAuthorizationController.new,
);
