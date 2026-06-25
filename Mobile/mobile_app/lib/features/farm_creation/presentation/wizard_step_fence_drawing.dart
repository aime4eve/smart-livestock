import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/map/coord_transform.dart';
import 'package:hkt_livestock_agentic/core/map/map_config.dart';
import 'package:hkt_livestock_agentic/core/map/mbtiles_tile_provider.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/fence_edit_operations.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/fence_edit_session.dart';

/// Wizard Step 2 — 围栏绘制
///
/// Uses [FenceEditSession] + [FenceEditOperations] for vertex management.
/// Vertex operations follow the ordering constraint:
/// - First vertex always added via [_addVertex] (never moveVertex on empty list)
/// - [FenceEditOperations.moveVertex] requires index < points.length
/// - [FenceEditOperations.removeVertex] requires >= 3 points
/// - [FenceEditOperations.insertVertex] requires >= 1 point
class WizardStepFenceDrawing extends ConsumerStatefulWidget {
  const WizardStepFenceDrawing({
    super.key,
    required this.farmId,
    required this.onComplete,
    required this.onSkip,
  });

  final String farmId;
  final void Function(int count) onComplete;
  final VoidCallback onSkip;

  @override
  ConsumerState<WizardStepFenceDrawing> createState() =>
      _WizardStepFenceDrawingState();
}

