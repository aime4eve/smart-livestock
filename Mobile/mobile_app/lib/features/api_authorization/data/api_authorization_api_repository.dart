import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/features/api_authorization/domain/api_authorization_repository.dart';

class ApiAuthorizationApiRepository implements ApiAuthorizationRepository {
  const ApiAuthorizationApiRepository();

  @override
  Future<ApiKeyListResult> loadApiKeys() async {
    final data = await ApiClient.instance.get('/admin/api-keys?page=1&pageSize=100');
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(_parseApiKeyItem)
        .toList();
    return ApiKeyListResult(
      items: items,
      total: data['total'] as int? ?? 0,
    );
  }

  @override
  Future<ApiKeyCreateResult> createApiKey(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post('/admin/api-keys', body: body);
    return ApiKeyCreateResult(
      info: ApiKeyItem(
        id: data['keyId'] as String? ?? '',
        prefix: data['prefix'] as String?,
      ),
      fullKey: data['fullKey'] as String? ?? '',
    );
  }

  @override
  Future<void> updateApiKeyStatus(String keyId, String status) async {
    await ApiClient.instance.put('/admin/api-keys/$keyId/status', body: {'status': status});
  }

  @override
  Future<void> revokeApiKey(String keyId) async {
    await ApiClient.instance.delete('/admin/api-keys/$keyId');
  }

  ApiKeyItem _parseApiKeyItem(Map<String, dynamic> m) {
    final rawId = m['id'] ?? m['keyId'];
    return ApiKeyItem(
      id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
      name: m['name'] as String?,
      prefix: m['prefix'] as String?,
      tenantId: m['tenantId']?.toString(),
      status: m['status'] as String?,
      createdAt: m['createdAt'] as String?,
    );
  }
}
