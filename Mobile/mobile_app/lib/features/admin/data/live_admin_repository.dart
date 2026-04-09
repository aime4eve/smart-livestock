import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/admin/data/mock_admin_repository.dart';
import 'package:smart_livestock_demo/features/admin/domain/admin_repository.dart';

class LiveAdminRepository implements AdminRepository {
  const LiveAdminRepository();

  static const MockAdminRepository _fallback = MockAdminRepository();

  @override
  AdminViewData load({
    required ViewState viewState,
    required bool licenseAdjusted,
  }) {
    final cache = ApiCache.instance;
    if (!cache.initialized) {
      return _fallback.load(
        viewState: viewState,
        licenseAdjusted: licenseAdjusted,
      );
    }

    final first = cache.tenants.isNotEmpty ? cache.tenants.first : null;
    final name = first?['name'] as String? ?? '暂无租户';
    final status = first?['status'] as String? ?? 'unknown';
    final used = first?['licenseUsed'] as int? ?? 0;
    final total = first?['licenseTotal'] as int? ?? 0;
    final subtitle = '$status · GPS $used/$total';

    return AdminViewData(
      viewState: viewState,
      tenantTitle: name,
      tenantSubtitle: subtitle,
      licenseAdjusted: licenseAdjusted,
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无租户',
        ViewState.error => '租户列表加载失败',
        ViewState.forbidden => '无平台运维权限',
        ViewState.offline => '离线：租户数据不可改',
        ViewState.normal => null,
      },
    );
  }
}
