import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/alerts/domain/alerts_repository.dart';

class LiveAlertsRepository implements AlertsRepository {
  const LiveAlertsRepository();

  static AlertItem _alertFromMap(Map<String, dynamic> m) {
    final id = m['id'] as String;
    final title = m['title'] as String;
    final ts = m['occurredAt'] as String? ?? '';
    var subtitle = '';
    if (ts.length >= 16) {
      subtitle =
          ts.replaceFirst(RegExp(r'T'), ' ').substring(0, 16);
    }
    final level = m['level'] as String? ?? 'warning';
    final priority = switch (level) {
      'critical' => 'P0',
      'warning' => 'P1',
      _ => 'P2',
    };
    final type = m['type'] as String? ?? 'unknown';
    final stageStr = m['stage'] as String? ?? 'pending';
    final earTagFromSl =
        RegExp(r'SL-2024-\d{3}').firstMatch(title)?.group(0) ?? '';
    final earTag = earTagFromSl.isNotEmpty
        ? earTagFromSl
        : (RegExp(r'耳标-\d+').firstMatch(title)?.group(0) ?? '-');
    return AlertItem(
      id: id,
      title: title,
      subtitle: subtitle,
      priority: priority,
      type: type,
      stage: stageStr,
      earTag: earTag,
    );
  }

  @override
  AlertsViewData load({
    required ViewState viewState,
    required DemoRole role,
    required AlertStage stage,
  }) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.lastLiveSource != 'api') {
      return AlertsViewData(
        viewState: ViewState.error,
        role: role,
        stage: stage,
        title: '告警列表加载失败',
        subtitle: '',
        message: 'Live API 未连接',
      );
    }

    final filtered = cache.alerts
        .where((a) => a['stage'] == stage.name)
        .toList();
    final first = filtered.isNotEmpty ? filtered.first : null;

    String subtitle = '';
    if (first != null) {
      final ts = first['occurredAt'] as String;
      subtitle = ts
          .replaceFirst(RegExp(r'T'), ' ')
          .substring(0, 16);
    }

    final items = viewState == ViewState.normal
        ? filtered.map(_alertFromMap).toList()
        : const <AlertItem>[];

    return AlertsViewData(
      viewState: viewState,
      role: role,
      stage: stage,
      title: first?['title'] as String? ?? '暂无告警',
      subtitle: subtitle,
      items: items,
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
