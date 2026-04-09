import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/alerts/domain/alerts_repository.dart';

class MockAlertsRepository implements AlertsRepository {
  const MockAlertsRepository();

  static String _stageString(AlertStage stage) => switch (stage) {
        AlertStage.pending => 'pending',
        AlertStage.acknowledged => 'acknowledged',
        AlertStage.handled => 'handled',
        AlertStage.archived => 'archived',
      };

  @override
  AlertsViewData load({
    required ViewState viewState,
    required DemoRole role,
    required AlertStage stage,
  }) {
    final stageStr = _stageString(stage);
    final filtered = DemoSeed.alerts
        .where((a) => a.stage == stageStr)
        .toList();
    final first = filtered.isNotEmpty ? filtered.first : null;

    return AlertsViewData(
      viewState: viewState,
      role: role,
      stage: stage,
      title: first?.title ?? '暂无告警',
      subtitle: first?.subtitle ?? '',
      items: viewState == ViewState.normal ? filtered : const [],
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
