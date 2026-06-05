import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/admin/tile_admin/data/tile_admin_api_repository.dart';
import 'package:smart_livestock_demo/features/admin/tile_admin/domain/tile_admin_models.dart';

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
}

final tileAdminControllerProvider =
    AsyncNotifierProvider<TileAdminController, TileAdminData>(
  TileAdminController.new,
);
