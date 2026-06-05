import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/api/farm_scoped_controller.dart';
import 'package:smart_livestock_demo/core/models/health_models.dart';
import 'package:smart_livestock_demo/features/twin_overview/data/twin_overview_api_repository.dart';
import 'package:smart_livestock_demo/features/twin_overview/domain/twin_overview_repository.dart';

final twinOverviewRepositoryProvider = Provider<TwinOverviewRepository>(
  (_) => const TwinOverviewApiRepository(),
);

class TwinOverviewController
    extends FarmScopedAsyncNotifier<HealthOverviewResponse> {
  @override
  Future<HealthOverviewResponse> build() async {
    watchActiveFarmId();
    return ref.read(twinOverviewRepositoryProvider).load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(twinOverviewRepositoryProvider).load(),
    );
  }
}

final twinOverviewControllerProvider = AsyncNotifierProvider<
    TwinOverviewController, HealthOverviewResponse>(
  TwinOverviewController.new,
);
