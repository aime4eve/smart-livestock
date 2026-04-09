import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/fence/data/mock_fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_repository.dart';

class LiveFenceRepository implements FenceRepository {
  const LiveFenceRepository();

  static const MockFenceRepository _fallback = MockFenceRepository();

  @override
  FenceViewData load({
    required ViewState viewState,
    required DemoRole role,
    required bool editSaved,
  }) {
    final cache = ApiCache.instance;
    if (!cache.initialized) {
      return _fallback.load(
        viewState: viewState,
        role: role,
        editSaved: editSaved,
      );
    }

    final first = cache.fences.isNotEmpty ? cache.fences.first : null;
    final name = first?['name'] as String? ?? '暂无围栏';
    final alarmOn = first?['alarmEnabled'] as bool? ?? false;
    final subtitle = '生效中 · 越界告警${alarmOn ? "开" : "关"}';

    return FenceViewData(
      viewState: viewState,
      role: role,
      fenceTitle: name,
      fenceSubtitle: subtitle,
      editSaved: editSaved,
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无围栏',
        ViewState.error => '围栏加载失败',
        ViewState.forbidden => '无权限管理围栏',
        ViewState.offline => '离线：展示本地缓存围栏列表',
        ViewState.normal => null,
      },
    );
  }
}
