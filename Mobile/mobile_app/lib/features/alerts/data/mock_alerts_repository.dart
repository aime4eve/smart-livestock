import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/alerts/domain/alerts_repository.dart';

class MockAlertsRepository implements AlertsRepository {
  const MockAlertsRepository();

  @override
  AlertsViewData load({
    required ViewState viewState,
    required DemoRole role,
    required AlertStage stage,
  }) {
    return AlertsViewData(
      viewState: viewState,
      role: role,
      stage: stage,
      title: '越界 · 耳标-001',
      subtitle: '2026-03-26 10:12',
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无告警',
        ViewState.error => '告警列表加载失败（演示）',
        ViewState.forbidden => '无权限处理告警（演示）',
        ViewState.offline => '离线：展示已缓存告警（演示）',
        ViewState.normal => null,
      },
    );
  }
}
