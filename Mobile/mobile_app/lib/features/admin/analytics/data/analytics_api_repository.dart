import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/admin/analytics/domain/analytics_models.dart';

class AnalyticsApiRepository {
  const AnalyticsApiRepository();

  Future<UsageOverview> getOverview(DateTime from, DateTime to) async {
    final data = await ApiClient.instance.get(
      '/admin/analytics/usage/overview?from=${_fmt(from)}&to=${_fmt(to)}',
    );
    return UsageOverview(
      totalCalls: (data['totalCalls'] as num?)?.toInt() ?? 0,
      successCalls: (data['successCalls'] as num?)?.toInt() ?? 0,
      errorCalls: (data['errorCalls'] as num?)?.toInt() ?? 0,
      avgResponseMs: (data['avgResponseMs'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Future<List<UsageTrendPoint>> getTrend(DateTime from, DateTime to) async {
    final data = await ApiClient.instance.get(
      '/admin/analytics/usage/trend?from=${_fmt(from)}&to=${_fmt(to)}',
    );
    final items = (data["value"] ?? data["items"] ?? []) as List;
    return items.whereType<Map<String, dynamic>>().map((m) => UsageTrendPoint(
      date: (m['date'] ?? '').toString(),
      totalCalls: (m['totalCalls'] as num?)?.toInt() ?? 0,
      successCalls: (m['successCalls'] as num?)?.toInt() ?? 0,
      errorCalls: (m['errorCalls'] as num?)?.toInt() ?? 0,
      avgResponseMs: (m['avgResponseMs'] as num?)?.toInt() ?? 0,
    )).toList();
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
