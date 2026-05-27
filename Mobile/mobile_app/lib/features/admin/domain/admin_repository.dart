// --- Tenant ---

class TenantSummary {
  const TenantSummary({
    required this.id,
    required this.name,
    this.contactName,
    this.contactPhone,
    this.phase,
    this.status,
    this.farmCount = 0,
    this.userCount = 0,
    this.deviceCount = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? contactName;
  final String? contactPhone;
  final String? phase;
  final String? status;
  final int farmCount;
  final int userCount;
  final int deviceCount;
  final String? createdAt;
}

class TenantDetail {
  const TenantDetail({
    required this.id,
    required this.name,
    this.contactName,
    this.contactPhone,
    this.phase,
    this.status,
    this.farmCount = 0,
    this.userCount = 0,
    this.deviceCount = 0,
    this.activeLicenseCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? contactName;
  final String? contactPhone;
  final String? phase;
  final String? status;
  final int farmCount;
  final int userCount;
  final int deviceCount;
  final int activeLicenseCount;
  final String? createdAt;
  final String? updatedAt;
}

// --- User ---

class UserSummary {
  const UserSummary({
    required this.id,
    required this.name,
    this.username,
    this.phone,
    this.role,
    this.tenantId,
    this.tenantName,
    this.status,
    this.farmCount = 0,
    this.lastLoginAt,
  });

  final String id;
  final String name;
  final String? username;
  final String? phone;
  final String? role;
  final String? tenantId;
  final String? tenantName;
  final String? status;
  final int farmCount;
  final String? lastLoginAt;
}

class UserDetail {
  const UserDetail({
    required this.id,
    required this.name,
    this.username,
    this.phone,
    this.role,
    this.tenantId,
    this.status,
    this.farms = const [],
    this.lastLoginAt,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? username;
  final String? phone;
  final String? role;
  final String? tenantId;
  final String? status;
  final List<Map<String, dynamic>> farms;
  final String? lastLoginAt;
  final String? createdAt;
}

// --- Farm ---

class FarmSummary {
  const FarmSummary({
    required this.id,
    required this.name,
    this.tenantId,
    this.tenantName,
    this.status,
    this.livestockCount = 0,
    this.deviceCount = 0,
    this.userCount = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? tenantId;
  final String? tenantName;
  final String? status;
  final int livestockCount;
  final int deviceCount;
  final int userCount;
  final String? createdAt;
}

class FarmDetail {
  const FarmDetail({
    required this.id,
    required this.name,
    this.tenantId,
    this.status,
    this.livestockCount = 0,
    this.deviceCount = 0,
    this.userCount = 0,
    this.activeAlertCount = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? tenantId;
  final String? status;
  final int livestockCount;
  final int deviceCount;
  final int userCount;
  final int activeAlertCount;
  final String? createdAt;
}

// --- API Key ---

class ApiKeyInfo {
  const ApiKeyInfo({
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

class ApiKeyCreateResult {
  const ApiKeyCreateResult({required this.info, required this.fullKey});

  final ApiKeyInfo info;
  final String fullKey;
}

// --- Paginated list wrapper ---

class AdminListResult<T> {
  const AdminListResult({
    required this.items,
    this.page = 1,
    this.pageSize = 20,
    this.total = 0,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;

  bool get isEmpty => items.isEmpty;
}

// --- Admin overview ---

class AdminOverviewData {
  const AdminOverviewData({
    required this.tenantCount,
    required this.userCount,
    required this.farmCount,
  });

  final int tenantCount;
  final int userCount;
  final int farmCount;
}

// --- Repository interface ---

abstract class AdminRepository {
  // Overview
  Future<AdminOverviewData> loadOverview();

  // Tenants
  Future<AdminListResult<TenantSummary>> loadTenants({int page = 1, int pageSize = 20, String? status, String? keyword});
  Future<TenantDetail> loadTenantDetail(String tenantId);
  Future<TenantSummary> createTenant(Map<String, dynamic> body);
  Future<TenantSummary> updateTenant(String tenantId, Map<String, dynamic> body);
  Future<void> updateTenantStatus(String tenantId, String status);

  // Users
  Future<AdminListResult<UserSummary>> loadUsers({int page = 1, int pageSize = 20, String? tenantId, String? role, String? keyword});
  Future<UserDetail> loadUserDetail(String userId);
  Future<UserSummary> createUser(Map<String, dynamic> body);
  Future<UserSummary> updateUser(String userId, Map<String, dynamic> body);
  Future<void> updateUserStatus(String userId, String status);
  Future<void> resetPassword(String userId, String newPassword);

  // Farms
  Future<AdminListResult<FarmSummary>> loadFarms({int page = 1, int pageSize = 20, String? tenantId, String? keyword});
  Future<FarmDetail> loadFarmDetail(String farmId);

  // API Keys
  Future<AdminListResult<ApiKeyInfo>> loadApiKeys({int page = 1, int pageSize = 20});
  Future<ApiKeyCreateResult> createApiKey(Map<String, dynamic> body);
  Future<void> updateApiKeyStatus(String keyId, String status);
  Future<void> revokeApiKey(String keyId);
}
