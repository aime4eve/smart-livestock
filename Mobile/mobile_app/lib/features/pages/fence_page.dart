import 'dart:math' show min;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/api/api_role.dart';
import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/data/generators/gps_trajectory_generator.dart';
import 'package:smart_livestock_demo/core/map/map_config.dart';
import 'package:smart_livestock_demo/core/mock/mock_config.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/permissions/role_permission.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_edit_session.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_state.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_hit_detection.dart';
import 'package:smart_livestock_demo/features/fence/presentation/widgets/fence_candidate_sheet.dart';
import 'package:smart_livestock_demo/features/fence/presentation/widgets/fence_edit_toolbar.dart';
import 'package:smart_livestock_demo/features/fence/presentation/widgets/fence_mini_title_bar.dart';
import 'package:smart_livestock_demo/features/fence/presentation/widgets/fence_unsaved_dialog.dart';

class FencePage extends ConsumerStatefulWidget {
  const FencePage({super.key});

  @override
  ConsumerState<FencePage> createState() => _FencePageState();
}

class _FencePageState extends ConsumerState<FencePage>
    with TickerProviderStateMixin {
  final _mapController = MapController();
  final _trajectoryGenerator = GpsTrajectoryGenerator(seed: 42);
  final _gestureKey = GlobalKey();
  bool _panelOpen = false;

  late final AnimationController _breathingController;

  int _activePointerCount = 0;
  bool _isMultiTouch = false;
  int? _draggingVertexIndex;
  Offset? _lastTranslateOffset;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fenceState = ref.watch(fenceControllerProvider);
    final role = ref.watch(sessionControllerProvider).role!;
    final canManage = RolePermission.canEditFence(role);
    final isEditing = fenceState.editSession != null;

    if (fenceState.selectedFenceId != null && !isEditing) {
      if (!_breathingController.isAnimating) {
        _breathingController.repeat(reverse: true);
      }
    } else {
      if (_breathingController.isAnimating) {
        _breathingController.stop();
        _breathingController.value = 0;
      }
    }

    return PopScope<void>(
      canPop: !isEditing,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handlePagePop(context);
      },
      child: Scaffold(
        key: const Key('page-fence'),
        appBar: isEditing
            ? null
            : AppBar(title: const Text(MockConfig.ranchName)),
        body: _buildBody(
          context,
          fenceState,
          ref.read(fenceControllerProvider.notifier),
          canManage,
          ref.watch(appModeProvider),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    FenceState fenceState,
    FenceController controller,
    bool canManage,
    AppMode appMode,
  ) {
    switch (fenceState.viewState) {
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.error:
      case ViewState.forbidden:
      case ViewState.offline:
        return Center(
          child: Text(
            fenceState.message ?? '围栏不可用',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      case ViewState.normal:
      case ViewState.empty:
        return _buildMap(
          context, fenceState, controller, canManage, appMode,
        );
    }
  }

  Widget _buildMap(
    BuildContext context,
    FenceState fenceState,
    FenceController controller,
    bool canManage,
    AppMode appMode,
  ) {
    const panelAnimDuration = Duration(milliseconds: 280);
    const panelCurve = Curves.easeOutCubic;
    final editSession = fenceState.editSession;
    final isEditing = editSession != null;
    final isSaving = fenceState.editMode == FenceEditMode.saving;
    final selectedFenceId = fenceState.selectedFenceId;

    return LayoutBuilder(
      builder: (context, constraints) {
        final panelW = min(300.0, constraints.maxWidth * 0.82);
        final mockTrajectoryPoints = appMode.isMock
            ? _buildMockTrajectoryPoints(fenceState)
            : const <LatLng>[];

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                child: Stack(
                  children: [
                    Container(
                      key: _gestureKey,
                      child: FlutterMap(
                        key: const Key('fence-map'),
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: DemoSeed.mapCenter,
                          initialZoom: DemoSeed.defaultZoom,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all,
                          ),
                          onTap: isEditing
                              ? (editSession.tool ==
                                      FenceEditTool.insertVertex
                                  ? (tapPos, _) =>
                                      _handleEditMapTapInsert(
                                        tapPos, editSession, controller,
                                      )
                                  : null)
                              : (tapPosition, point) =>
                                  _handleMapTap(
                                    tapPosition,
                                    point,
                                    fenceState,
                                    controller,
                                  ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: MapConfig.tileUrlTemplate,
                            userAgentPackageName:
                                'com.smartlivestock.demo',
                            maxZoom: MapConfig.cacheMaxZoom.toDouble(),
                          ),
                          if (!isEditing)
                            AnimatedBuilder(
                              animation: _breathingController,
                              builder: (context, _) => PolygonLayer(
                                polygons:
                                    _buildBrowsePolygons(fenceState),
                              ),
                            )
                          else
                            PolygonLayer(
                              polygons:
                                  _buildEditPolygons(editSession),
                            ),
                          if (!isEditing &&
                              editSession == null &&
                              appMode.isMock &&
                              mockTrajectoryPoints.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: mockTrajectoryPoints,
                                  color: AppColors.primary,
                                  strokeWidth: 3,
                                ),
                              ],
                            ),
                          if (!isEditing &&
                              appMode.isLive &&
                              ApiCache.instance.initialized &&
                              ApiCache.instance
                                  .mapTrajectoryPoints.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: [
                                    for (final p in ApiCache
                                        .instance.mapTrajectoryPoints)
                                      LatLng(
                                        (p['lat'] as num).toDouble(),
                                        (p['lng'] as num).toDouble(),
                                      ),
                                  ],
                                  color: AppColors.primary,
                                  strokeWidth: 3,
                                ),
                              ],
                            ),
                          if (isEditing &&
                              editSession.points.length >= 2)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: [
                                    ...editSession.points,
                                    editSession.points.first,
                                  ],
                                  color: AppColors.primary,
                                  strokeWidth: 2.5,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              if (!isEditing)
                                ..._buildLivestockMarkers(appMode),
                              if (!isEditing)
                                ..._buildFenceNameMarkers(fenceState),
                              if (isEditing)
                                ..._buildVertexMarkers(
                                  editSession, controller, isSaving,
                                ),
                              if (isEditing &&
                                  editSession.tool ==
                                      FenceEditTool.insertVertex)
                                ..._buildEdgeMidpointMarkers(
                                  editSession, controller, isSaving,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isEditing &&
                        !isSaving &&
                        editSession.tool == FenceEditTool.translate &&
                        editSession.points.length >= 3)
                      Positioned.fill(
                        child: ClipPath(
                          clipper:
                              _PolygonClipper(_translateHitPolygon(editSession)),
                          child: GestureDetector(
                            key: const Key(
                                'fence-edit-translate-hit-area'),
                            behavior: HitTestBehavior.opaque,
                            onPanStart: _handleTranslatePanStart,
                            onPanUpdate: _handleTranslatePanUpdate,
                            onPanEnd: (_) =>
                                _lastTranslateOffset = null,
                            onPanCancel: () =>
                                _lastTranslateOffset = null,
                            child: const ColoredBox(
                                color: Colors.transparent),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (isEditing)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: FenceMiniTitleBar(
                  fenceName: fenceState.selectedFence?.name ?? '',
                  onBack: () => _handleEditExit(context, controller),
                  onUndo: controller.undoEdit,
                  onRedo: controller.redoEdit,
                  canUndo: editSession.canUndo && !isSaving,
                  canRedo: editSession.canRedo && !isSaving,
                ),
              ),

            if (isEditing)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: FenceEditToolbar(
                  activeTool: editSession.tool,
                  onSave: () =>
                      _handleEditSave(context, controller, appMode),
                  canSave:
                      controller.canSaveSession(editSession),
                  canExit: !isSaving,
                  onExit: () =>
                      _handleEditExit(context, controller),
                  canSelectTool: !isSaving,
                  onSelectTool: controller.selectEditTool,
                ),
              ),

            if (!isEditing)
              AnimatedPositioned(
                duration: panelAnimDuration,
                curve: panelCurve,
                left: _panelOpen ? 0 : -panelW,
                top: 0,
                bottom: 0,
                width: panelW,
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black38,
                  color: Theme.of(context).colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(AppSpacing.lg),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SafeArea(
                    right: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '牧场 (${fenceState.fences.length})',
                                key: const Key('fence-drawer-title'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                              if (canManage)
                                IconButton(
                                  key: const Key('fence-add'),
                                  onPressed: () => context
                                      .push(AppRoute.fenceForm.path)
                                      .then((_) {
                                    if (appMode.isLive) {
                                      ref
                                          .read(fenceControllerProvider
                                              .notifier)
                                          .reloadFromRepository();
                                    }
                                  }),
                                  icon: const Icon(
                                      Icons.add_circle_outline),
                                  tooltip: '新建围栏',
                                ),
                            ],
                          ),
                          if (fenceState.fences.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xl,
                              ),
                              child: Center(
                                child: Text(
                                  '暂无围栏，打开菜单后点 + 创建',
                                  key: const Key('fence-empty-hint'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color:
                                            AppColors.textSecondary,
                                      ),
                                ),
                              ),
                            )
                          else
                            for (final fence in fenceState.fences)
                              _FenceCard(
                                fence: fence,
                                isSelected: fence.id ==
                                    fenceState.selectedFenceId,
                                canManage: canManage,
                                onTap: () {
                                  controller.select(fence.id);
                                  _mapController.move(
                                    _fenceCenter(fence.points),
                                    16.0,
                                  );
                                  setState(
                                      () => _panelOpen = false);
                                },
                                onEdit: () {
                                  controller.select(fence.id);
                                  controller
                                      .startEditing(fence.id);
                                  _mapController.move(
                                    _fenceCenter(fence.points),
                                    16.0,
                                  );
                                  setState(
                                      () => _panelOpen = false);
                                },
                                onDelete: () =>
                                    _showDeleteDialog(
                                  context,
                                  fence,
                                  controller,
                                  appMode,
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            if (!isEditing)
              AnimatedPositioned(
                duration: panelAnimDuration,
                curve: panelCurve,
                left: _panelOpen ? panelW + 12 : 12,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: FloatingActionButton.small(
                    key: const Key('fence-panel-toggle'),
                    heroTag: 'fence-panel-toggle',
                    onPressed: () =>
                        setState(() => _panelOpen = !_panelOpen),
                    tooltip:
                        _panelOpen ? '收起牧场列表' : '牧场列表',
                    child: Icon(_panelOpen
                        ? Icons.chevron_left
                        : Icons.menu),
                  ),
                ),
              ),

            if (!isEditing &&
                canManage &&
                fenceState.fences.isNotEmpty)
              Positioned(
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: FloatingActionButton.extended(
                  key: const Key('fence-start-edit'),
                  heroTag: 'fence-start-edit',
                  onPressed: () {
                    if (selectedFenceId == null) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('请先选择一个牧场'),
                          ),
                        );
                      return;
                    }
                    controller.startEditing(selectedFenceId);
                    setState(() => _panelOpen = false);
                  },
                  icon: const Icon(
                      Icons.edit_location_alt_outlined),
                  label: const Text('编辑边界'),
                ),
              ),
          ],
        );
      },
    );
  }

  List<Polygon> _buildBrowsePolygons(FenceState fenceState) {
    final t = _breathingController.value;
    final hasSelection = fenceState.selectedFenceId != null;
    return fenceState.fences.map((fence) {
      final color = Color(fence.colorValue);
      final selected = fence.id == fenceState.selectedFenceId;
      if (selected) {
        return Polygon(
          points: fence.points,
          color: color.withValues(alpha: 0.3 + 0.1 * t),
          borderColor: color,
          borderStrokeWidth: 3.0 + 1.5 * t,
        );
      }
      return Polygon(
        points: fence.points,
        color: color.withValues(alpha: hasSelection ? 0.08 : 0.15),
        borderColor:
            hasSelection ? color.withValues(alpha: 0.4) : color,
        borderStrokeWidth: hasSelection ? 1.5 : 2.0,
      );
    }).toList();
  }

  List<Polygon> _buildEditPolygons(FenceEditSession editSession) {
    if (editSession.points.length < 3) return const [];
    return [
      Polygon(
        points: editSession.points,
        color: AppColors.primary.withValues(alpha: 0.22),
        borderColor: AppColors.primary,
        borderStrokeWidth: 2.5,
      ),
    ];
  }

  List<Marker> _buildVertexMarkers(
    FenceEditSession editSession,
    FenceController controller,
    bool isSaving,
  ) {
    final isInteractive = !isSaving;
    return [
      for (var i = 0; i < editSession.points.length; i++)
        Marker(
          key: Key('fence-edit-vertex-marker-$i'),
          point: editSession.points[i],
          width: 88,
          height: 88,
          alignment: Alignment.center,
          child: GestureDetector(
            key: Key('fence-edit-vertex-$i'),
            behavior: HitTestBehavior.opaque,
            onTap: isInteractive
                ? () {
                    if (editSession.tool == FenceEditTool.deleteVertex) {
                      _handleRemoveVertex(
                        context, controller, editSession, i,
                      );
                    }
                  }
                : null,
            onPanStart: isInteractive &&
                    editSession.tool == FenceEditTool.moveVertex
                ? (_) {
                    if (_isMultiTouch) return;
                    setState(() => _draggingVertexIndex = i);
                  }
                : null,
            onPanUpdate: isInteractive &&
                    editSession.tool == FenceEditTool.moveVertex
                ? (details) {
                    if (_isMultiTouch || _draggingVertexIndex != i) {
                      return;
                    }
                    _handleVertexPanUpdate(i, details.globalPosition, controller);
                  }
                : null,
            onPanEnd: isInteractive &&
                    editSession.tool == FenceEditTool.moveVertex
                ? (_) {
                    setState(() => _draggingVertexIndex = null);
                  }
                : null,
            onPanCancel: isInteractive &&
                    editSession.tool == FenceEditTool.moveVertex
                ? () {
                    setState(() => _draggingVertexIndex = null);
                  }
                : null,
            child: Center(
              child: _VertexHandle(
                highlight:
                    editSession.tool == FenceEditTool.moveVertex ||
                        editSession.tool == FenceEditTool.deleteVertex,
              ),
            ),
          ),
        ),
    ];
  }

  List<Marker> _buildEdgeMidpointMarkers(
    FenceEditSession editSession,
    FenceController controller,
    bool isSaving,
  ) {
    return [
      for (var i = 0; i < editSession.points.length; i++)
        Marker(
          key: Key('fence-edit-edge-marker-$i'),
          point: _midPointForEdge(editSession.points, i),
          width: 28,
          height: 28,
          child: GestureDetector(
            key: Key('fence-edit-edge-$i'),
            behavior: HitTestBehavior.opaque,
            onTap: !isSaving
                ? () => controller.insertDraftVertex(
                      i,
                      _midPointForEdge(editSession.points, i),
                    )
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
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
          ),
        ),
    ];
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointerCount++;
    if (_activePointerCount >= 2) {
      _isMultiTouch = true;
      if (_draggingVertexIndex != null || _lastTranslateOffset != null) {
        setState(() {
          _draggingVertexIndex = null;
          _lastTranslateOffset = null;
        });
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointerCount--;
    if (_activePointerCount <= 0) {
      _activePointerCount = 0;
      _isMultiTouch = false;
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointerCount--;
    if (_activePointerCount <= 0) {
      _activePointerCount = 0;
      _isMultiTouch = false;
    }
  }

  void _handleMapTap(
    TapPosition tapPosition,
    LatLng point,
    FenceState fenceState,
    FenceController controller,
  ) {
    final screenPoint = tapPosition.relative;
    if (screenPoint == null) return;
    final camera = _mapController.camera;

    Offset project(LatLng ll) {
      final p = camera.latLngToScreenOffset(ll);
      return Offset((p.dx as num).toDouble(), (p.dy as num).toDouble());
    }

    final hits = detectFenceHits(
      tapScreenPoint: screenPoint,
      tapLatLng: point,
      fences: fenceState.fences,
      project: project,
    );

    if (hits.isEmpty) {
      controller.select(null);
      return;
    }

    if (hits.length == 1) {
      controller.select(hits.first.fenceId);
      return;
    }

    final candidates = <FenceItem>[];
    for (final hit in hits) {
      for (final fence in fenceState.fences) {
        if (fence.id == hit.fenceId) {
          candidates.add(fence);
          break;
        }
      }
    }
    showFenceCandidateSheet(context, candidates).then((selectedId) {
      if (selectedId != null) {
        controller.select(selectedId);
      }
    });
  }

  void _handleEditMapTapInsert(
    TapPosition tapPosition,
    FenceEditSession editSession,
    FenceController controller,
  ) {
    final local = tapPosition.relative;
    if (local == null) return;
    final edgeHit = _findNearestEdge(local, editSession.points);
    if (edgeHit == null || edgeHit.distance > 24.0) return;
    final insertPoint = _latLngFromLocal(local);
    if (insertPoint == null) return;
    controller.insertDraftVertex(edgeHit.edgeStartIndex, insertPoint);
  }

  void _handleVertexPanUpdate(
    int vertexIndex,
    Offset globalPosition,
    FenceController controller,
  ) {
    final context = _gestureKey.currentContext;
    if (context == null) return;
    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox) return;
    final local = renderBox.globalToLocal(globalPosition);
    final nextPoint = _latLngFromLocal(local);
    if (nextPoint == null) return;
    controller.moveDraftVertex(vertexIndex, nextPoint);
  }

  void _handleTranslatePanStart(DragStartDetails details) {
    if (_isMultiTouch) return;
    _lastTranslateOffset = details.localPosition;
  }

  void _handleTranslatePanUpdate(DragUpdateDetails details) {
    if (_isMultiTouch) {
      _lastTranslateOffset = null;
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
    ref.read(fenceControllerProvider.notifier).translateDraft(
          currentLatLng.latitude - previousLatLng.latitude,
          currentLatLng.longitude - previousLatLng.longitude,
        );
    _lastTranslateOffset = current;
  }

  LatLng? _latLngFromLocal(Offset localPosition) {
    try {
      final camera = _mapController.camera;
      if (camera.size.width == 0 || camera.size.height == 0) return null;
      return camera.screenOffsetToLatLng(localPosition);
    } catch (_) {
      return null;
    }
  }

  Offset? _offsetForPoint(LatLng point) {
    try {
      final offset = _mapController.camera.latLngToScreenOffset(point);
      return Offset(
        (offset.dx as num).toDouble(),
        (offset.dy as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  _EdgeHit? _findNearestEdge(Offset localPosition, List<LatLng> points) {
    if (points.length < 2) return null;
    _EdgeHit? best;
    for (var i = 0; i < points.length; i++) {
      final start = _offsetForPoint(points[i]);
      final end = _offsetForPoint(points[(i + 1) % points.length]);
      if (start == null || end == null) continue;
      final d = distanceToSegment(localPosition, start, end);
      if (best == null || d < best.distance) {
        best = _EdgeHit(edgeStartIndex: i, distance: d);
      }
    }
    return best;
  }

  List<Offset> _translateHitPolygon(FenceEditSession editSession) {
    final offsets = <Offset>[];
    for (final point in editSession.points) {
      final offset = _offsetForPoint(point);
      if (offset == null) return const [];
      offsets.add(offset);
    }
    return offsets;
  }

  static LatLng _midPointForEdge(List<LatLng> points, int edgeStartIndex) {
    final start = points[edgeStartIndex];
    final end = points[(edgeStartIndex + 1) % points.length];
    return LatLng(
      (start.latitude + end.latitude) / 2,
      (start.longitude + end.longitude) / 2,
    );
  }

  LatLng _fenceCenter(List<LatLng> points) {
    double lat = 0, lng = 0;
    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  Future<void> _handleEditExit(
    BuildContext context,
    FenceController controller,
  ) async {
    final fenceState = ref.read(fenceControllerProvider);
    if (fenceState.editMode == FenceEditMode.saving) return;
    final hasChanges = fenceState.editSession?.hasChanges ?? false;
    if (!hasChanges) {
      controller.cancelEditing();
      if (mounted) setState(() => _panelOpen = true);
      return;
    }
    final action = await showFenceUnsavedDialog(context);
    if (!context.mounted || action == null) return;
    switch (action) {
      case FenceUnsavedAction.save:
        await _handleEditSave(
          context, controller, ref.read(appModeProvider),
        );
        return;
      case FenceUnsavedAction.discard:
        controller.discardEditing();
        setState(() => _panelOpen = true);
        return;
      case FenceUnsavedAction.continueEditing:
        return;
    }
  }

  Future<void> _handleEditSave(
    BuildContext context,
    FenceController controller,
    AppMode appMode,
  ) async {
    final session = ref.read(fenceControllerProvider).editSession;
    if (session == null || !session.hasChanges) return;
    final geometryError =
        FenceController.validateDraftGeometry(session.points);
    if (geometryError != null) {
      _showSnackBar(context, geometryError);
      return;
    }
    if (appMode.isMock) {
      controller.saveEditing();
      if (mounted) setState(() => _panelOpen = true);
      return;
    }
    final sessionInstanceId = session.sessionInstanceId;
    final fenceId = session.fenceId;
    controller.markSavingEdit();
    final ok = await ApiCache.instance.updateFenceRemote(
      apiRoleFromEnvironment,
      fenceId,
      {
        'coordinates': [
          for (final point in session.points)
            [point.longitude, point.latitude],
        ],
      },
    );
    if (!ok) {
      final restored =
          controller.restoreEditingAfterSaveFailureIfCurrent(
        sessionInstanceId: sessionInstanceId,
        fenceId: fenceId,
      );
      if (restored && context.mounted) {
        _showSnackBar(
          context,
          fenceSaveErrorMessageForStatusCode(
            ApiCache.instance.lastFenceSaveStatusCode,
          ),
        );
      }
      return;
    }
    final saved = controller.saveEditingIfCurrent(
      sessionInstanceId: sessionInstanceId,
      fenceId: fenceId,
    );
    if (!saved) return;
    await ApiCache.instance
        .refreshFencesAndMap(apiRoleFromEnvironment);
    controller.reloadFromRepository();
    if (context.mounted) setState(() => _panelOpen = true);
  }

  Future<void> _handlePagePop(BuildContext context) async {
    final fenceState = ref.read(fenceControllerProvider);
    final controller = ref.read(fenceControllerProvider.notifier);
    if (fenceState.editSession == null ||
        fenceState.editMode == FenceEditMode.saving) {
      return;
    }
    await _handleEditExit(context, controller);
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleRemoveVertex(
    BuildContext context,
    FenceController controller,
    FenceEditSession editSession,
    int vertexIndex,
  ) {
    if (editSession.points.length <= 3) {
      _showSnackBar(context, '边界至少保留 3 个点');
      return;
    }
    controller.removeDraftVertex(vertexIndex);
  }

  List<Marker> _buildFenceNameMarkers(FenceState fenceState) {
    return [
      for (final fence in fenceState.fences)
        if (fence.points.isNotEmpty)
          Marker(
            key: Key('fence-map-name-${fence.id}'),
            point: _fenceCenter(fence.points),
            width: 140,
            height: 40,
            alignment: Alignment.center,
            child: _FenceMapNameChip(
              name: fence.name,
              colorValue: fence.colorValue,
              selected: fence.id == fenceState.selectedFenceId,
            ),
          ),
    ];
  }

  List<Marker> _buildLivestockMarkers(AppMode appMode) {
    if (appMode.isMock) {
      return [
        for (int i = 0; i < DemoSeed.livestockLocations.length; i++)
          Marker(
            key: Key('fence-map-marker-$i'),
            point: DemoSeed.livestockLocations[i].toLatLng(),
            width: 56,
            height: 56,
            child: _MapMarker(
              label: DemoSeed
                  .earTags[i < DemoSeed.earTags.length ? i : 0],
              isAlert: i == 0,
            ),
          ),
      ];
    }
    if (!ApiCache.instance.initialized ||
        ApiCache.instance.animals.isEmpty) {
      return [
        for (int i = 0; i < DemoSeed.livestockLocations.length; i++)
          Marker(
            key: Key('fence-map-marker-fallback-$i'),
            point: DemoSeed.livestockLocations[i].toLatLng(),
            width: 56,
            height: 56,
            child: _MapMarker(
              label: DemoSeed
                  .earTags[i < DemoSeed.earTags.length ? i : 0],
              isAlert: i == 0,
            ),
          ),
      ];
    }
    final animals = ApiCache.instance.animals;
    return [
      for (var i = 0; i < animals.length; i++)
        Marker(
          key: Key('fence-map-marker-$i'),
          point: LatLng(
            (animals[i]['lat'] as num).toDouble(),
            (animals[i]['lng'] as num).toDouble(),
          ),
          width: 56,
          height: 56,
          child: _MapMarker(
            label: animals[i]['earTag'] as String? ?? '-',
            isAlert: animals[i]['boundaryStatus'] == 'outside',
          ),
        ),
    ];
  }

  List<LatLng> _buildMockTrajectoryPoints(FenceState fenceState) {
    final selectedFenceId =
        fenceState.selectedFenceId ?? 'fence_pasture_a';
    List<LatLng>? boundary;
    for (final fence in fenceState.fences) {
      if (fence.id == selectedFenceId) {
        boundary = fence.points;
        break;
      }
    }
    if (boundary == null || boundary.length < 2) return const [];
    String? earTag;
    for (final livestock in DemoSeed.livestock) {
      if (livestock.fenceId == selectedFenceId) {
        earTag = livestock.earTag;
        break;
      }
    }
    final activeEarTag = earTag ?? DemoSeed.earTags.first;
    final restFence = DemoSeed.fencePointsById('fence_rest');
    final points = _trajectoryGenerator.generate(
      earTag: activeEarTag,
      fenceBoundary: boundary,
      restFenceBoundary: restFence.isEmpty ? null : restFence,
      anchorPoints: DemoSeed.gpsAnchorPoints,
      start: DateTime.utc(2026, 4, 7, 10),
      end: DateTime.utc(2026, 4, 8, 10),
    );
    return points.map((p) => p.toLatLng()).toList();
  }

  void _showDeleteDialog(
    BuildContext context,
    FenceItem fence,
    FenceController controller,
    AppMode appMode,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确认删除「${fence.name}」？删除后无法恢复。'),
        actions: [
          TextButton(
            key: const Key('fence-delete-cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            key: const Key('fence-delete-confirm'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (appMode.isLive) {
                final ok = await ApiCache.instance.deleteFenceRemote(
                    apiRoleFromEnvironment, fence.id);
                if (!context.mounted) return;
                if (ok) {
                  await ApiCache.instance
                      .refreshFencesAndMap(apiRoleFromEnvironment);
                  if (!context.mounted) return;
                  controller.reloadFromRepository();
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                          content: Text('已删除「${fence.name}」')),
                    );
                } else {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                          content: Text('删除失败，请稍后重试')),
                    );
                }
              } else {
                controller.delete(fence.id);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text('已删除「${fence.name}」')),
                  );
              }
            },
            child: const Text('删除',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _VertexHandle extends StatelessWidget {
  const _VertexHandle({required this.highlight});

  static const double _outerDiameter = 44;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final outerColor = highlight ? AppColors.primary : Colors.white;
    const borderColor = AppColors.primary;
    final innerColor = highlight ? Colors.white : AppColors.primary;

    return SizedBox(
      width: _outerDiameter,
      height: _outerDiameter,
      child: Container(
        decoration: BoxDecoration(
          color: outerColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4),
          ],
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
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
  const _EdgeHit({required this.edgeStartIndex, required this.distance});
  final int edgeStartIndex;
  final double distance;
}

class _PolygonClipper extends CustomClipper<ui.Path> {
  const _PolygonClipper(this.points);
  final List<Offset> points;

  @override
  ui.Path getClip(Size size) {
    final path = ui.Path();
    if (points.length < 3) return path;
    path.addPolygon(points, true);
    return path;
  }

  @override
  bool shouldReclip(covariant _PolygonClipper oldClipper) {
    if (oldClipper.points.length != points.length) return true;
    for (var i = 0; i < points.length; i++) {
      if (oldClipper.points[i] != points[i]) return true;
    }
    return false;
  }
}

class _FenceCard extends StatelessWidget {
  const _FenceCard({
    required this.fence,
    required this.isSelected,
    required this.canManage,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final FenceItem fence;
  final bool isSelected;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('fence-card-${fence.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        side: isSelected
            ? BorderSide(color: Color(fence.colorValue), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(fence.colorValue),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fence.name,
                      style:
                          Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _StatusLabel(active: fence.active),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${fence.livestockCount}头',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canManage) ...[
                IconButton(
                  key: Key('fence-edit-${fence.id}'),
                  onPressed: onEdit,
                  icon:
                      const Icon(Icons.edit_outlined, size: 20),
                  tooltip: '编辑',
                ),
                IconButton(
                  key: Key('fence-delete-${fence.id}'),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      size: 20),
                  tooltip: '删除',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.textSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        active ? '启用' : '停用',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: active
                  ? AppColors.success
                  : AppColors.textSecondary,
              fontSize: 11,
            ),
      ),
    );
  }
}

class _FenceMapNameChip extends StatelessWidget {
  const _FenceMapNameChip({
    required this.name,
    required this.colorValue,
    required this.selected,
  });

  final String name;
  final int colorValue;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final accent = Color(colorValue);
    return IgnorePointer(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 132),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            border: Border.all(
              color: selected ? accent : accent.withValues(alpha: 0.45),
              width: selected ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 3),
            ],
          ),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.label, this.isAlert = false});

  final String label;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final color = isAlert ? AppColors.danger : AppColors.success;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.pets,
                color: Colors.white, size: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 2),
              ],
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
