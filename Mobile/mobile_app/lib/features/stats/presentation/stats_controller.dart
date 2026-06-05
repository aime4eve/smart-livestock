import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/api/farm_scoped_controller.dart';
import 'package:smart_livestock_demo/features/stats/data/stats_api_repository.dart';
import 'package:smart_livestock_demo/features/stats/domain/stats_repository.dart';

final statsRepositoryProvider = Provider<StatsRepository>(
  (_) => const StatsApiRepository(),
);

class StatsController extends FarmScopedAsyncNotifier<StatsResponse> {
  @override
  Future<StatsResponse> build() async {
    watchActiveFarmId();
    return ref.read(statsRepositoryProvider).load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(statsRepositoryProvider).load(),
    );
  }
}

final statsControllerProvider =
    AsyncNotifierProvider<StatsController, StatsResponse>(
  StatsController.new,
);
