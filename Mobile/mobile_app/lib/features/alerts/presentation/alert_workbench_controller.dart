import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import 'package:hkt_livestock_agentic/features/alerts/data/alert_workbench_api_repository.dart';
import 'package:hkt_livestock_agentic/features/alerts/data/alerts_api_repository.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alert_workbench.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alert_workbench_repository.dart';

final alertWorkbenchRepositoryProvider = Provider<AlertWorkbenchRepository>(
  (_) => const AlertWorkbenchApiRepository(),
);

class AlertWorkbenchController
    extends FarmScopedAsyncNotifier<AlertWorkbenchData> {
  String _bucket = 'all';
  Set<String> _asset = {'all'};
  String? _fenceId;
  int _page = 1;
  int _generation = 0;

  String get bucket => _bucket;
  Set<String> get asset => _asset;
  String? get fenceId => _fenceId;

  bool get canLoadMore => state.value?.canLoadMore ?? false;

  Future<AlertWorkbenchData> _fetch(int page) {
    return ref
        .read(alertWorkbenchRepositoryProvider)
        .load(bucket: _bucket, asset: _asset, fenceId: _fenceId, page: page);
  }

  @override
  Future<AlertWorkbenchData> build() async {
    watchActiveFarmId();
    _page = 1;
    final generation = ++_generation;
    final result = await _fetch(1);
    if (generation != _generation) return state.value ?? result;
    return result;
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(1));
    _page = 1;
    if (generation != _generation) return;
  }

  Future<void> silentRefresh() async {
    if (_page > 1) return;
    final generation = ++_generation;
    final next = await AsyncValue.guard(() => _fetch(1));
    if (generation != _generation) return;
    if (next.hasValue) state = next;
  }

  Future<bool> loadMore() async {
    final current = state.value;
    if (current == null || !canLoadMore) return false;
    final generation = ++_generation;
    final next = await AsyncValue.guard(() => _fetch(_page + 1));
    if (generation != _generation) return false;
    final more = next.value;
    if (more == null) return false;
    final ids = current.items.map((item) => item.id).toSet();
    final merged = [
      ...current.items,
      ...more.items.where((item) => !ids.contains(item.id)),
    ];
    _page++;
    state = AsyncData(
      AlertWorkbenchData(
        summary: more.summary,
        items: merged,
        page: _page,
        pageSize: more.pageSize,
        total: more.total,
      ),
    );
    return true;
  }

  Future<void> setFilters({
    String? bucket,
    Set<String>? asset,
    String? fenceId,
  }) async {
    _bucket = bucket ?? 'all';
    _asset = asset == null || asset.isEmpty ? {'all'} : asset;
    _fenceId = fenceId;
    await refresh();
  }

  Future<void> markRead(WorkbenchItem item) async {
    final ids = item.reasons
        .where((reason) => !reason.read)
        .map((reason) => reason.alertId)
        .toList();
    if (ids.isNotEmpty) await const AlertsApiRepository().batchRead(ids);
    await silentRefresh();
  }

  Future<void> dismiss(WorkbenchItem item) async {
    for (final reason in item.reasons) {
      await const AlertsApiRepository().dismiss(reason.alertId);
    }
    await refresh();
  }
}

final alertWorkbenchControllerProvider =
    AsyncNotifierProvider<AlertWorkbenchController, AlertWorkbenchData>(
      AlertWorkbenchController.new,
    );

/// Independent all-snapshot for the compact ranch tab, so changing filters in
/// the full alert center does not mutate the ranch view.
final ranchAlertWorkbenchProvider = FutureProvider.autoDispose
    .family<AlertWorkbenchData, String>((ref, farmId) {
      return ref.watch(alertWorkbenchRepositoryProvider).load(bucket: 'all');
    });
