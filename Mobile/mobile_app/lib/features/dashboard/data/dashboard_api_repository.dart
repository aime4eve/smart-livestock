import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/models/core_models.dart';
import 'package:smart_livestock_demo/features/dashboard/domain/dashboard_repository.dart';

class DashboardApiRepository implements DashboardRepository {
  const DashboardApiRepository();

  @override
  Future<DashboardViewData> load() async {
    final data = await ApiClient.instance.farmGet('/dashboard/summary');

    final metricsRaw = data['metrics'];
    if (metricsRaw is List) {
      final metrics = metricsRaw.whereType<Map<String, dynamic>>().map((m) {
        final key = m['key'];
        return DashboardMetric(
          widgetKey: 'dashboard-metric-${key is int ? key : key ?? ''}',
          title: m['title'] as String? ?? '',
          value: m['value']?.toString() ?? '',
        );
      }).toList();
      return DashboardViewData(metrics: metrics);
    }

    // Flat Spring Boot format
    final entries = <String, String>{
      'livestockCount': '牲畜总数',
      'onlineDeviceCount': '在线设备',
      'activeAlertCount': '活跃告警',
      'fenceCount': '围栏数',
    };
    final metrics = <DashboardMetric>[];
    for (final e in entries.entries) {
      final raw = data[e.key];
      if (raw != null) {
        metrics.add(DashboardMetric(
          widgetKey: 'dashboard-metric-${e.key}',
          title: e.value,
          value: raw.toString(),
        ));
      }
    }
    final health = data['healthSummary'] as Map<String, dynamic>?;
    if (health != null) {
      for (final (key, label) in [('healthy', '健康'), ('warning', '关注'), ('critical', '异常')]) {
        final raw = health[key];
        if (raw != null) {
          metrics.add(DashboardMetric(
            widgetKey: 'dashboard-metric-health-$key',
            title: label,
            value: raw.toString(),
          ));
        }
      }
    }
    return DashboardViewData(metrics: metrics);
  }
}
