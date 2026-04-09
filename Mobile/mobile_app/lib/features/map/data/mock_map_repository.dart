import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/data/generators/gps_trajectory_generator.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/map/domain/map_repository.dart';

class MockMapRepository implements MapRepository {
  const MockMapRepository();

  static final _gpsGen = GpsTrajectoryGenerator(seed: 42);

  @override
  MapViewData load({
    required ViewState viewState,
    required String selectedAnimal,
    required TrajectoryRange selectedRange,
  }) {
    final rangeLabel = switch (selectedRange) {
      TrajectoryRange.h24 => '24h',
      TrajectoryRange.d7 => '7d',
      TrajectoryRange.d30 => '30d',
    };

    List<GeoPoint> trajectory = const [];
    if (viewState == ViewState.normal) {
      LivestockInfo? cow;
      for (final l in DemoSeed.livestock) {
        if (l.earTag == selectedAnimal) {
          cow = l;
          break;
        }
      }

      if (cow != null) {
        FencePolygon? fence;
        for (final f in DemoSeed.fencePolygons) {
          if (f.id == cow.fenceId) {
            fence = f;
            break;
          }
        }

        if (fence != null) {
          final end = DateTime.utc(2026, 4, 8, 10);
          final start = switch (selectedRange) {
            TrajectoryRange.h24 => end.subtract(const Duration(hours: 24)),
            TrajectoryRange.d7 => end.subtract(const Duration(days: 7)),
            TrajectoryRange.d30 => end.subtract(const Duration(days: 30)),
          };
          final full = _gpsGen.generate(
            earTag: selectedAnimal,
            fenceBoundary: fence.points,
            start: start,
            end: end,
          );
          trajectory = full;
        }
      }
    }

    return MapViewData(
      viewState: viewState,
      availableAnimals: DemoSeed.earTags,
      selectedAnimal: selectedAnimal,
      selectedRange: selectedRange,
      summaryText: '$selectedAnimal · $rangeLabel',
      fallbackItems: DemoSeed.earTags
          .take(5)
          .map((t) => '$t · 最近点')
          .toList(),
      mapCenter: DemoSeed.mapCenter,
      zoom: DemoSeed.defaultZoom,
      livestockLocations: DemoSeed.livestockLocations,
      trajectoryPoints: trajectory,
      fences: DemoSeed.fencePolygons,
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无定位数据',
        ViewState.error => '地图不可用，列表回退（演示）',
        ViewState.forbidden => '无权限查看地图（演示）',
        ViewState.offline => '离线：$selectedAnimal · $rangeLabel（演示）',
        ViewState.normal => null,
      },
    );
  }
}
