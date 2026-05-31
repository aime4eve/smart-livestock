import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/api/farm_scoped_controller.dart';
import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/features/dashboard/data/dashboard_api_repository.dart';
import 'package:smart_livestock_demo/features/dashboard/domain/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (_) => const DashboardApiRepository(),
);

class DashboardController extends FarmScopedAsyncNotifier<DashboardViewData> {
  @override
  Future<DashboardViewData> build() async {
    watchActiveFarmId();
    for (var i = 0; i < 20; i++) {
      if (ApiClient.instance.activeFarmId != null) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return ref.read(dashboardRepositoryProvider).load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(dashboardRepositoryProvider).load());
  }
}

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardViewData>(DashboardController.new);
