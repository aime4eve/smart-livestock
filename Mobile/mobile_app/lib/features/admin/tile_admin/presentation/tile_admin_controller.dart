import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/features/admin/tile_admin/data/tile_admin_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/tile_admin/domain/tile_admin_models.dart';

final tileAdminRepositoryProvider = Provider<TileAdminApiRepository>(
  (_) => const TileAdminApiRepository(),
);

class TileAdminData {
  const TileAdminData({
    this.regions = const [],
    this.tasks = const [],
    this.farmTasks = const [],
  });
  final List<TileRegion> regions;
  final List<TileTask> tasks;
  final List<FarmTileStatus> farmTasks;
}

class TileAdminController extends AsyncNotifier<TileAdminData> {
  @override
  Future<TileAdminData> build() async {
    final repo = ref.read(tileAdminRepositoryProvider);
    final results = await Future.wait([
      repo.listRegions(),
      repo.listTasks(),
      repo.listFarmTasks(),
    ]);
    return TileAdminData(
      regions: results[0] as List<TileRegion>,
      tasks: results[1] as List<TileTask>,
      farmTasks: results[2] as List<FarmTileStatus>,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  /// 静默刷新（轮询用）：不设 AsyncLoading，避免 widget tree 重建导致
  /// DefaultTabController 的 tab index 重置回 0。失败时保留旧数据。
  Future<void> silentRefresh() async {
    final next = await AsyncValue.guard(() => build());
    if (next.hasValue) state = next;
  }
}

final tileAdminControllerProvider =
    AsyncNotifierProvider<TileAdminController, TileAdminData>(
  TileAdminController.new,
);
