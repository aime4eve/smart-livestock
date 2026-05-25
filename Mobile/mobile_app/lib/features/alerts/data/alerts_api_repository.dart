import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/models/core_models.dart';
import 'package:smart_livestock_demo/features/alerts/domain/alerts_repository.dart';

class AlertsApiRepository implements AlertsRepository {
  const AlertsApiRepository();

  @override
  Future<AlertsListData> loadAlerts({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    var path = '/alerts?page=$page&pageSize=$pageSize';
    if (status != null) path += '&status=$status';
    final data = await ApiClient.instance.farmGet(path);
    final itemsRaw = data['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map<String, dynamic>>()
            .map(_alertItemFromMap)
            .toList()
        : <AlertItem>[];
    return AlertsListData(
      items: items,
      total: data['total'] as int? ?? items.length,
      page: data['page'] as int? ?? page,
      pageSize: data['pageSize'] as int? ?? pageSize,
    );
  }

  @override
  Future<AlertDetail> loadDetail(String alertId) async {
    final data = await ApiClient.instance.farmGet('/alerts/$alertId');
    return _alertDetailFromMap(data);
  }

  @override
  Future<void> acknowledge(String alertId) async {
    await ApiClient.instance.farmPost('/alerts/$alertId/acknowledge');
  }

  @override
  Future<void> handle(String alertId) async {
    await ApiClient.instance.farmPost('/alerts/$alertId/handle');
  }

  @override
  Future<void> archive(String alertId) async {
    await ApiClient.instance.farmPost('/alerts/$alertId/archive');
  }

  @override
  Future<void> batchHandle(List<String> alertIds) async {
    await ApiClient.instance
        .farmPost('/alerts/batch-handle', body: {'alertIds': alertIds});
  }

  static AlertItem _alertItemFromMap(Map<String, dynamic> m) {
    final rawId = m['id'];
    final id = rawId is int ? rawId.toString() : (rawId as String? ?? '');
    final title = m['title'] as String? ?? '';
    final ts = m['occurredAt'] as String? ?? '';
    var subtitle = '';
    if (ts.length >= 16) {
      subtitle = ts.replaceFirst(RegExp(r'T'), ' ').substring(0, 16);
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
    final livestockCode = m['livestockCode'] as String? ?? earTag;
    return AlertItem(
      id: id,
      title: title,
      subtitle: subtitle,
      priority: priority,
      type: type,
      stage: stageStr,
      earTag: livestockCode,
      livestockId: m['livestockId'] as String?,
    );
  }

  static AlertDetail _alertDetailFromMap(Map<String, dynamic> m) {
    final rawId = m['id'];
    final id = rawId is int ? rawId.toString() : (rawId as String? ?? '');
    final title = m['title'] as String? ?? '';
    final ts = m['occurredAt'] as String? ?? '';
    var subtitle = '';
    if (ts.length >= 16) {
      subtitle = ts.replaceFirst(RegExp(r'T'), ' ').substring(0, 16);
    }
    final level = m['level'] as String? ?? 'warning';
    final priority = switch (level) {
      'critical' => 'P0',
      'warning' => 'P1',
      _ => 'P2',
    };
    final earTagFromSl =
        RegExp(r'SL-2024-\d{3}').firstMatch(title)?.group(0) ?? '';
    final earTag = earTagFromSl.isNotEmpty
        ? earTagFromSl
        : (RegExp(r'耳标-\d+').firstMatch(title)?.group(0) ?? '-');
    final livestockCode = m['livestockCode'] as String? ?? earTag;
    return AlertDetail(
      id: id,
      title: title,
      subtitle: subtitle,
      priority: priority,
      type: m['type'] as String? ?? 'unknown',
      stage: m['stage'] as String? ?? 'pending',
      earTag: livestockCode,
      livestockId: m['livestockId'] as String?,
      occurredAt: ts,
      description: m['description'] as String?,
    );
  }
}
