import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/map/map_config.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_edit_session.dart';

typedef FenceMoveVertex = void Function(int vertexIndex, LatLng point);
typedef FenceInsertVertex = void Function(int edgeStartIndex, LatLng point);
typedef FenceRemoveVertex = void Function(int vertexIndex);
typedef FenceTranslate = void Function(double latitudeDelta, double longitudeDelta);

class FenceEditOverlay extends StatefulWidget {
  const FenceEditOverlay({
    super.key,
    this.isEditing = true,
    this.isInteractive = true,
    required this.mapController,
    required this.points,
    required this.activeTool,
    required this.onMoveVertex,
    required this.onInsertVertex,
    required this.onRemoveVertex,
    required this.onTranslate,
  });

  final bool isEditing;
  final bool isInteractive;
  final MapController mapController;
  final List<LatLng> points;
  final FenceEditTool activeTool;
  final FenceMoveVertex onMoveVertex;
  final FenceInsertVertex onInsertVertex;
  final FenceRemoveVertex onRemoveVertex;
  final FenceTranslate onTranslate;

  @override
  State<FenceEditOverlay> createState() => _FenceEditOverlayState();
}

class _FenceEditOverlayState extends State<FenceEditOverlay> {
  static const _edgeHitThreshold = 24.0;

  final _gestureKey = GlobalKey();
  Offset? _lastTranslateOffset;
  int? _draggingVertexIndex;

  @override
  void didUpdateWidget(covariant FenceEditOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeTool != widget.activeTool) {
      _draggingVertexIndex = null;
    } else if (widget.activeTool == FenceEditTool.moveVertex &&
        oldWidget.points.length != widget.points.length) {
      _draggingVertexIndex = null;
    }
    if (_draggingVertexIndex != null &&
        _draggingVertexIndex! >= widget.points.length) {
      _draggingVertexIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEditing) {
      return const SizedBox.shrink();
    }

    final initialCenter =
        widget.points.isNotEmpty ? widget.points.first : DemoSeed.mapCenter;
    final translateHitPolygon = _translateHitPolygon();
    final mapInteractionFlags =
        widget.activeTool == FenceEditTool.moveVertex ||
                widget.activeTool == FenceEditTool.translate
            ? InteractiveFlag.none
            : InteractiveFlag.all;

