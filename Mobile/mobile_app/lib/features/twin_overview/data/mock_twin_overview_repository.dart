import 'package:smart_livestock_demo/core/data/twin_seed.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/twin_overview/domain/twin_overview_repository.dart';

class MockTwinOverviewRepository implements TwinOverviewRepository {
  const MockTwinOverviewRepository();

  @override
  TwinOverviewViewData load([ViewState desiredState = ViewState.normal]) {
    return TwinOverviewViewData(
      viewState: desiredState,
      stats: desiredState == ViewState.normal ? TwinSeed.overviewStats : null,
      sceneSummary:
          desiredState == ViewState.normal ? TwinSeed.sceneSummary : null,
      pendingTasks:
          desiredState == ViewState.normal ? TwinSeed.pendingTasks : const [],
      message: switch (desiredState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无孪生数据',
        ViewState.error => '孪生数据加载失败（演示）',
        ViewState.forbidden => '当前角色仅可查看授权范围内的孪生信息（演示）',
        ViewState.offline => '离线数据（演示）：展示最近一次同步时间',
        ViewState.normal => null,
      },
    );
  }
}
