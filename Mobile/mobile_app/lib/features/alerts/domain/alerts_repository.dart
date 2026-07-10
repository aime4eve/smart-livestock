import 'package:hkt_livestock_agentic/core/models/core_models.dart';

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
    this.description,
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
  final String? description;
}

abstract class AlertsRepository {
  Future<AlertsListData> loadAlerts({
    int page = 1,
    int pageSize = 20,
    String? status,
  });

  Future<AlertDetail> loadDetail(String alertId);

  Future<void> markRead(String alertId);

  Future<void> dismiss(String alertId);

  Future<void> batchRead(List<String> alertIds);
}
