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

/// Result of `POST /alerts/{alertId}/estrus-feedback` (NIX-286 T2 contract:
/// FeedbackResult{alertId, verdict, physiologyEventId, labelId, idempotent}).
class AlertFeedbackResult {
  const AlertFeedbackResult({
    required this.alertId,
    required this.verdict,
    this.physiologyEventId,
    this.labelId,
    this.idempotent = false,
  });

  final String alertId;

  /// Server verdict: `CONFIRMED` (确认发情) or `REJECTED` (不是发情).
  final String verdict;

  /// Physiology event linked on confirm; null on reject. Kept as a string so
  /// the frontend never cares whether the backend serializes an int or UUID.
  final String? physiologyEventId;
  final String? labelId;

  /// True when the same verdict was already recorded — the UI shows the
  /// "already submitted" copy instead of the success copy.
  final bool idempotent;

  factory AlertFeedbackResult.fromJson(Map<String, dynamic> json) {
    return AlertFeedbackResult(
      alertId: json['alertId']?.toString() ?? '',
      verdict: json['verdict'] as String? ?? '',
      physiologyEventId: json['physiologyEventId']?.toString(),
      labelId: json['labelId']?.toString(),
      idempotent: json['idempotent'] as bool? ?? false,
    );
  }
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

  /// NIX-286: submit estrus confirm/reject feedback on an alert
  /// (`POST /alerts/{alertId}/estrus-feedback`, body `{"confirmed": bool}`).
  /// Throws [ApiException] subclasses on 400/403/404 so the caller can surface
  /// the server-side i18n message.
  Future<AlertFeedbackResult> submitEstrusFeedback(
    String farmId,
    String alertId, {
    required bool confirmed,
  });
}
