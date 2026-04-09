import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_repository.dart';

class MockFenceRepository implements FenceRepository {
  const MockFenceRepository();

  @override
  FenceViewData load({
    required ViewState viewState,
    required DemoRole role,
    required bool editSaved,
  }) {
    return FenceViewData(
      viewState: viewState,
      role: role,
      fenceTitle: '北区围栏',
      fenceSubtitle: '生效中 · 越界告警开',
      editSaved: editSaved,
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无围栏',
        ViewState.error => '围栏加载失败（演示）',
        ViewState.forbidden => '无权限管理围栏（演示）',
        ViewState.offline => '离线：展示本地缓存围栏列表（演示）',
        ViewState.normal => null,
      },
    );
  }
}
