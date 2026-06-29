import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/anomaly_api_repository.dart';
import '../domain/anomaly_models.dart';
import '../domain/anomaly_repository.dart';

final anomalyRepositoryProvider = Provider<AnomalyRepository>(
  (_) => const AnomalyApiRepository(),
);

class AnomalyDetailController extends AsyncNotifier<AnomalyScoreData> {
  AnomalyDetailController(this.livestockId);
  final String livestockId;

  @override
  Future<AnomalyScoreData> build() async {
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

// History provider for the trend chart.
final anomalyHistoryProvider =
    FutureProvider.autoDispose.family<List<AnomalyScoreHistoryItem>, String>(
  (ref, livestockId) {
    return ref.read(anomalyRepositoryProvider).fetchHistory(livestockId);
  },
);
