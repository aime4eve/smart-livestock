import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/admin/domain/admin_repository.dart';

class AdminApiRepository implements AdminRepository {
  const AdminApiRepository();

  @override
  Future<AdminOverviewData> loadOverview() async {
    final tenants = await loadTenants();
    final users = await loadUsers();
    final farms = await loadFarms();
    return AdminOverviewData(
      tenantCount: tenants.total,
      userCount: users.total,
      farmCount: farms.total,
    );
  }

  // --- Tenants ---

  @override
  Future<AdminListResult<TenantSummary>> loadTenants({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? keyword,
  }) async {
    final query = <String, String>{'page': '$page', 'pageSize': '$pageSize'};
    if (status != null) query['status'] = status;
    if (keyword != null) query['keyword'] = keyword;
    final qs = query.entries.map((e) => '${e.key}=${e.value}').join('&');
    final data = await ApiClient.instance.get('/admin/tenants?$qs');
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(_parseTenantSummary)
        .toList();
    return AdminListResult(
      items: items,
      page: data['page'] as int? ?? page,
      pageSize: data['pageSize'] as int? ?? pageSize,
      total: data['total'] as int? ?? 0,
    );
  }

  @override
  Future<TenantDetail> loadTenantDetail(String tenantId) async {
    final data = await ApiClient.instance.get('/admin/tenants/$tenantId');
    return _parseTenantDetail(data);
  }

  @override
  Future<TenantSummary> createTenant(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post('/admin/tenants', body: body);
    return _parseTenantSummary(data);
  }

  @override
  Future<TenantSummary> updateTenant(String tenantId, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.put('/admin/tenants/$tenantId', body: body);
    return _parseTenantSummary(data);
  }

  @override
  Future<void> updateTenantStatus(String tenantId, String status) async {
    await ApiClient.instance.put('/admin/tenants/$tenantId/status', body: {'status': status});
  }

  // --- Users ---

  @override
  Future<AdminListResult<UserSummary>> loadUsers({
    int page = 1,
    int pageSize = 20,
    String? tenantId,
    String? role,
    String? keyword,
  }) async {
    final query = <String, String>{'page': '$page', 'pageSize': '$pageSize'};
    if (tenantId != null) query['tenantId'] = tenantId;
    if (role != null) query['role'] = role;
    if (keyword != null) query['keyword'] = keyword;
    final qs = query.entries.map((e) => '${e.key}=${e.value}').join('&');
    final data = await ApiClient.instance.get('/admin/users?$qs');
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(_parseUserSummary)
        .toList();
    return AdminListResult(
      items: items,
      page: data['page'] as int? ?? page,
      pageSize: data['pageSize'] as int? ?? pageSize,
      total: data['total'] as int? ?? 0,
    );
  }

  @override
  Future<UserDetail> loadUserDetail(String userId) async {
    final data = await ApiClient.instance.get('/admin/users/$userId');
    return _parseUserDetail(data);
  }

  @override
  Future<UserSummary> createUser(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post('/admin/users', body: body);
    return _parseUserSummary(data);
  }

  @override
  Future<UserSummary> updateUser(String userId, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.put('/admin/users/$userId', body: body);
    return _parseUserSummary(data);
  }

  @override
  Future<void> updateUserStatus(String userId, String status) async {
    await ApiClient.instance.put('/admin/users/$userId/status', body: {'status': status});
  }

  @override
  Future<void> resetPassword(String userId, String newPassword) async {
    await ApiClient.instance.post('/admin/users/$userId/reset-password', body: {'newPassword': newPassword});
  }

  // --- Farms ---

  @override
  Future<AdminListResult<FarmSummary>> loadFarms({
    int page = 1,
    int pageSize = 20,
    String? tenantId,
    String? keyword,
  }) async {
    final query = <String, String>{'page': '$page', 'pageSize': '$pageSize'};
    if (tenantId != null) query['tenantId'] = tenantId;
    if (keyword != null) query['keyword'] = keyword;
    final qs = query.entries.map((e) => '${e.key}=${e.value}').join('&');
    final data = await ApiClient.instance.get('/admin/farms?$qs');
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(_parseFarmSummary)
        .toList();
    return AdminListResult(
      items: items,
      page: data['page'] as int? ?? page,
      pageSize: data['pageSize'] as int? ?? pageSize,
      total: data['total'] as int? ?? 0,
    );
  }

  @override
  Future<FarmDetail> loadFarmDetail(String farmId) async {
    final data = await ApiClient.instance.get('/admin/farms/$farmId');
    return _parseFarmDetail(data);
  }

  // --- API Keys ---

