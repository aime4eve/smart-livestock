import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/alerts/data/mock_alerts_repository.dart';
import 'package:smart_livestock_demo/features/alerts/domain/alerts_repository.dart';

class LiveAlertsRepository implements AlertsRepository {
  const LiveAlertsRepository();

  static const MockAlertsRepository _fallback = MockAlertsRepository();

  @override
  AlertsViewData load({
    required ViewState viewState,
    required DemoRole role,
    required AlertStage stage,
  }) {
    final cache = ApiCache.instance;
    if (!cache.initialized) {
      return _fallback.load(viewState: viewState, role: role, stage: stage);
    }

    // Filter alerts by stage
    final filtered = cache.alerts
        .where((a) => a['stage'] == stage.name)
        .toList();
    final first = filtered.isNotEmpty ? filtered.first : null;

    // Format timestamp for subtitle
    String subtitle = '';
    if (first != null) {
      final ts = first['occurredAt'] as String;
      // "2026-03-26T10:12:00+08:00" → "2026-03-26 10:12"
      subtitle = ts
          .replaceFirst(RegExp(r'T'), ' ')
          .substring(0, 16);
    }

    return AlertsViewData(
      viewState: viewState,
      role: role,
      stage: stage,
      title: first?['title'] as String? ?? '暂无告警',
      subtitle: subtitle,
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无告警',
        ViewState.error => '告警列表加载失败',
        ViewState.forbidden => '无权限处理告警',
        ViewState.offline => '离线：展示已缓存告警',
        ViewState.normal => null,
      },
    );
  }
}
