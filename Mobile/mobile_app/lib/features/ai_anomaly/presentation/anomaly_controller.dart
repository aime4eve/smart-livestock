import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import '../data/anomaly_api_repository.dart';
import 'package:hkt_livestock_agentic/core/models/anomaly_models.dart';
import '../domain/anomaly_repository.dart';

final anomalyRepositoryProvider = Provider<AnomalyRepository>(
  (_) => const AnomalyApiRepository(),
);

/// Farm-scoped (repository uses farmGet): rebuilds on farm switch.
class AnomalyDetailController extends FarmScopedAsyncNotifier<AnomalyScoreData> {
  AnomalyDetailController(this.livestockId);
  final String livestockId;

  @override
  Future<AnomalyScoreData> build() async {
    watchActiveFarmId();
    return ref.read(anomalyRepositoryProvider).fetchLatest(livestockId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(anomalyRepositoryProvider).fetchLatest(livestockId),
    );
  }
}

final anomalyDetailProvider = AsyncNotifierProvider.family<
    AnomalyDetailController, AnomalyScoreData, String>(
  AnomalyDetailController.new,
);

/// Farm-scoped history for the trend chart.
class AnomalyHistoryController
    extends FarmScopedAsyncNotifier<List<AnomalyScoreHistoryItem>> {
  AnomalyHistoryController(this.livestockId);
  final String livestockId;

  @override
  Future<List<AnomalyScoreHistoryItem>> build() async {
    watchActiveFarmId();
    return ref.read(anomalyRepositoryProvider).fetchHistory(livestockId);
  }
}

final anomalyHistoryProvider = AsyncNotifierProvider.family<
    AnomalyHistoryController, List<AnomalyScoreHistoryItem>, String>(
  AnomalyHistoryController.new,
);
