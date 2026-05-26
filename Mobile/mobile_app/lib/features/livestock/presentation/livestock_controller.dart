import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/core_models.dart';
import 'package:smart_livestock_demo/features/livestock/data/livestock_api_repository.dart';
import 'package:smart_livestock_demo/features/livestock/domain/livestock_repository.dart';

final livestockRepositoryProvider = Provider<LivestockRepository>((ref) {
  return const LivestockApiRepository();
});

class LivestockListController extends AsyncNotifier<LivestockListData> {
  @override
  Future<LivestockListData> build() async {
    return ref.read(livestockRepositoryProvider).loadAll();
  }

  Future<void> refresh({String? status}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(livestockRepositoryProvider).loadAll(status: status),
    );
  }
}

final livestockListControllerProvider =
    AsyncNotifierProvider<LivestockListController, LivestockListData>(
  LivestockListController.new,
);

class LivestockDetailController extends AsyncNotifier<LivestockDetail> {
  LivestockDetailController(this.id);

  final String id;

  @override
  Future<LivestockDetail> build() async {
    return ref.read(livestockRepositoryProvider).loadDetail(id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(livestockRepositoryProvider).loadDetail(id),
    );
  }
}

final livestockDetailControllerProvider = AsyncNotifierProvider.family<
    LivestockDetailController, LivestockDetail, String>(
  LivestockDetailController.new,
);
