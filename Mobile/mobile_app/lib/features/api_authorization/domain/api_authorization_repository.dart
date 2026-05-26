class ApiKeyItem {
  const ApiKeyItem({
    required this.id,
    this.name,
    this.prefix,
    this.tenantId,
    this.status,
    this.createdAt,
  });

  final String id;
  final String? name;
  final String? prefix;
  final String? tenantId;
  final String? status;
  final String? createdAt;
}

class ApiKeyListResult {
  const ApiKeyListResult({
    required this.items,
    this.total = 0,
  });

  final List<ApiKeyItem> items;
  final int total;

  bool get isEmpty => items.isEmpty;
}

class ApiKeyCreateResult {
  const ApiKeyCreateResult({required this.info, required this.fullKey});

  final ApiKeyItem info;
  final String fullKey;
}

abstract class ApiAuthorizationRepository {
  Future<ApiKeyListResult> loadApiKeys();
  Future<ApiKeyCreateResult> createApiKey(Map<String, dynamic> body);
  Future<void> updateApiKeyStatus(String keyId, String status);
  Future<void> revokeApiKey(String keyId);
}
