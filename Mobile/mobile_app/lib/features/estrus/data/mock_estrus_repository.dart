import 'package:smart_livestock_demo/core/data/twin_seed.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/estrus/domain/estrus_repository.dart';

class MockEstrusRepository implements EstrusRepository {
  const MockEstrusRepository();

  @override
  EstrusViewData load([ViewState desiredState = ViewState.normal]) {
    return EstrusViewData(
      viewState: desiredState,
      items: desiredState == ViewState.normal ? TwinSeed.estrusItems : const [],
      message: switch (desiredState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无发情识别数据',
        ViewState.error => '发情数据加载失败（演示）',
        ViewState.forbidden => '无权限查看发情数据（演示）',
        ViewState.offline => '离线：展示已缓存评分（演示）',
        ViewState.normal => null,
      },
    );
  }

  @override
  EstrusScore? loadDetail(String livestockId) {
    for (final e in TwinSeed.estrusItems) {
      if (e.livestockId == livestockId) return e;
    }
    return null;
  }
}
