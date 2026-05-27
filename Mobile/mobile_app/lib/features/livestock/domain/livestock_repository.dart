import 'package:smart_livestock_demo/core/models/core_models.dart';

class LivestockSummary {
  const LivestockSummary({
    required this.id,
    required this.earTag,
    required this.breed,
    required this.health,
    required this.fenceId,
    this.lat,
    this.lng,
  });

  final String id;
  final String earTag;
  final String breed;
  final LivestockHealth health;
  final String fenceId;
  final double? lat;
  final double? lng;
}

class LivestockListData {
  const LivestockListData({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<LivestockSummary> items;
  final int total;
  final int page;
  final int pageSize;
}

abstract class LivestockRepository {
  Future<LivestockListData> loadAll({
    int page = 1,
    int pageSize = 20,
    String? status,
  });

  Future<LivestockDetail> loadDetail(String id);

  Future<LivestockDetail> create(Map<String, dynamic> body);

  Future<LivestockDetail> update(String id, Map<String, dynamic> body);

  Future<void> delete(String id);
}
