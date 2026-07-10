import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/mine/domain/mine_repository.dart';

class MineApiRepository implements MineRepository {
  const MineApiRepository();

  @override
  Future<UserProfile> loadProfile() async {
    final data = await ApiClient.instance.get('/me');
    return UserProfile(
      id: data['id'] as int?,
      username: data['username'] as String?,
      name: data['name'] as String?,
      phone: data['phone'] as String?,
      role: data['role'] as String?,
      tenantId: data['tenantId'] as int?,
      active: data['active'] as bool?,
    );
  }

  @override
  Future<UserProfile> updateProfile(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.put('/me', body: body);
    return UserProfile(
      id: data['id'] as int?,
      username: data['username'] as String?,
      name: data['name'] as String?,
      phone: data['phone'] as String?,
      role: data['role'] as String?,
      tenantId: data['tenantId'] as int?,
      active: data['active'] as bool?,
    );
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await ApiClient.instance.put('/me/password', body: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  @override
  Future<TenantInfo> loadTenantInfo() async {
    final data = await ApiClient.instance.get('/tenants/me');
    return TenantInfo(
      id: data['id'] as int?,
      name: data['name'] as String?,
      contactName: data['contactName'] as String?,
      contactPhone: data['contactPhone'] as String?,
      phase: data['phase'] as String?,
    );
  }
}
