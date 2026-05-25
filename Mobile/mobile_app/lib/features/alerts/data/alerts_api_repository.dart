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
    final message = m['message'] as String? ?? '';
    final severity = (m['severity'] as String? ?? 'WARNING').toUpperCase();
    final priority = switch (severity) {
      'CRITICAL' => 'P0',
      'WARNING' => 'P1',
      _ => 'P2',
    };
    final type = m['type'] as String? ?? 'unknown';
    final stageStr = (m['status'] as String? ?? 'PENDING').toLowerCase();
    final rawLivestockId = m['livestockId'];
    final livestockId = rawLivestockId is int
        ? rawLivestockId.toString()
        : (rawLivestockId as String?);
    return AlertItem(
      id: id,
      title: message,
      subtitle: '',
      priority: priority,
      type: type,
      stage: stageStr,
      earTag: livestockId ?? '-',
      livestockId: livestockId,
    );
  }

  static AlertDetail _alertDetailFromMap(Map<String, dynamic> m) {
    final item = _alertItemFromMap(m);
    return AlertDetail(
      id: item.id,
      title: item.title,
      subtitle: item.subtitle,
      priority: item.priority,
      type: item.type,
      stage: item.stage,
      earTag: item.earTag,
      livestockId: item.livestockId,
      occurredAt: m['handledAt'] as String?,
      description: m['message'] as String?,
    );
  }
}
