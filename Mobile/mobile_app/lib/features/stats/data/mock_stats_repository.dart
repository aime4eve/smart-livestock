import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/stats/domain/stats_repository.dart';

class MockStatsRepository implements StatsRepository {
  const MockStatsRepository();

  @override
  StatsViewData load(
      {required ViewState viewState, required StatsTimeRange timeRange}) {
    return StatsViewData(
      viewState: viewState,
      timeRange: timeRange,
      healthSummary:
          viewState == ViewState.normal ? DemoSeed.healthSummary : null,
      alertSummary:
          viewState == ViewState.normal ? DemoSeed.alertSummary : null,
      deviceSummary:
          viewState == ViewState.normal ? DemoSeed.deviceSummary : null,
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无统计数据',
        ViewState.error => '统计数据加载失败（演示）',
        ViewState.forbidden => '无权限查看统计（演示）',
        ViewState.offline => '离线统计快照（演示）',
        ViewState.normal => null,
      },
    );
  }
}
