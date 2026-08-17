import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/admin/datagen/domain/datagen_models.dart';

class DatagenApiRepository {
  const DatagenApiRepository();

  static const _base = '/admin/datagen';

  Future<List<DatagenFarm>> loadFarms() async {
    final data = await ApiClient.instance.get('$_base/farms');
    return (data['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(DatagenFarm.fromJson)
        .toList();
  }

  Future<DatagenConsoleData> loadConsole(int farmId) async {
    final data = await ApiClient.instance.get('$_base/console?farmId=$farmId');
    return DatagenConsoleData.fromJson(data);
  }

  Future<DatagenConsoleData> updateControl({
    required int farmId,
    required bool enabled,
    required List<int> deviceIds,
  }) async {
    await ApiClient.instance.put(
      '$_base/control/$farmId',
      body: {'enabled': enabled, 'deviceIds': deviceIds},
    );
    return loadConsole(farmId);
  }

  Future<DatagenClearResult> previewClear({
    required int farmId,
    required String rangeType,
    DateTime? from,
    DateTime? to,
  }) async {
    final data = await ApiClient.instance.post(
      '$_base/clear/preview',
      body: {
        'farmId': farmId,
        'rangeType': rangeType,
        'from': from?.toUtc().toIso8601String(),
        'to': to?.toUtc().toIso8601String(),
      },
    );
    return DatagenClearResult.fromJson(data.cast<String, dynamic>());
  }

  Future<DatagenClearResult> clear({
    required int farmId,
    required String rangeType,
    required String confirmText,
    DateTime? from,
    DateTime? to,
  }) async {
    final data = await ApiClient.instance.post(
      '$_base/clear',
      body: {
        'farmId': farmId,
        'rangeType': rangeType,
        'from': from?.toUtc().toIso8601String(),
        'to': to?.toUtc().toIso8601String(),
        'confirmText': confirmText,
      },
    );
    return DatagenClearResult.fromJson(data.cast<String, dynamic>());
  }
}
