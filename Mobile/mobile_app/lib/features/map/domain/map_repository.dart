import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';

class MapViewData {
  const MapViewData({
    required this.viewState,
    required this.availableAnimals,
    required this.selectedAnimal,
    required this.selectedRange,
    required this.summaryText,
    required this.fallbackItems,
    required this.mapCenter,
    required this.zoom,
    required this.livestockLocations,
    required this.trajectoryPoints,
    required this.fences,
    this.message,
  });

  final ViewState viewState;
  final List<String> availableAnimals;
  final String selectedAnimal;
  final TrajectoryRange selectedRange;
  final String summaryText;
  final List<String> fallbackItems;
  final LatLng mapCenter;
  final double zoom;
  final List<GeoPoint> livestockLocations;
  final List<GeoPoint> trajectoryPoints;
  final List<FencePolygon> fences;
  final String? message;
}

abstract class MapRepository {
  MapViewData load({
    required ViewState viewState,
    required String selectedAnimal,
    required TrajectoryRange selectedRange,
  });
}
