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

  Future<void> markRead(String alertId) async {
    await ref.read(alertsRepositoryProvider).markRead(alertId);
    await refresh();
  }

  Future<void> dismiss(String alertId) async {
    await ref.read(alertsRepositoryProvider).dismiss(alertId);
    await refresh();
  }

  Future<void> batchRead(List<String> alertIds) async {
    await ref.read(alertsRepositoryProvider).batchRead(alertIds);
    await refresh();
  }

  // ── Legacy compatibility (HealthBottomSheet rewrite will remove these) ──

  Future<void> acknowledge(String alertId) async {
    await markRead(alertId);
  }

  Future<void> handle(String alertId) async {
    await dismiss(alertId);
  }

  Future<void> archive(String alertId) async {
    // No-op: auto-resolve is server-driven
  }

  Future<void> batchHandle(List<String> alertIds) async {
    await batchRead(alertIds);
  }
}

final alertsControllerProvider =
    AsyncNotifierProvider<AlertsController, AlertsListData>(
  AlertsController.new,
);
