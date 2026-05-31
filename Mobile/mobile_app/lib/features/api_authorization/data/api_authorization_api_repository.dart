import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/features/api_authorization/domain/api_authorization_repository.dart';

class ApiAuthorizationApiRepository implements ApiAuthorizationRepository {
  const ApiAuthorizationApiRepository();

  @override
  Future<ApiKeyListResult> loadApiKeys() async {
    final data = await ApiClient.instance.get('/portal/keys?page=1&pageSize=100');
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(_parseApiKeyItem)
        .toList();
    return ApiKeyListResult(items: items, total: data['total'] as int? ?? 0);
  }

  @override
  Future<ApiKeyCreateResult> createApiKey(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post('/portal/keys', body: body);
    return ApiKeyCreateResult(
      info: _parseApiKeyItem(data),
      fullKey: data['rawKey'] as String? ?? '',
    );
  }

  @override
  Future<void> updateApiKeyStatus(String keyId, String status) async {
    await ApiClient.instance.put('/portal/keys/$keyId/status', body: {'status': status});
  }

  @override
  Future<void> revokeApiKey(String keyId) async {
    await ApiClient.instance.delete('/portal/keys/$keyId');
  }

  @override
  Future<UsageOverview> loadDashboard(String from, String to) async {
    final data = await ApiClient.instance.get('/portal/keys/dashboard?from=$from&to=$to');
    return UsageOverview(
      totalCalls: data['totalCalls'] as int? ?? 0,
      successCalls: data['successCalls'] as int? ?? 0,
      errorCalls: data['errorCalls'] as int? ?? 0,
      avgResponseMs: (data['avgResponseMs'] as num?)?.toDouble() ?? 0.0,
      from: data['from'] as String?,
      to: data['to'] as String?,
    );
  }

  ApiKeyItem _parseApiKeyItem(Map<String, dynamic> m) {
    final rawId = m['id'];
    return ApiKeyItem(
      id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
      name: m['keyName'] as String? ?? m['name'] as String?,
      prefix: m['prefix'] as String?,
      tenantId: m['tenantId']?.toString(),
      status: m['status'] as String?,
      scopes: m['scopes'] as String?,
      requestsPerMinute: m['requestsPerMinute'] as int?,
      dailyQuota: m['dailyQuota'] as int?,
      description: m['description'] as String?,
      createdAt: m['createdAt'] as String?,
      lastUsedAt: m['lastUsedAt'] as String?,
    );
  }
}