class _WizardStepFenceDrawingState
    extends ConsumerState<WizardStepFenceDrawing> {
  final _nameController = TextEditingController();
  final _mapController = MapController();
  final _formKey = GlobalKey<FormState>();
  late FenceEditSession _session;
  bool _saving = false;
  SmartTileProvider? _tileProvider;
  bool _tileProviderInitialized = false;

  @override
  void initState() {
    super.initState();
    _session = FenceEditSession(
      fenceId: 'draft',
      originalPoints: const [],
      points: const [],
    );
  }

  @override
  void dispose() {
    _tileProvider?.dispose();
    _nameController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initTileProvider() async {
    MBTilesTileProvider? mbtiles;
    if (!kIsWeb) {
      mbtiles = await MBTilesTileProvider.fromAsset();
    }
    const region = String.fromEnvironment('REGION', defaultValue: 'china');
    const isChina = region == 'china';
    _tileProvider = await SmartTileProvider.create(
      selfHostedTileUrl: null, // 新牧场尚无 region 瓦片，直接降级到通用底图
      mbtilesProvider: mbtiles,
      fallbackUrl: isChina ? MapConfig.chinaFallbackUrl : MapConfig.overseasFallbackUrl,
      isGcj02Fallback: isChina,
      onSourceChanged: () { if (mounted) setState(() {}); },
    );
    if (mounted) setState(() {});
  }

  /// Add a vertex to the session. Always safe to call regardless of point count.
  FenceEditSession _addVertex(FenceEditSession session, LatLng point) {
    final newPoints = [...session.points, point];
    return session.copyWith(
      points: newPoints,
      undoStack: [session.points, ...session.undoStack],
      redoStack: const [],
    );
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (!mounted) return;
    setState(() {
      _session = _addVertex(_session, point);
    });
  }

  void _onMarkerDrag(int index, LatLng point) {
    if (!mounted) return;
    // moveVertex requires valid index; only called when index < points.length
    if (index < _session.points.length) {
      setState(() {
        _session = FenceEditOperations.moveVertex(
          session: _session,
          vertexIndex: index,
          point: point,
        );
      });
    }
  }

  void _onMarkerLongPress(int index) {
    if (!mounted) return;
    // removeVertex refuses if <= 3 points, but we guard anyway
    if (_session.points.length > 3) {
      setState(() {
        _session = FenceEditOperations.removeVertex(
          session: _session,
          vertexIndex: index,
        );
      });
    }
  }

  void _undo() {
    if (!_session.canUndo || !mounted) return;
    setState(() {
      final previous = _session.undoStack.first;
      _session = _session.copyWith(
        points: previous,
        undoStack: _session.undoStack.skip(1).toList(),
        redoStack: [_session.points, ..._session.redoStack],
      );
    });
  }

  void _redo() {
    if (!_session.canRedo || !mounted) return;
    setState(() {
      final next = _session.redoStack.first;
      _session = _session.copyWith(
        points: next,
        redoStack: _session.redoStack.skip(1).toList(),
        undoStack: [_session.points, ..._session.undoStack],
      );
    });
  }

  /// When the tile source uses GCJ-02, vertices drawn on the map must be
  /// inverse-transformed to WGS-84 before storage.
  List<LatLng> _verticesForSave(List<LatLng> drawnVertices) {
    if (_tileProvider?.shouldTransformCoordinates() ?? false) {
      return CoordTransform.gcj02ToWgs84All(drawnVertices);
    }
    return drawnVertices;
  }

  Future<void> _saveFence() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_session.points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.wizardFenceMinVertices)),
      );
      return;
    }
    setState(() => _saving = true);

    final vertices = _verticesForSave(_session.points)
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList();

    final body = <String, dynamic>{
      'name': _nameController.text.trim(),
      'type': 'polygon',
      'vertices': vertices,
      'alarmEnabled': true,
    };

    try {
      await ApiClient.instance.farmPost('/fences', body: body, farmId: widget.farmId);
      if (!mounted) return;
      widget.onComplete(1);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fenceFormSaveFailed(e.toString()))),
      );
    }
  }

  List<Marker> _buildVertexMarkers() {
    return [
      for (var i = 0; i < _session.points.length; i++)
        Marker(
          key: Key('fence-wizard-vertex-$i'),
          point: _session.points[i],
          width: 36,
          height: 36,
          child: GestureDetector(
            onLongPress: () => _onMarkerLongPress(i),
            child: Draggable<LatLng>(
              data: _session.points[i],
              feedback: _buildMarkerChild(i, isDragging: true),
              childWhenDragging: _buildMarkerChild(i, isPlaceholder: true),
              child: _buildMarkerChild(i),
              onDragEnd: (details) {
                // Convert the global drag end position to a map coordinate
                final renderBox = context.findRenderObject() as RenderBox;
                final localOffset = renderBox.globalToLocal(
                  details.offset + const Offset(18, 18),
                );
                try {
                  final point = _mapController.camera.screenOffsetToLatLng(
                    localOffset,
                  );
                  _onMarkerDrag(i, point);
                } catch (_) {
                  // Ignore conversion failures
                }
              },
            ),
          ),
        ),
    ];
  }

  Widget _buildMarkerChild(int index,
      {bool isDragging = false, bool isPlaceholder = false}) {
    if (isPlaceholder) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 1),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: isDragging
            ? AppColors.accent
            : (index == 0 ? AppColors.primary : AppColors.primary.withValues(alpha: 0.8)),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String get _hintText {
    final count = _session.points.length;
    if (count == 0) return '点击地图添加围栏顶点（至少3个）';
    if (count < 3) return '已添加 $count 个顶点，还需 ${3 - count} 个';
    return '已添加 $count 个顶点 — 可继续添加，或输入名称后保存';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_tileProviderInitialized) {
      _tileProviderInitialized = true;
      _initTileProvider();
    }
    final points = _session.points;

    return SingleChildScrollView(
      key: const Key('fence-wizard-step2'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '绘制围栏',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '点击地图添加围栏顶点，拖拽顶点可调整位置，长按顶点可删除（需≥4个顶点）。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              key: const Key('fence-wizard-name'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '围栏名称',
                hintText: '例如：北草场围栏',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请输入围栏名称' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                IconButton(
                  key: const Key('fence-wizard-undo'),
                  onPressed: _session.canUndo ? _undo : null,
                  icon: const Icon(Icons.undo),
                  tooltip: '撤销',
                ),
                IconButton(
                  key: const Key('fence-wizard-redo'),
                  onPressed: _session.canRedo ? _redo : null,
                  icon: const Icon(Icons.redo),
                  tooltip: '重做',
                ),
                const Spacer(),
                Text(
                  '${points.length} 个顶点',
                  key: const Key('fence-wizard-vertex-count'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              child: SizedBox(
                key: const Key('fence-wizard-map'),
                height: 320,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: MapConfig.defaultCenter,
                    initialZoom: 14.0,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _tileProvider == null ? MapConfig.tileUrlTemplate : null,
                      tileProvider: _tileProvider,
                      userAgentPackageName: 'com.smartlivestock.demo',
                      maxZoom: MapConfig.cacheMaxZoom.toDouble(),
                    ),
                    if (points.length >= 3)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: points,
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderColor: AppColors.primary,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                    if (points.length >= 2 && points.length < 3)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: points,
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: _buildVertexMarkers(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _hintText,
              key: const Key('fence-wizard-hint'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: points.length >= 3
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              key: const Key('fence-wizard-save'),
              onPressed: _saving ? null : _saveFence,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.fenceFormSaveFence),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              key: const Key('fence-wizard-skip'),
              onPressed: widget.onSkip,
              child: Text(l10n.wizardSetupLater),
            ),
          ],
        ),
      ),
    );
  }
}
