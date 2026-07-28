import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/map/coord_transform.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_factory.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';
import 'package:latlong2/latlong.dart';

/// Shared offline-tile map for NIX-68 LINE views (candidate preview, LINE
/// report, LINE comparison). Renders the given polylines (WGS-84) and
/// markers, fitting the camera to all points. Mirrors the flutter_map +
/// offline tile pattern of trajectory_sheet.dart:631-650.
class TrackLineMap extends ConsumerStatefulWidget {
  const TrackLineMap({
    super.key,
    required this.polylines,
    this.markers = const [],
    this.height = 300,
  });

  /// Polylines in WGS-84 coordinates (transformed to GCJ-02 when the
  /// active tile source requires it).
  final List<Polyline> polylines;
  final List<Marker> markers;
  final double height;

  @override
  ConsumerState<TrackLineMap> createState() => _TrackLineMapState();
}

class _TrackLineMapState extends ConsumerState<TrackLineMap> {
  SmartTileProvider? _tileProvider;
  final _mapController = MapController();
  bool _lastTransformed = false;
  LatLngBounds? _lastBounds;

  @override
  void initState() {
    super.initState();
    _initTileProvider();
  }

  Future<void> _initTileProvider() async {
    _tileProvider = await loadSmartTileProvider(
      ref,
      onSourceChanged: () {
        if (mounted) setState(() {});
      },
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tileProvider?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  bool get _shouldTransform =>
      _tileProvider?.shouldTransformCoordinates() ?? false;

  List<LatLng> _transform(List<LatLng> raw) =>
      _shouldTransform ? CoordTransform.wgs84ToGcj02All(raw) : raw;

  /// Expand degenerate bounds (single point / zero span) by a small epsilon
  /// to avoid Infinity zoom in flutter_map.
  LatLngBounds _safeBounds(LatLngBounds bounds) {
    var b = bounds;
    if (b.north == b.south && b.east == b.west) {
      const eps = 0.0005;
      b = LatLngBounds(
        LatLng(b.south - eps, b.west - eps),
        LatLng(b.north + eps, b.east + eps),
      );
    }
    return b;
  }

  @override
  Widget build(BuildContext context) {
    final polylines = widget.polylines
        .map((p) => Polyline(
              points: _transform(p.points),
              color: p.color,
              strokeWidth: p.strokeWidth,
              borderColor: p.borderColor,
              borderStrokeWidth: p.borderStrokeWidth,
              pattern: p.pattern,
            ))
        .toList();
    final markers = widget.markers
        .map((m) => Marker(
              point: _transform([m.point]).first,
              width: m.width,
              height: m.height,
              alignment: m.alignment,
              child: m.child,
            ))
        .toList();

    final allPoints = polylines.expand((p) => p.points).toList()
      ..addAll(markers.map((m) => m.point));
    if (allPoints.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final bounds = _safeBounds(LatLngBounds.fromPoints(allPoints));

    // Re-fit the camera when the tile source switches coordinate system.
    if (_lastTransformed != _shouldTransform) {
      _lastTransformed = _shouldTransform;
      _lastBounds = bounds;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _lastBounds != null) {
          _mapController.fitCamera(CameraFit.bounds(
              bounds: _lastBounds!, padding: const EdgeInsets.all(30)));
        }
      });
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: widget.height,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
                bounds: bounds, padding: const EdgeInsets.all(30)),
          ),
          children: [
            TileLayer(
              key: ValueKey(_tileProvider?.activeSourceName),
              tileProvider: _tileProvider,
              urlTemplate: '',
            ),
            if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
            if (markers.isNotEmpty) MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }
}

/// Small circular dot marker used for start/end/highlight points.
class TrackDotMarker extends StatelessWidget {
  const TrackDotMarker({super.key, required this.color, this.size = 12});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}
