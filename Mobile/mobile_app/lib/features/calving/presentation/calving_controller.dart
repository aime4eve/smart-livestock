import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/features/calving/data/calving_api_repository.dart';
import 'package:hkt_livestock_agentic/features/calving/domain/calving_repository.dart';

final calvingRepositoryProvider = Provider<CalvingRepository>((ref) {
  return const CalvingApiRepository();
});

class CalvingListController
    extends FarmScopedAsyncNotifier<List<CalvingPredictionItem>> {
  @override
  Future<List<CalvingPredictionItem>> build() async {
    watchActiveFarmId();
    return ref.read(calvingRepositoryProvider).fetchCalvingPredictions();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(calvingRepositoryProvider).fetchCalvingPredictions(),
    );
  }
}

final calvingListControllerProvider = AsyncNotifierProvider<
    CalvingListController, List<CalvingPredictionItem>>(
  CalvingListController.new,
);
