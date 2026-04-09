import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/map/domain/map_repository.dart';

class MockMapRepository implements MapRepository {
  const MockMapRepository();

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
    return MapViewData(
      viewState: viewState,
      availableAnimals: DemoSeed.earTags,
      selectedAnimal: selectedAnimal,
      selectedRange: selectedRange,
      summaryText: '$selectedAnimal · $rangeLabel',
      fallbackItems: const [
        '地图不可用，列表回退（演示）',
        '耳标-001 · 最近点',
        '耳标-002 · 最近点',
      ],
      mapCenter: DemoSeed.mapCenter,
      zoom: DemoSeed.defaultZoom,
      livestockLocations: DemoSeed.livestockLocations,
      trajectoryPoints: DemoSeed.trajectoryPoints,
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
