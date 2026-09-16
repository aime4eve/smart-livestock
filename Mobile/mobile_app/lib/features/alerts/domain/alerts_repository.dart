import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alert_summary.dart';

enum AlertStage {
  active,
  dismissed,
  autoResolved,
}

class AlertsListData {
  const AlertsListData({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<AlertItem> items;
  final int total;
  final int page;
  final int pageSize;
}

class AlertDetail {
  const AlertDetail({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priority,
    required this.type,
    required this.stage,
    required this.livestockCode,
    this.livestockId,
    this.occurredAt,
    this.resolvedAt,
    this.description,
    this.severity = 'WARNING',
    this.source = 'RULE',
    this.fenceName,
    this.resolvedType,
    this.read = false,
    this.fenceId,
    this.deviceCode,
  });

  final String id;
  final String title;
  final String subtitle;
  final String priority;
  final String type;
  final String stage;
  final String livestockCode;
  final String? livestockId;
  final String? occurredAt;
  final String? resolvedAt;
  final String? description;
  final String severity;
  final String source;
  final String? fenceName;
  final String? resolvedType;
  final bool read;
  final String? fenceId;

  /// Device serial for device-originated alerts.
  final String? deviceCode;
}

/// Metadata entry for the detail timeline.
class AlertTimelineEntry {
  const AlertTimelineEntry({
    required this.label,
    required this.time,
    this.done = false,
  });
  final String label;
  final String? time;
  final bool done;
}

abstract class AlertsRepository {
  Future<AlertsListData> loadAlerts({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? severity,
    Set<String>? types,
    String? fenceId,
    bool unreadOnly = false,
  });

  /// Farm-global counters (active/unread/severity/type-group), independent of
  /// any list filter or pagination window. Non-empty [types] scopes them to a
  /// category view.
  Future<RanchAlertSummary> loadSummary({Set<String>? types});

  Future<AlertDetail> loadDetail(String alertId);

  Future<void> markRead(String alertId);

  Future<void> dismiss(String alertId);

  Future<void> batchRead(List<String> alertIds);

  Future<void> batchDismiss(List<String> alertIds);
}
