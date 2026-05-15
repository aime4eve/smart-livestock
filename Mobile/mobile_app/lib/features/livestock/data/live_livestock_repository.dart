import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/livestock/domain/livestock_repository.dart';

class LiveLivestockRepository implements LivestockRepository {
  const LiveLivestockRepository();

  @override
  LivestockViewData load(
      {required ViewState viewState, required String earTag}) {
    if (viewState != ViewState.normal) {
      return LivestockViewData(viewState: viewState, detail: null);
    }

    final cache = ApiCache.instance;
    final animal = cache.animals.cast<Map<String, dynamic>?>().firstWhere(
          (a) => a?['livestockCode'] == earTag || a?['earTag'] == earTag,
          orElse: () => null,
        );

    if (animal == null) {
      return const LivestockViewData(
        viewState: ViewState.empty,
        detail: null,
        message: '未找到该牲畜',
      );
    }

    final healthStr =
        (animal['healthStatus'] as String?)?.toUpperCase() ?? 'HEALTHY';
    final health = healthStr == 'WARNING'
        ? LivestockHealth.watch
        : healthStr == 'CRITICAL'
            ? LivestockHealth.abnormal
            : LivestockHealth.healthy;

    final detail = LivestockDetail(
      earTag: earTag,
      livestockId:
          animal['id']?.toString() ?? animal['livestockId']?.toString() ?? '',
      breed: animal['breed']?.toString() ?? '未知品种',
      ageMonths: _parseInt(animal['ageMonths']) ?? 24,
      weightKg: _parseDouble(animal['weightKg'] ?? animal['weight']) ?? 0.0,
      health: health,
      fenceId: animal['fenceId']?.toString() ?? '',
      devices: const [],
      bodyTemp: _parseDouble(animal['bodyTemp']) ?? 38.5,
      activityLevel: animal['activityLevel']?.toString() ?? '正常',
      ruminationFreq: animal['ruminationFreq']?.toString() ?? '--',
      lastLocation:
          '${animal['lat'] ?? '--'}, ${animal['lng'] ?? '--'}',
    );

    return LivestockViewData(viewState: viewState, detail: detail);
  }

  static int? _parseInt(dynamic v) =>
      v is int ? v : v is String ? int.tryParse(v) : null;

  static double? _parseDouble(dynamic v) =>
      v is double ? v : v is num ? v.toDouble() : null;
}
