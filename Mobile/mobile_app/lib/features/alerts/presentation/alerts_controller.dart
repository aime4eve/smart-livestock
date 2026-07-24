import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import 'package:hkt_livestock_agentic/features/alerts/data/alerts_api_repository.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alerts_repository.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>(
  (_) => const AlertsApiRepository(),
);

class AlertsController extends FarmScopedAsyncNotifier<AlertsListData> {
  // ── Filter state (applied to API requests for status/severity, UI for type) ──

  String? _filterStatus;
  String? _filterSeverity;
  String? _filterType;

  String? get filterStatus => _filterStatus;
  String? get filterSeverity => _filterSeverity;
  String? get filterType => _filterType;

  @override
  Future<AlertsListData> build() async {
    watchActiveFarmId();
    return ref.read(alertsRepositoryProvider).loadAlerts(
          status: _filterStatus,
          severity: _filterSeverity,
        );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(alertsRepositoryProvider).loadAlerts(
            status: _filterStatus,
            severity: _filterSeverity,
          ),
    );
  }

  void setFilterStatus(String? status) {
    _filterStatus = status;
    refresh();
  }

  void setFilterSeverity(String? severity) {
    _filterSeverity = severity;
    refresh();
  }

  void setFilterType(String? type) {
    _filterType = type;
    state = AsyncData(state.value ?? const AlertsListData(items: [], total: 0, page: 1, pageSize: 20));
  }

  // ── Actions ──

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

  Future<void> batchDismiss(List<String> alertIds) async {
    await ref.read(alertsRepositoryProvider).batchDismiss(alertIds);
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
