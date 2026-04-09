import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/admin/domain/admin_repository.dart';

class MockAdminRepository implements AdminRepository {
  const MockAdminRepository();

  @override
  AdminViewData load({
    required ViewState viewState,
    required bool licenseAdjusted,
  }) {
    return AdminViewData(
      viewState: viewState,
      tenantTitle: '华东示范牧场',
      tenantSubtitle: 'active · GPS 428/500',
      licenseAdjusted: licenseAdjusted,
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无租户',
        ViewState.error => '租户列表加载失败（演示）',
        ViewState.forbidden => '无平台运维权限（演示）',
        ViewState.offline => '离线：租户数据不可改（演示）',
        ViewState.normal => null,
      },
    );
  }
}
