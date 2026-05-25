import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/features/admin/domain/admin_repository.dart';

class AdminApiRepository implements AdminRepository {
  const AdminApiRepository();

  @override
  Future<AdminViewData> load() async {
    try {
      final data = await ApiClient.instance.get('/me');
      final tenantName = data['tenantName'] as String? ?? '管理后台';
      final role = data['role'] as String? ?? 'platform_admin';
      return AdminViewData(
        tenantTitle: tenantName,
        tenantSubtitle: '角色: $role',
        licenseAdjusted: false,
      );
    } catch (_) {
      return const AdminViewData(
        tenantTitle: '管理后台',
        tenantSubtitle: '平台管理员',
        licenseAdjusted: false,
      );
    }
  }
}
