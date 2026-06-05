class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.eventId,
    required this.eventType,
    this.tenantId,
    this.userId,
    required this.action,
    this.details,
    required this.occurredAt,
    this.createdAt,
  });

  final int id;
  final String eventId;
  final String eventType;
  final String? tenantId;
  final String? userId;
  final String action;
  final Map<String, dynamic>? details;
  final String occurredAt;
  final String? createdAt;
}

class AuditLogListResult {
  const AuditLogListResult({
    required this.items,
    this.page = 1,
    this.pageSize = 20,
    this.total = 0,
  });

  final List<AuditLogEntry> items;
  final int page;
  final int pageSize;
  final int total;
  bool get isEmpty => items.isEmpty;
}
