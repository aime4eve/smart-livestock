import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import 'package:hkt_livestock_agentic/features/alerts/data/alerts_api_repository.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alert_summary.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alerts_repository.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>(
  (_) => const AlertsApiRepository(),
);

class AlertsController extends FarmScopedAsyncNotifier<AlertsListData> {
  /// Page size for the paginated alert list (server-side, real total).
  static const int pageSize = 50;

  // ── Filter state (status/severity/types/fenceId go to the API, type chip is UI-only) ──

  /// Defaults to ACTIVE so the alert center opens on "needs handling now"
  /// (matching the page's default tab) instead of the full history.
  String? _filterStatus = 'ACTIVE';
  String? _filterSeverity;
  Set<String>? _filterTypes;
  String? _filterFenceId;
  bool _filterUnreadOnly = false;
  String? _filterType;
  int _page = 1;

  String? get filterStatus => _filterStatus;
  String? get filterSeverity => _filterSeverity;
  String? get filterType => _filterType;

  bool get canLoadMore {
    final data = state.value;
    if (data == null) return false;
    return data.items.length < data.total;
  }

  Future<AlertsListData> _fetchPage(int page) {
    return ref.read(alertsRepositoryProvider).loadAlerts(
          page: page,
          pageSize: pageSize,
          status: _filterStatus,
          severity: _filterSeverity,
          types: _filterTypes,
          fenceId: _filterFenceId,
          unreadOnly: _filterUnreadOnly,
        );
  }

  @override
  Future<AlertsListData> build() async {
    watchActiveFarmId();
    _page = 1;
    return _fetchPage(1);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(1));
    _page = 1;
  }

  /// Silent refresh for polling: no AsyncLoading spinner. Only reloads the
  /// first page — with later pages loaded, refreshing would shrink the list
  /// under the user's finger.
  Future<void> silentRefresh() async {
    if (_page > 1) return;
    final next = await AsyncValue.guard(() => _fetchPage(1));
    if (next.hasValue) state = next;
  }

  /// Appends the next page. Returns true when new items were added.
  Future<bool> loadMore() async {
    final data = state.value;
    if (data == null || !canLoadMore) return false;
    final next = await AsyncValue.guard(() => _fetchPage(_page + 1));
    if (!next.hasValue) return false;
    final more = next.value!;
    final existingIds = data.items.map((a) => a.id).toSet();
    final merged = [
      ...data.items,
      ...more.items.where((a) => !existingIds.contains(a.id)),
    ];
    _page = _page + 1;
    state = AsyncData(AlertsListData(
      items: merged,
      total: more.total,
      page: _page,
      pageSize: more.pageSize,
    ));
    return more.items.isNotEmpty;
  }

  void setFilterStatus(String? status) {
    _filterStatus = status;
    refresh();
  }

  void setFilterSeverity(String? severity) {
    _filterSeverity = severity;
    refresh();
  }

  /// Severity cells count ACTIVE alerts only, so tapping one always means
  /// "show me those N active alerts": the status filter snaps to ACTIVE and
  /// the list count equals the cell count. [unreadOnly] toggles the
  /// "Unread" hero filter on/off.
  void applyFilters({String? status, String? severity, bool? unreadOnly}) {
    if (status != null) _filterStatus = status;
    if (unreadOnly != null) _filterUnreadOnly = unreadOnly;
    _filterSeverity = severity;
    refresh();
  }

  /// Server-side type filter (fence/health/device category sets or a single
  /// selected chip type). Empty/null = all types. Call from the page so deep
  /// links and type chips filter on the API and pagination totals stay right.
  void setFilterCategory(Set<String> types) {
    _filterTypes = types.isEmpty ? null : types;
    refresh();
  }

  void setFilterFenceId(String? fenceId) {
    _filterFenceId = fenceId;
    refresh();
  }

  void setFilterType(String? type) {
    // Legacy no-op: type chips now filter server-side via setFilterCategory.
    _filterType = type;
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
    // Backend has no /alerts/batch-dismiss; reuse /alerts/batch-handle
    // (deprecated but active, internally loops dismiss, OWNER/B2B_ADMIN only).
    await ref.read(alertsRepositoryProvider).batchDismiss(alertIds);
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

/// Farm-global alert counters for the RANCH page badges/cards (always
/// unscoped). The alert center uses [scopedAlertSummaryProvider] instead so a
/// category deep link can scope its header without polluting the ranch page.
class AlertSummaryController extends FarmScopedAsyncNotifier<RanchAlertSummary> {
  @override
  Future<RanchAlertSummary> build() async {
    watchActiveFarmId();
    return ref.read(alertsRepositoryProvider).loadSummary();
  }

  Future<void> silentRefresh() async {
    final next = await AsyncValue.guard(
      () => ref.read(alertsRepositoryProvider).loadSummary(),
    );
    if (next.hasValue) state = next;
  }
}

final alertSummaryControllerProvider =
    AsyncNotifierProvider<AlertSummaryController, RanchAlertSummary>(
  AlertSummaryController.new,
);

/// Key for [scopedAlertSummaryProvider]: '' = farm-wide, else sorted types CSV.
String scopedSummaryKey(Set<String> types) =>
    types.isEmpty ? '' : (types.toList()..sort()).join(',');

/// Category-scoped summary for the alert center header: its numbers match the
/// category-filtered list exactly (ranch badges use the farm-wide provider).
final scopedAlertSummaryProvider = FutureProvider.autoDispose
    .family<RanchAlertSummary, String>((ref, key) {
  final types = key.isEmpty ? null : key.split(',').toSet();
  return ref.watch(alertsRepositoryProvider).loadSummary(types: types);
});
