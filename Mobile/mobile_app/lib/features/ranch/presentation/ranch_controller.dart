import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import 'package:hkt_livestock_agentic/features/ranch/data/ranch_api_repository.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_repository.dart';

final ranchRepositoryProvider = Provider<RanchRepository>(
  (_) => const RanchApiRepository(),
);

/// Drill-down levels for the alert panel.
enum RanchDrillLevel { dashboard, list, detail }

class RanchController extends FarmScopedAsyncNotifier<RanchOverview> {
  RanchDrillLevel _drillLevel = RanchDrillLevel.dashboard;
  String? _selectedCategory;
  String? _selectedAlertId;

  RanchDrillLevel get drillLevel => _drillLevel;
  String? get selectedCategory => _selectedCategory;
  String? get selectedAlertId => _selectedAlertId;

  @override
  Future<RanchOverview> build() async {
    watchActiveFarmId();
    _drillLevel = RanchDrillLevel.dashboard;
    _selectedCategory = null;
    _selectedAlertId = null;
    return ref.read(ranchRepositoryProvider).loadOverview();
  }

  // ── Drill-down navigation ──

  void showDashboard() {
    _drillLevel = RanchDrillLevel.dashboard;
    _selectedCategory = null;
    _selectedAlertId = null;
    _notifyRebuild();
  }

  void showCategoryList(String category) {
    _drillLevel = RanchDrillLevel.list;
    _selectedCategory = category;
    _selectedAlertId = null;
    _notifyRebuild();
  }

  void showAlertDetail(String alertId) {
    _drillLevel = RanchDrillLevel.detail;
    _selectedAlertId = alertId;
    _notifyRebuild();
    markRead(alertId);
  }

  // ── Alert actions ──

  Future<void> markRead(String alertId) async {
    try {
      await ref.read(ranchRepositoryProvider).markRead(alertId);
      final overview = state.value;
      if (overview != null) {
        final updatedAlerts = overview.alerts.map((a) {
          if (a.id == alertId) return a.copyWith(read: true);
          return a;
        }).toList();
        state = AsyncData(overview.copyWith(alerts: updatedAlerts));
      }
    } catch (_) {
      // Silently fail — read status is non-critical
    }
  }

  Future<void> dismiss(String alertId) async {
    await ref.read(ranchRepositoryProvider).dismiss(alertId);
    refresh();
  }

  Future<void> batchRead(List<String> alertIds) async {
    await ref.read(ranchRepositoryProvider).batchRead(alertIds);
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(ranchRepositoryProvider).loadOverview(),
    );
    _drillLevel = RanchDrillLevel.dashboard;
    _selectedCategory = null;
    _selectedAlertId = null;
  }

  void _notifyRebuild() {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current);
    }
  }
}

final ranchControllerProvider =
    AsyncNotifierProvider<RanchController, RanchOverview>(
  RanchController.new,
);
