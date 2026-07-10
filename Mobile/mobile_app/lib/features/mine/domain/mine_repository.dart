class UserProfile {
  const UserProfile({
    this.id,
    this.username,
    this.name,
    this.phone,
    this.role,
    this.tenantId,
    this.active,
  });

  final int? id;
  final String? username;
  final String? name;
  final String? phone;
  final String? role;
  final int? tenantId;
  final bool? active;

  String get displayName => name ?? phone ?? username ?? '用户';
}

class TenantInfo {
  const TenantInfo({
    this.id,
    this.name,
    this.contactName,
    this.contactPhone,
    this.phase,
  });

  final int? id;
  final String? name;
  final String? contactName;
  final String? contactPhone;
  final String? phase;
}

abstract class MineRepository {
  Future<UserProfile> loadProfile();
  Future<UserProfile> updateProfile(Map<String, dynamic> body);
  Future<void> changePassword(String oldPassword, String newPassword);
  Future<TenantInfo> loadTenantInfo();
}
