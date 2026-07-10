import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/admin/audit_log/domain/audit_log_models.dart';

class AuditLogApiRepository {
  const AuditLogApiRepository();

  Future<AuditLogListResult> load({
    int page = 1,
    int pageSize = 20,
    String? tenantId,
    String? userId,
    String? action,
    String? startTime,
    String? endTime,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
    };
    if (tenantId != null) query['tenantId'] = tenantId;
    if (userId != null) query['userId'] = userId;
    if (action != null && action.isNotEmpty) query['action'] = action;
    if (startTime != null) query['startTime'] = startTime;
    if (endTime != null) query['endTime'] = endTime;
    final qs = query.entries.map((e) => '${e.key}=${e.value}').join('&');
    final data = await ApiClient.instance.get('/admin/audit-logs?$qs');
    final items = (data['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(_parseEntry)
        .toList();
    return AuditLogListResult(
      items: items,
      page: data['page'] as int? ?? page,
      pageSize: data['pageSize'] as int? ?? pageSize,
      total: data['total'] as int? ?? 0,
    );
  }

  AuditLogEntry _parseEntry(Map<String, dynamic> m) {
    return AuditLogEntry(
      id: m['id'] as int,
      eventId: (m['eventId'] ?? '').toString(),
      eventType: (m['eventType'] ?? '').toString(),
      tenantId: m['tenantId']?.toString(),
      userId: m['userId']?.toString(),
      action: (m['action'] ?? '').toString(),
      details: m['details'] as Map<String, dynamic>?,
      occurredAt: (m['occurredAt'] ?? '').toString(),
      createdAt: m['createdAt']?.toString(),
    );
  }
}
