import 'package:smart_livestock_demo/core/data/twin_seed.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/epidemic/domain/epidemic_repository.dart';

class MockEpidemicRepository implements EpidemicRepository {
  const MockEpidemicRepository();

  @override
  EpidemicViewData load([ViewState desiredState = ViewState.normal]) {
    return EpidemicViewData(
      viewState: desiredState,
      metrics: desiredState == ViewState.normal ? TwinSeed.epidemicMetrics : null,
      contacts:
          desiredState == ViewState.normal ? TwinSeed.epidemicContacts : const [],
      message: switch (desiredState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无疫病防控数据',
        ViewState.error => '疫病数据加载失败（演示）',
        ViewState.forbidden => '无权限查看疫病数据（演示）',
        ViewState.offline => '离线：展示已缓存群体指标（演示）',
        ViewState.normal => null,
      },
    );
  }
}
