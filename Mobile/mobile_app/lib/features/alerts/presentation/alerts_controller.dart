import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/api/farm_scoped_controller.dart';
import 'package:smart_livestock_demo/features/alerts/data/alerts_api_repository.dart';
import 'package:smart_livestock_demo/features/alerts/domain/alerts_repository.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>(
  (_) => const AlertsApiRepository(),
);

class AlertsController extends FarmScopedAsyncNotifier<AlertsListData> {
  @override
  Future<AlertsListData> build() async {
    watchActiveFarmId();
    return ref.read(alertsRepositoryProvider).loadAlerts();
  }

  Future<void> refresh({String? status}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(alertsRepositoryProvider).loadAlerts(status: status),
    );
  }

  Future<void> acknowledge(String alertId) async {
    await ref.read(alertsRepositoryProvider).acknowledge(alertId);
    await refresh();
  }

  Future<void> handle(String alertId) async {
    await ref.read(alertsRepositoryProvider).handle(alertId);
    await refresh();
  }

  Future<void> archive(String alertId) async {
    await ref.read(alertsRepositoryProvider).archive(alertId);
    await refresh();
  }

  Future<void> batchHandle(List<String> alertIds) async {
    await ref.read(alertsRepositoryProvider).batchHandle(alertIds);
    await refresh();
  }
}

final alertsControllerProvider =
    AsyncNotifierProvider<AlertsController, AlertsListData>(
  AlertsController.new,
);