    return Positioned.fill(
      child: Container(
        key: const Key('fence-edit-overlay'),
        color: AppColors.surface,
        child: Stack(
          children: [
            Container(
              key: _gestureKey,
              color: Colors.transparent,
              child: FlutterMap(
                key: const Key('fence-edit-map'),
                mapController: widget.mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 16,
                  interactionOptions: InteractionOptions(
                    flags: mapInteractionFlags,
                  ),
                  onTap: widget.isInteractive &&
                          widget.activeTool == FenceEditTool.insertVertex
                      ? _handleMapTapInsert
                      : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapConfig.tileUrlTemplate,
                    userAgentPackageName: 'com.smartlivestock.demo',
                    maxZoom: MapConfig.cacheMaxZoom.toDouble(),
                  ),
                  if (widget.points.length >= 3)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: widget.points,
                          color: AppColors.primary.withValues(alpha: 0.22),
                          borderColor: AppColors.primary,
                          borderStrokeWidth: 2.5,
                        ),
                      ],
                    ),
                  if (widget.points.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [...widget.points, widget.points.first],
                          color: AppColors.primary,
                          strokeWidth: 2.5,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      for (var i = 0; i < widget.points.length; i++)
                        Marker(
                          key: Key('fence-edit-vertex-marker-$i'),
                          point: widget.points[i],
                          width: 88,
                          height: 88,
                          alignment: Alignment.center,
                          child: GestureDetector(
                            key: Key('fence-edit-vertex-$i'),
                            behavior: HitTestBehavior.opaque,
                            onTap: widget.isInteractive
                                ? () {
                                    if (widget.activeTool ==
                                        FenceEditTool.deleteVertex) {
                                      widget.onRemoveVertex(i);
                                    }
                                  }
                                : null,
                            onPanStart: widget.isInteractive &&
                                    widget.activeTool ==
                                        FenceEditTool.moveVertex
                                ? (_) {
                                    setState(() => _draggingVertexIndex = i);
                                  }
                                : null,
                            onPanUpdate: widget.isInteractive &&
                                    widget.activeTool ==
                                        FenceEditTool.moveVertex
                                ? (details) {
                                    if (_draggingVertexIndex != i) {
                                      return;
                                    }
                                    _handleVertexPanUpdate(
                                      i,
                                      details.globalPosition,
                                    );
                                  }
                                : null,
                            onPanEnd: widget.isInteractive &&
                                    widget.activeTool ==
                                        FenceEditTool.moveVertex
                                ? (_) {
                                    setState(() => _draggingVertexIndex = null);
                                  }
                                : null,
                            onPanCancel: widget.isInteractive &&
                                    widget.activeTool ==
                                        FenceEditTool.moveVertex
                                ? () {
                                    setState(() => _draggingVertexIndex = null);
                                  }
                                : null,
                            child: Center(
                              child: _VertexHandle(
                                highlight: widget.activeTool ==
                                        FenceEditTool.moveVertex ||
                                    widget.activeTool ==
                                        FenceEditTool.deleteVertex,
                                selected: false,
                                dimmed: false,
                              ),
                            ),
                          ),
                        ),
                      if (widget.activeTool == FenceEditTool.insertVertex)
                        for (var i = 0; i < widget.points.length; i++)
                          Marker(
                            key: Key('fence-edit-edge-marker-$i'),
                            point: _midPointForEdge(i),
                            width: 28,
                            height: 28,
                            child: GestureDetector(
                              key: Key('fence-edit-edge-$i'),
                              behavior: HitTestBehavior.opaque,
                              onTap: widget.isInteractive
                                  ? () => widget.onInsertVertex(i, _midPointForEdge(i))
                                  : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 4),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.isInteractive &&
                widget.activeTool == FenceEditTool.translate &&
                translateHitPolygon.length >= 3)
              Positioned.fill(
                child: ClipPath(
                  clipper: _PolygonClipper(translateHitPolygon),
                  child: GestureDetector(
                    key: const Key('fence-edit-translate-hit-area'),
                    behavior: HitTestBehavior.opaque,
                    onPanStart: _handlePanStart,
                    onPanUpdate: _handlePanUpdate,
                    onPanEnd: (_) => _lastTranslateOffset = null,
                    onPanCancel: () => _lastTranslateOffset = null,
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleMapTapInsert(TapPosition tapPosition, LatLng _) {
    if (!widget.isInteractive ||
        widget.activeTool != FenceEditTool.insertVertex) {
      return;
    }
    final local = tapPosition.relative;
    if (local == null) {
      return;
    }
    final edgeHit = _findNearestEdge(local);
    if (edgeHit == null || edgeHit.distance > _edgeHitThreshold) {
      return;
    }
    final insertPoint = _latLngFromLocal(local);
    if (insertPoint == null) {
      return;
    }
    widget.onInsertVertex(edgeHit.edgeStartIndex, insertPoint);
  }

  void _handlePanStart(DragStartDetails details) {
    if (widget.activeTool == FenceEditTool.translate) {
      _lastTranslateOffset = details.localPosition;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (widget.activeTool != FenceEditTool.translate) {
      return;
    }
    final previous = _lastTranslateOffset;
    final current = details.localPosition;
    if (previous == null) {
      _lastTranslateOffset = current;
      return;
    }
    final previousLatLng = _latLngFromLocal(previous);
    final currentLatLng = _latLngFromLocal(current);
    if (previousLatLng == null || currentLatLng == null) {
      _lastTranslateOffset = current;
      return;
    }
    widget.onTranslate(
      currentLatLng.latitude - previousLatLng.latitude,
      currentLatLng.longitude - previousLatLng.longitude,
    );
    _lastTranslateOffset = current;
  }

  void _handleVertexPanUpdate(int vertexIndex, Offset globalPosition) {
    final nextPoint = _latLngFromGlobal(globalPosition);
    if (nextPoint == null) {
      return;
    }
    widget.onMoveVertex(vertexIndex, nextPoint);
  }

  LatLng? _latLngFromGlobal(Offset globalPosition) {
    final context = _gestureKey.currentContext;
    if (context == null) {
      return null;
    }
    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox) {
      return null;
    }
    return _latLngFromLocal(renderBox.globalToLocal(globalPosition));
  }

  LatLng? _latLngFromLocal(Offset localPosition) {
    try {
      final camera = widget.mapController.camera;
      if (camera.size.width == 0 || camera.size.height == 0) {
        return null;
      }
      return camera.screenOffsetToLatLng(localPosition);
    } catch (_) {
      return null;
    }
  }

  _EdgeHit? _findNearestEdge(Offset localPosition) {
    if (widget.points.length < 2) {
      return null;
    }

    _EdgeHit? best;
    for (var i = 0; i < widget.points.length; i++) {
      final start = _offsetForPoint(widget.points[i]);
      final end = _offsetForPoint(widget.points[(i + 1) % widget.points.length]);
      if (start == null || end == null) {
        continue;
      }
      final distance = _distanceToSegment(localPosition, start, end);
      if (best == null || distance < best.distance) {
        best = _EdgeHit(edgeStartIndex: i, distance: distance);
      }
    }
    return best;
  }

  Offset? _offsetForPoint(LatLng point) {
    try {
      final offset = widget.mapController.camera.latLngToScreenOffset(point);
      return Offset(
        (offset.dx as num).toDouble(),
        (offset.dy as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  List<Offset> _translateHitPolygon() {
    final offsets = <Offset>[];
    for (final point in widget.points) {
      final offset = _offsetForPoint(point);
      if (offset == null) {
        return const [];
      }
      offsets.add(offset);
    }
    return offsets;
  }

  LatLng _midPointForEdge(int edgeStartIndex) {
    final start = widget.points[edgeStartIndex];
    final end = widget.points[(edgeStartIndex + 1) % widget.points.length];
    return LatLng(
      (start.latitude + end.latitude) / 2,
      (start.longitude + end.longitude) / 2,
    );
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    if (dx == 0 && dy == 0) {
      return (point - start).distance;
    }

    final t = (((point.dx - start.dx) * dx) + ((point.dy - start.dy) * dy)) /
        ((dx * dx) + (dy * dy));
    final clampedT = t.clamp(0.0, 1.0);
    final projection = Offset(
      start.dx + dx * clampedT,
      start.dy + dy * clampedT,
    );
    return (point - projection).distance;
  }
}

class _VertexHandle extends StatelessWidget {
  const _VertexHandle({
    required this.highlight,
    this.selected = false,
    this.dimmed = false,
  });

  static const double _outerDiameter = 44;

  final bool highlight;
  final bool selected;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final effectiveHighlight = highlight && !dimmed;
    final outerColor = selected || effectiveHighlight
        ? AppColors.primary
        : Colors.white;
    const borderColor = AppColors.primary;
    final innerColor = selected || effectiveHighlight
        ? Colors.white
        : AppColors.primary;
    const borderWidth = 2.0;
    const innerDot = 10.0;

    return SizedBox(
      width: _outerDiameter,
      height: _outerDiameter,
      child: Container(
        decoration: BoxDecoration(
          color: outerColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: innerDot,
            height: innerDot,
            decoration: BoxDecoration(
              color: innerColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _EdgeHit {
  const _EdgeHit({
    required this.edgeStartIndex,
    required this.distance,
  });

  final int edgeStartIndex;
  final double distance;
}

class _PolygonClipper extends CustomClipper<ui.Path> {
  const _PolygonClipper(this.points);

  final List<Offset> points;

  @override
  ui.Path getClip(Size size) {
    final path = ui.Path();
    if (points.length < 3) {
      return path;
    }
    path.addPolygon(points, true);
    return path;
  }

  @override
  bool shouldReclip(covariant _PolygonClipper oldClipper) {
    if (oldClipper.points.length != points.length) {
      return true;
    }
    for (var i = 0; i < points.length; i++) {
      if (oldClipper.points[i] != points[i]) {
        return true;
      }
    }
    return false;
  }
}
