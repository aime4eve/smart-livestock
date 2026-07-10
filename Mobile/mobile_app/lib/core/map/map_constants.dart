import 'package:latlong2/latlong.dart';

/// Map anchor points and constants previously in DemoSeed.
/// These represent static map reference data for the demo ranch area.
class MapConstants {
  const MapConstants._();

  static const LatLng mapCenter = LatLng(28.2282, 112.9388);
  static const double defaultZoom = 14.0;

  /// Anchor points: water troughs, feeding stations, salt licks.
  static const List<LatLng> gpsAnchorPoints = [
    LatLng(28.2336, 112.9435),
    LatLng(28.2312, 112.9409),
    LatLng(28.2268, 112.9342),
    LatLng(28.2254, 112.9357),
    LatLng(28.2332, 112.9415),
    LatLng(28.2250, 112.9330),
  ];
}