  @override
  Future<AdminListResult<ApiKeyInfo>> loadApiKeys({int page = 1, int pageSize = 20}) async {
    final data = await ApiClient.instance.get('/admin/api-keys?page=$page&pageSize=$pageSize');
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(_parseApiKeyInfo)
        .toList();
    return AdminListResult(
      items: items,
      page: data['page'] as int? ?? page,
      pageSize: data['pageSize'] as int? ?? pageSize,
      total: data['total'] as int? ?? 0,
    );
  }

  @override
  Future<ApiKeyCreateResult> createApiKey(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post('/admin/api-keys', body: body);
    return ApiKeyCreateResult(
      info: ApiKeyInfo(
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

  // --- Parsers ---

  TenantSummary _parseTenantSummary(Map<String, dynamic> m) {
    final rawId = m['id'];
    return TenantSummary(
      id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
      name: m['name'] as String? ?? '',
      contactName: m['contactName'] as String?,
      contactPhone: m['contactPhone'] as String?,
      phase: m['phase'] as String?,
      status: m['status'] as String?,
      farmCount: m['farmCount'] as int? ?? 0,
      userCount: m['userCount'] as int? ?? 0,
      deviceCount: m['deviceCount'] as int? ?? 0,
      createdAt: m['createdAt'] as String?,
    );
  }

  TenantDetail _parseTenantDetail(Map<String, dynamic> m) {
    final rawId = m['id'];
    return TenantDetail(
      id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
      name: m['name'] as String? ?? '',
      contactName: m['contactName'] as String?,
      contactPhone: m['contactPhone'] as String?,
      phase: m['phase'] as String?,
      status: m['status'] as String?,
      farmCount: m['farmCount'] as int? ?? 0,
      userCount: m['userCount'] as int? ?? 0,
      deviceCount: m['deviceCount'] as int? ?? 0,
      activeLicenseCount: m['activeLicenseCount'] as int? ?? 0,
      createdAt: m['createdAt'] as String?,
      updatedAt: m['updatedAt'] as String?,
    );
  }

  UserSummary _parseUserSummary(Map<String, dynamic> m) {
    final rawId = m['id'];
    return UserSummary(
      id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
      name: m['name'] as String? ?? '',
      username: m['username'] as String?,
      phone: m['phone'] as String?,
      role: m['role'] as String?,
      tenantId: m['tenantId']?.toString(),
      tenantName: m['tenantName'] as String?,
      status: m['status'] as String?,
      farmCount: m['farmCount'] as int? ?? 0,
      lastLoginAt: m['lastLoginAt'] as String?,
    );
  }

  UserDetail _parseUserDetail(Map<String, dynamic> m) {
    final rawId = m['id'];
    return UserDetail(
      id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
      name: m['name'] as String? ?? '',
      username: m['username'] as String?,
      phone: m['phone'] as String?,
      role: m['role'] as String?,
      tenantId: m['tenantId']?.toString(),
      status: m['status'] as String?,
      farms: (m['farms'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList(),
      lastLoginAt: m['lastLoginAt'] as String?,
      createdAt: m['createdAt'] as String?,
    );
  }

  FarmSummary _parseFarmSummary(Map<String, dynamic> m) {
    final rawId = m['id'];
    return FarmSummary(
      id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
      name: m['name'] as String? ?? '',
      tenantId: m['tenantId']?.toString(),
      tenantName: m['tenantName'] as String?,
      status: m['status'] as String?,
      livestockCount: m['livestockCount'] as int? ?? 0,
      deviceCount: m['deviceCount'] as int? ?? 0,
      userCount: m['userCount'] as int? ?? 0,
      createdAt: m['createdAt'] as String?,
    );
  }

  FarmDetail _parseFarmDetail(Map<String, dynamic> m) {
    final rawId = m['id'];
    return FarmDetail(
      id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
      name: m['name'] as String? ?? '',
      tenantId: m['tenantId']?.toString(),
      status: m['status'] as String?,
      livestockCount: m['livestockCount'] as int? ?? 0,
      deviceCount: m['deviceCount'] as int? ?? 0,
      userCount: m['userCount'] as int? ?? 0,
      activeAlertCount: m['activeAlertCount'] as int? ?? 0,
      createdAt: m['createdAt'] as String?,
    );
  }

  ApiKeyInfo _parseApiKeyInfo(Map<String, dynamic> m) {
    final rawId = m['id'] ?? m['keyId'];
    return ApiKeyInfo(
      id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
      name: m['name'] as String?,
      prefix: m['prefix'] as String?,
      tenantId: m['tenantId']?.toString(),
      status: m['status'] as String?,
      createdAt: m['createdAt'] as String?,
    );
  }
}
