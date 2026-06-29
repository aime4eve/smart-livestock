import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/features/fever_warning/data/fever_api_repository.dart';
import 'package:hkt_livestock_agentic/features/fever_warning/domain/fever_repository.dart';

final feverRepositoryProvider = Provider<FeverRepository>((ref) {
  return const FeverApiRepository();
});

class FeverListController extends FarmScopedAsyncNotifier<List<FeverListItem>> {
  @override
  Future<List<FeverListItem>> build() async {
    watchActiveFarmId();
    return ref.read(feverRepositoryProvider).fetchFeverList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(feverRepositoryProvider).fetchFeverList(),
    );
  }
}

final feverListControllerProvider =
    AsyncNotifierProvider<FeverListController, List<FeverListItem>>(
  FeverListController.new,
);

class FeverDetailController extends AsyncNotifier<FeverDetailData> {
  FeverDetailController(this.livestockId);
  final String livestockId;

  @override
  Future<FeverDetailData> build() async {
    return ref.read(feverRepositoryProvider).fetchFeverDetail(livestockId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(feverRepositoryProvider).fetchFeverDetail(livestockId),
    );
  }

  /// Silent refresh for auto-polling: no loading spinner, keeps data on error.
  Future<void> silentRefresh() async {
    final next = await AsyncValue.guard(
      () => ref.read(feverRepositoryProvider).fetchFeverDetail(livestockId),
    );
    if (next.hasValue) state = next;
  }
}

final feverDetailControllerProvider = AsyncNotifierProvider.family<
    FeverDetailController, FeverDetailData, String>(
  FeverDetailController.new,
);

final feverDurationProvider =
    FutureProvider.family<List<DailyFeverHour>, String>((ref, livestockId) async {
  return ref.read(feverRepositoryProvider).fetchFeverDuration(livestockId);
});
