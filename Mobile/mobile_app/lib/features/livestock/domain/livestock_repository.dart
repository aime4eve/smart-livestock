import 'package:hkt_livestock_agentic/core/models/core_models.dart';

class LivestockSummary {
  const LivestockSummary({
    required this.id,
    required this.livestockCode,
    required this.breed,
    required this.health,
    required this.fenceId,
    this.lat,
    this.lng,
    this.gender,
    this.birthDate,
    this.weight,
    this.deviceCodes = const [],
  });

  final String id;
  final String livestockCode;
  final Breed breed;
  final LivestockHealth health;
  final String fenceId;
  final double? lat;
  final double? lng;
  final String? gender;
  final DateTime? birthDate;
  final double? weight;
  final List<String> deviceCodes;
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
    String? keyword,
  });

  Future<LivestockDetail> loadDetail(String id);

  Future<LivestockDetail> create(Map<String, dynamic> body);

  Future<LivestockDetail> update(String id, Map<String, dynamic> body);

  Future<void> delete(String id);
}
