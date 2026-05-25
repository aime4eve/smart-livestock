import 'package:smart_livestock_demo/core/models/core_models.dart';

enum AlertStage {
  pending,
  acknowledged,
  handled,
  archived,
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
    required this.earTag,
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
  final String earTag;
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

  Future<void> acknowledge(String alertId);

  Future<void> handle(String alertId);

  Future<void> archive(String alertId);

  Future<void> batchHandle(List<String> alertIds);
}
