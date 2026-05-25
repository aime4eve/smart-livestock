import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/dashboard/data/dashboard_api_repository.dart';
import 'package:smart_livestock_demo/features/dashboard/domain/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (_) => const DashboardApiRepository(),
);

class DashboardController extends AsyncNotifier<DashboardViewData> {
  @override
  Future<DashboardViewData> build() async {
    return ref.read(dashboardRepositoryProvider).load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(dashboardRepositoryProvider).load());
  }
}

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardViewData>(DashboardController.new);
