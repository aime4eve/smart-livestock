import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/mine/data/mock_mine_repository.dart';
import 'package:smart_livestock_demo/features/mine/domain/mine_repository.dart';

class LiveMineRepository implements MineRepository {
  const LiveMineRepository();

  static const MockMineRepository _fallback = MockMineRepository();

  @override
  MineViewData load(ViewState viewState) {
    final cache = ApiCache.instance;
    if (!cache.initialized) return _fallback.load(viewState);

    final profile = cache.profile;
    final name = profile?['name'] as String? ?? '未知用户';
    final tenant = profile?['tenantName'] as String? ?? '未知牧场';
    final normalText = '我的页：$name · $tenant';

    return MineViewData(
      viewState: viewState,
      normalText: normalText,
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
