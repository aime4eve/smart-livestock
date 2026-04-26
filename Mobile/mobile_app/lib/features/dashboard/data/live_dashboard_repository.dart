import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/dashboard/domain/dashboard_repository.dart';

class LiveDashboardRepository implements DashboardRepository {
  const LiveDashboardRepository();

  @override
  DashboardViewData load(ViewState viewState) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.lastLiveSource != 'api') {
      return const DashboardViewData(
        viewState: ViewState.error,
        metrics: [],
        message: 'Live API 未连接',
      );
    }

    final metrics = cache.dashboardMetrics
        .map((m) => DashboardMetric(
              widgetKey: 'dashboard-metric-${m['key']}',
              title: m['title'] as String,
              value: m['value'] as String,
            ))
        .toList();

    return DashboardViewData(
      viewState: viewState,
      metrics: metrics,
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无看板数据',
        ViewState.error => '加载失败',
        ViewState.forbidden => '无权限查看该数据',
        ViewState.offline => '离线数据：展示最近同步时间',
        ViewState.normal => null,
      },
    );
  }
}
