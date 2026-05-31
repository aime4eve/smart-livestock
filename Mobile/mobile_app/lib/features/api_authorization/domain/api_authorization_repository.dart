class ApiKeyItem {
  const ApiKeyItem({
    required this.id,
    this.name,
    this.prefix,
    this.tenantId,
    this.status,
    this.scopes,
    this.requestsPerMinute,
    this.dailyQuota,
    this.description,
    this.createdAt,
    this.lastUsedAt,
  });

  final String id;
  final String? name;
  final String? prefix;
  final String? tenantId;
  final String? status;
  final String? scopes;
  final int? requestsPerMinute;
  final int? dailyQuota;
  final String? description;
  final String? createdAt;
  final String? lastUsedAt;

  List<String> get scopeList =>
      scopes != null ? scopes!.split(',').where((s) => s.isNotEmpty).toList() : [];
}

class ApiKeyListResult {
  const ApiKeyListResult({required this.items, this.total = 0});

  final List<ApiKeyItem> items;
  final int total;

  bool get isEmpty => items.isEmpty;
}

class ApiKeyCreateResult {
  const ApiKeyCreateResult({required this.info, required this.fullKey});

  final ApiKeyItem info;
  final String fullKey;
}

class UsageOverview {
  const UsageOverview({
    required this.totalCalls,
    required this.successCalls,
    required this.errorCalls,
    required this.avgResponseMs,
    this.from,
    this.to,
  });

  final int totalCalls;
  final int successCalls;
  final int errorCalls;
  final double avgResponseMs;
  final String? from;
  final String? to;
}

abstract class ApiAuthorizationRepository {
  Future<ApiKeyListResult> loadApiKeys();
  Future<ApiKeyCreateResult> createApiKey(Map<String, dynamic> body);
  Future<void> updateApiKeyStatus(String keyId, String status);
  Future<void> revokeApiKey(String keyId);
  Future<UsageOverview> loadDashboard(String from, String to);
}
