import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/twin_overview/domain/twin_overview_repository.dart';

class LiveTwinOverviewRepository implements TwinOverviewRepository {
  const LiveTwinOverviewRepository();

  @override
  TwinOverviewViewData load([ViewState desiredState = ViewState.normal]) {
    return TwinOverviewViewData(
      viewState: desiredState,
      stats: TwinOverviewStats(
        totalLivestock: 0,
        healthyRate: 0,
        alertCount: 0,
        criticalCount: 0,
        deviceOnlineRate: 0,
        livestockCaption: '',
        alertCaption: '',
        healthCaption: '',
        deviceCaption: '',
        healthTrend: '',
        livestockTrend: '',
      ),
      sceneSummary: TwinSceneSummary(
        fever: SceneSummaryFever(abnormalCount: 0, criticalCount: 0),
        digestive: SceneSummaryDigestive(abnormalCount: 0, watchCount: 0),
        estrus: SceneSummaryEstrus(highScoreCount: 0, breedingAdvice: false),
        epidemic: SceneSummaryEpidemic(status: 'normal', abnormalRate: 0.0),
      ),
      pendingTasks: const [],
      pastureHeadline: null,
      pastureDetail: null,
      message: switch (desiredState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无孪生数据',
        ViewState.error => '孪生数据加载失败',
        ViewState.forbidden => '当前角色仅可查看授权范围内的孪生信息',
        ViewState.offline => '离线数据：展示最近一次同步时间',
        ViewState.normal => '功能开发中，敬请期待',
      },
    );
  }
}
