import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/estrus/domain/estrus_repository.dart';

class LiveEstrusRepository implements EstrusRepository {
  const LiveEstrusRepository();

  @override
  EstrusViewData load([ViewState desiredState = ViewState.normal]) {
    return EstrusViewData(
      viewState: desiredState,
      items: const [],
      message: switch (desiredState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无发情识别数据',
        ViewState.error => '发情数据加载失败',
        ViewState.forbidden => '无权限查看发情数据',
        ViewState.offline => '离线：展示已缓存评分',
        ViewState.normal => '功能开发中，敬请期待',
      },
    );
  }

  @override
  EstrusScore? loadDetail(String livestockId) {
    return null;
  }
}
