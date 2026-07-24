import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alerts_repository.dart';

class AlertsApiRepository implements AlertsRepository {
  const AlertsApiRepository();

  @override
  Future<AlertsListData> loadAlerts({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? severity,
  }) async {
    var path = '/alerts?page=$page&pageSize=$pageSize';
    if (status != null) path += '&status=$status';
    if (severity != null) path += '&severity=$severity';
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
  Future<void> markRead(String alertId) async {
    await ApiClient.instance.farmPost('/alerts/$alertId/read');
  }

  @override
  Future<void> dismiss(String alertId) async {
    await ApiClient.instance.farmPost('/alerts/$alertId/dismiss');
  }

  @override
  Future<void> batchRead(List<String> alertIds) async {
    await ApiClient.instance
       .farmPost('/alerts/batch-read', body: {'alertIds': alertIds});
  }

  @override
  Future<void> batchDismiss(List<String> alertIds) async {
    // Backend has no /alerts/batch-dismiss; reuse /alerts/batch-handle
    // (deprecated but active, internally loops dismiss, OWNER/B2B_ADMIN only).
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
    final readVal = m['read'];
    final isRead = readVal is bool ? readVal : false;
    final type = m['type'] as String? ?? 'unknown';
    final stageStr = (m['status'] as String? ?? 'ACTIVE').toLowerCase();
    final stage = switch (stageStr) {
      'active' => AlertStage.active,
      'dismissed' => AlertStage.dismissed,
      'auto_resolved' => AlertStage.autoResolved,
      // Legacy compatibility
      'pending' => AlertStage.active,
      'acknowledged' => AlertStage.active,
      'handled' => AlertStage.dismissed,
      'archived' => AlertStage.autoResolved,
      _ => AlertStage.active,
    };
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
      stage: stage.name,
      livestockCode: livestockId ?? '-',
      livestockId: livestockId,
      source: (m['source'] as String?) ?? 'RULE',
      severity: severity,
      read: isRead,
      occurredAt: _extractTimestamp(m, 'occurredAt', 'resolvedAt'),
      resolvedAt: m['resolvedAt'] as String?,
     fenceName: m['fenceName'] as String?,
     resolvedType: m['resolvedType'] as String?,
      fenceId: m['fenceId']?.toString(),
   );
 }

 static AlertDetail _alertDetailFromMap(Map<String, dynamic> m) {
   final item = _alertItemFromMap(m);
   final rawFenceId = m['fenceId'];
    final fenceId = rawFenceId is int
        ? rawFenceId.toString()
        : (rawFenceId as String?);
    return AlertDetail(
      id: item.id,
      title: item.title,
      subtitle: item.subtitle,
      priority: item.priority,
      type: item.type,
      stage: item.stage,
      livestockCode: item.livestockCode,
      livestockId: item.livestockId,
      occurredAt: item.occurredAt,
      resolvedAt: item.resolvedAt,
      description: m['message'] as String?,
      severity: item.severity,
      source: item.source,
      fenceName: item.fenceName,
      resolvedType: item.resolvedType,
      read: item.read,
      fenceId: fenceId,
    );
  }

  /// Tries multiple possible timestamp field names from the DTO.
  static String? _extractTimestamp(
      Map<String, dynamic> m, String primary, String fallback) {
    final v = m[primary];
    if (v is String && v.isNotEmpty) return v;
    final f = m[fallback];
    if (f is String && f.isNotEmpty) return f;
    return null;
  }

  // Test-only accessors for private parsing methods
  static AlertItem alertItemFromMapForTest(Map<String, dynamic> m) =>
      _alertItemFromMap(m);
  static AlertDetail alertDetailFromMapForTest(Map<String, dynamic> m) =>
      _alertDetailFromMap(m);
}
