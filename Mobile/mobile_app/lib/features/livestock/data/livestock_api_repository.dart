import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/models/core_models.dart';
import 'package:smart_livestock_demo/features/livestock/domain/livestock_repository.dart';

class LivestockApiRepository implements LivestockRepository {
  const LivestockApiRepository();

  @override
  Future<LivestockListData> loadAll({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    var path = '/livestock?page=$page&pageSize=$pageSize';
    if (status != null) path += '&status=$status';
    final data = await ApiClient.instance.farmGet(path);
    final itemsRaw = data['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map<String, dynamic>>()
            .map(_livestockSummaryFromMap)
            .toList()
        : <LivestockSummary>[];
    return LivestockListData(
      items: items,
      total: data['total'] as int? ?? items.length,
      page: data['page'] as int? ?? page,
      pageSize: data['pageSize'] as int? ?? pageSize,
    );
  }

  @override
  Future<LivestockDetail> loadDetail(String id) async {
    final data = await ApiClient.instance.farmGet('/livestock/$id');
    return _livestockDetailFromMap(data);
  }

  @override
  Future<LivestockDetail> create(Map<String, dynamic> body) async {
    final data =
        await ApiClient.instance.farmPost('/livestock', body: body);
    return _livestockDetailFromMap(data);
  }

  @override
  Future<LivestockDetail> update(String id, Map<String, dynamic> body) async {
    final data =
        await ApiClient.instance.farmPut('/livestock/$id', body: body);
    return _livestockDetailFromMap(data);
  }

  @override
  Future<void> delete(String id) async {
    await ApiClient.instance.farmDelete('/livestock/$id');
  }

  static LivestockSummary _livestockSummaryFromMap(Map<String, dynamic> m) {
    final rawId = m['id'];
    final id = rawId is int ? rawId.toString() : (rawId as String? ?? '');
    final healthStr =
        (m['healthStatus'] as String?)?.toUpperCase() ?? 'HEALTHY';
    final health = healthStr == 'WARNING'
        ? LivestockHealth.watch
        : healthStr == 'CRITICAL'
            ? LivestockHealth.abnormal
            : LivestockHealth.healthy;
    return LivestockSummary(
      id: id,
      earTag: (m['livestockCode'] ?? m['earTag'] ?? '') as String,
      breed: (m['breed'] ?? '未知品种') as String,
      health: health,
      fenceId: (m['fenceId'] ?? '').toString(),
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
    );
  }

  static LivestockDetail _livestockDetailFromMap(Map<String, dynamic> m) {
    final rawId = m['id'];
    final id = rawId is int ? rawId.toString() : (rawId as String? ?? '');
    final healthStr =
        (m['healthStatus'] as String?)?.toUpperCase() ?? 'HEALTHY';
    final health = healthStr == 'WARNING'
        ? LivestockHealth.watch
        : healthStr == 'CRITICAL'
            ? LivestockHealth.abnormal
            : LivestockHealth.healthy;
    return LivestockDetail(
      earTag: (m['livestockCode'] ?? m['earTag'] ?? '') as String,
      livestockId: id,
      breed: (m['breed'] ?? '未知品种') as String,
      ageMonths: _parseInt(m['ageMonths']) ?? 24,
      weightKg: _parseDouble(m['weightKg'] ?? m['weight']) ?? 0.0,
      health: health,
      fenceId: (m['fenceId'] ?? '').toString(),
      devices: const [],
      bodyTemp: _parseDouble(m['bodyTemp']) ?? 38.5,
      activityLevel: (m['activityLevel'] ?? '正常').toString(),
      ruminationFreq: (m['ruminationFreq'] ?? '--').toString(),
      lastLocation: '${m['lat'] ?? '--'}, ${m['lng'] ?? '--'}',
    );
  }

  static int? _parseInt(dynamic v) =>
      v is int ? v : v is String ? int.tryParse(v) : null;

  static double? _parseDouble(dynamic v) =>
      v is double ? v : v is num ? v.toDouble() : null;
}
