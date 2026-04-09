import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/dashboard/domain/dashboard_repository.dart';

class MockDashboardRepository implements DashboardRepository {
  const MockDashboardRepository();

  @override
  DashboardViewData load(ViewState viewState) {
    return DashboardViewData(
      viewState: viewState,
      metrics: DemoSeed.dashboardMetrics,
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无看板数据',
        ViewState.error => '加载失败（演示）',
        ViewState.forbidden => '无权限查看该数据（演示）',
        ViewState.offline => '离线数据（演示）：展示最近同步时间为 —',
        ViewState.normal => null,
      },
    );
  }
}
