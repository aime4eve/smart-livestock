import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/livestock/domain/livestock_repository.dart';

class MockLivestockRepository implements LivestockRepository {
  const MockLivestockRepository();

  @override
  LivestockViewData load(
      {required ViewState viewState, required String earTag}) {
    final detail = DemoSeed.getLivestockDetail(earTag);
    return LivestockViewData(
      viewState: viewState,
      detail: viewState == ViewState.normal ? detail : null,
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '未找到该牲畜',
        ViewState.error => '加载失败（演示）',
        ViewState.forbidden => '无权限查看该牲畜（演示）',
        ViewState.offline => '离线数据（演示）',
        ViewState.normal => null,
      },
    );
  }
}
