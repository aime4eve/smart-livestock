import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/mine/domain/mine_repository.dart';

class MockMineRepository implements MineRepository {
  const MockMineRepository();

  @override
  MineViewData load(ViewState viewState) {
    return MineViewData(
      viewState: viewState,
      normalText: '我的页：账户信息与设置入口',
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '我的页：暂无个人数据',
        ViewState.error => '我的页：加载失败，请重试',
        ViewState.forbidden => '我的页：无权限查看',
        ViewState.offline => '我的页：当前离线，显示缓存信息',
        ViewState.normal => null,
      },
    );
  }
}
