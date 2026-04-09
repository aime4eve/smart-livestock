import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/map/data/mock_map_repository.dart';
import 'package:smart_livestock_demo/features/map/domain/map_repository.dart';

class LiveMapRepository implements MapRepository {
  const LiveMapRepository();

  static const MockMapRepository _fallback = MockMapRepository();

  @override
  MapViewData load({
    required ViewState viewState,
    required String selectedAnimal,
    required TrajectoryRange selectedRange,
  }) {
    final cache = ApiCache.instance;
    if (!cache.initialized) {
      return _fallback.load(
        viewState: viewState,
        selectedAnimal: selectedAnimal,
        selectedRange: selectedRange,
      );
    }

    final rangeLabel = switch (selectedRange) {
      TrajectoryRange.h24 => '24h',
      TrajectoryRange.d7 => '7d',
      TrajectoryRange.d30 => '30d',
    };

    final animals = cache.animals
        .map((a) => a['earTag'] as String)
        .toList();

    final fallbackItems = cache.animals
        .map((a) => '${a['earTag']} · 最近点')
        .toList();

    // Parse fences from cache
    final fences = cache.fences.map((f) {
      final coords = (f['coordinates'] as List?) ?? [];
      final points = coords
          .map<LatLng?>((c) {
            final list = c as List?;
            if (list == null || list.length < 2) return null;
            return LatLng((list[1] as num).toDouble(), (list[0] as num).toDouble());
          })
          .whereType<LatLng>()
          .toList();
      return FencePolygon(
        id: f['id'] as String? ?? '',
        name: f['name'] as String? ?? '',
        points: points,
        colorValue: 0xFF4C9A5F,
      );
    }).toList();

    return MapViewData(
      viewState: viewState,
      availableAnimals: animals,
      selectedAnimal: selectedAnimal,
      selectedRange: selectedRange,
      summaryText: '$selectedAnimal · $rangeLabel',
      fallbackItems: fallbackItems,
      mapCenter: DemoSeed.mapCenter,
      zoom: DemoSeed.defaultZoom,
      livestockLocations: _parseLocations(cache.animals),
      trajectoryPoints: _parseTrajectory(cache),
      fences: fences,
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无定位数据',
        ViewState.error => '地图不可用，列表回退',
        ViewState.forbidden => '无权限查看地图',
        ViewState.offline => '离线：$selectedAnimal · $rangeLabel',
        ViewState.normal => null,
      },
    );
  }

  static List<GeoPoint> _parseLocations(List<Map<String, dynamic>> animals) {
    return animals
        .map(
          (a) => GeoPoint(
            lat: (a['lat'] as num?)?.toDouble() ?? 0,
            lng: (a['lng'] as num?)?.toDouble() ?? 0,
            timestamp: a['timestamp'] as String? ?? '',
          ),
        )
        .toList();
  }

  static List<GeoPoint> _parseTrajectory(ApiCache cache) {
    return cache.mapTrajectoryPoints
        .map(
          (p) => GeoPoint(
            lat: (p['lat'] as num?)?.toDouble() ?? 0,
            lng: (p['lng'] as num?)?.toDouble() ?? 0,
            timestamp: p['ts'] as String? ?? p['timestamp'] as String? ?? '',
          ),
        )
        .toList();
  }
}
