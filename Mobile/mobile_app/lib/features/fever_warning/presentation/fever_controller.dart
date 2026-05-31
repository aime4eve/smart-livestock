import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/api/farm_scoped_controller.dart';
import 'package:smart_livestock_demo/core/models/health_models.dart';
import 'package:smart_livestock_demo/features/fever_warning/data/fever_api_repository.dart';
import 'package:smart_livestock_demo/features/fever_warning/domain/fever_repository.dart';

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
}

final feverDetailControllerProvider = AsyncNotifierProvider.family<
    FeverDetailController, FeverDetailData, String>(
  FeverDetailController.new,
);
