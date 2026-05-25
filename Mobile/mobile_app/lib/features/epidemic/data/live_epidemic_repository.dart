import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/epidemic/domain/epidemic_repository.dart';

class LiveEpidemicRepository implements EpidemicRepository {
  const LiveEpidemicRepository();

  @override
  EpidemicViewData load([ViewState desiredState = ViewState.normal]) {
    return EpidemicViewData(
      viewState: desiredState,
      metrics: null,
      contacts: const [],
      message: switch (desiredState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无疫病防控数据',
        ViewState.error => '疫病数据加载失败',
        ViewState.forbidden => '无权限查看疫病数据',
        ViewState.offline => '离线：展示已缓存群体指标',
        ViewState.normal => '功能开发中，敬请期待',
      },
    );
  }
}
