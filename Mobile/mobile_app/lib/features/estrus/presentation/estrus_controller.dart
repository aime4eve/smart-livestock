import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/features/estrus/data/estrus_api_repository.dart';
import 'package:hkt_livestock_agentic/features/estrus/domain/estrus_repository.dart';

final estrusRepositoryProvider = Provider<EstrusRepository>((ref) {
  return const EstrusApiRepository();
});

class EstrusListController extends FarmScopedAsyncNotifier<List<EstrusListItem>> {
  @override
  Future<List<EstrusListItem>> build() async {
    watchActiveFarmId();
    return ref.read(estrusRepositoryProvider).fetchEstrusList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(estrusRepositoryProvider).fetchEstrusList(),
    );
  }
}

final estrusListControllerProvider =
    AsyncNotifierProvider<EstrusListController, List<EstrusListItem>>(
  EstrusListController.new,
);

class EstrusDetailController extends AsyncNotifier<EstrusDetailData> {
  EstrusDetailController(this.livestockId);
  final String livestockId;

  @override
  Future<EstrusDetailData> build() async {
    return ref.read(estrusRepositoryProvider).fetchEstrusDetail(livestockId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(estrusRepositoryProvider).fetchEstrusDetail(livestockId),
    );
  }

  /// Silent refresh for auto-polling: no loading spinner, keeps data on error.
  Future<void> silentRefresh() async {
    final next = await AsyncValue.guard(
      () => ref.read(estrusRepositoryProvider).fetchEstrusDetail(livestockId),
    );
    if (next.hasValue) state = next;
  }
}

final estrusDetailControllerProvider = AsyncNotifierProvider.family<
    EstrusDetailController, EstrusDetailData, String>(
  EstrusDetailController.new,
);
