import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/api/api_role.dart';
import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/map/map_config.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';

class FenceFormPage extends ConsumerStatefulWidget {
  const FenceFormPage({super.key, this.fenceId});

  final String? fenceId;

  @override
  ConsumerState<FenceFormPage> createState() => _FenceFormPageState();
}

class _FenceFormPageState extends ConsumerState<FenceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _formMapController = MapController();
  FenceType _type = FenceType.rectangle;
  bool _alarmEnabled = true;
  bool _active = true;
  bool _saving = false;
  bool _initialized = false;
  bool _drawMode = false;
  List<LatLng> _drawingPoints = [];
  LatLng? _dragStart;
  LatLng? _dragCurrent;
  LatLng? _cursorLatLng;
  Offset? _polygonPointerDownLocal;
  Duration? _polygonPointerDownTime;
  Offset? _lastPolygonCursorLocal;

  bool get _isEdit => widget.fenceId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _formMapController.dispose();
    super.dispose();
  }

  void _clearTransientGesture() {
    _dragStart = null;
    _dragCurrent = null;
    _cursorLatLng = null;
    _polygonPointerDownLocal = null;
    _polygonPointerDownTime = null;
    _lastPolygonCursorLocal = null;
  }

  void _initForEdit() {
    if (_initialized || !_isEdit) return;
    _initialized = true;
    final fenceState = ref.read(fenceControllerProvider);
    FenceItem? fence;
    for (final f in fenceState.fences) {
      if (f.id == widget.fenceId) {
        fence = f;
        break;
      }
    }
    if (fence == null) return;
    _nameController.text = fence.name;
    _type = fence.type;
    _alarmEnabled = fence.alarmEnabled;
    _active = fence.active;
    if (fence.type == FenceType.rectangle) {
      if (fence.points.length >= 4) {
        _drawingPoints = [fence.points[0], fence.points[2]];
      }
    } else if (fence.type == FenceType.circle) {
      if (fence.points.isNotEmpty) {
        final n = fence.points.length;
        double lat = 0, lng = 0;
        for (final p in fence.points) {
          lat += p.latitude;
          lng += p.longitude;
        }
        _drawingPoints = [LatLng(lat / n, lng / n), fence.points[0]];
      }
    } else {
      _drawingPoints = List.from(fence.points);
    }
  }

  List<LatLng> _getPreviewPoints() {
    if (_drawMode &&
        _dragStart != null &&
        _dragCurrent != null &&
        (_type == FenceType.rectangle || _type == FenceType.circle)) {
      return switch (_type) {
        FenceType.rectangle =>
          _buildRectanglePoints(_dragStart!, _dragCurrent!),
        FenceType.circle => _buildCirclePoints(_dragStart!, _dragCurrent!),
        FenceType.polygon => [],
      };
    }
    if (_drawingPoints.isEmpty) return [];
    return switch (_type) {
      FenceType.rectangle => _drawingPoints.length >= 2
          ? _buildRectanglePoints(_drawingPoints[0], _drawingPoints[1])
          : [],
      FenceType.circle => _drawingPoints.length >= 2
          ? _buildCirclePoints(_drawingPoints[0], _drawingPoints[1])
          : [],
      FenceType.polygon =>
        _drawingPoints.length >= 3 ? List.from(_drawingPoints) : [],
    };
  }

  List<LatLng> _buildRectanglePoints(LatLng p1, LatLng p2) {
    return [
      LatLng(p1.latitude, p1.longitude),
      LatLng(p1.latitude, p2.longitude),
      LatLng(p2.latitude, p2.longitude),
      LatLng(p2.latitude, p1.longitude),
    ];
  }

  List<LatLng> _buildCirclePoints(LatLng center, LatLng boundary) {
    final dLat = boundary.latitude - center.latitude;
    final dLng = boundary.longitude - center.longitude;
    final radius = sqrt(dLat * dLat + dLng * dLng);
    return [
      for (var i = 0; i < 12; i++)
        LatLng(
          center.latitude + radius * cos(i * pi / 6),
          center.longitude + radius * sin(i * pi / 6),
        ),
    ];
  }

  List<LatLng> _markerPoints() {
    if (_drawMode &&
        _dragStart != null &&
        _dragCurrent != null &&
        (_type == FenceType.rectangle || _type == FenceType.circle)) {
      return [_dragStart!, _dragCurrent!];
    }
    return _drawingPoints;
  }

  bool _isDrawingComplete() {
    return switch (_type) {
      FenceType.rectangle => _drawingPoints.length >= 2,
      FenceType.circle => _drawingPoints.length >= 2,
      FenceType.polygon => _drawingPoints.length >= 3,
    };
  }

  String _overlayBannerText() {
    if (!_drawMode) return '';
    return switch (_type) {
      FenceType.rectangle ||
      FenceType.circle =>
        _dragStart != null && _dragCurrent != null
            ? '松开鼠标或手指完成绘制'
            : '在地图上拖拽以画出范围',
      FenceType.polygon => _drawingPoints.length >= 3
          ? '可继续点击添加顶点，或点下方「完成绘制」结束'
          : '点击地图添加顶点（至少3个）',
    };
  }

  String _footerHintText() {
    if (!_drawMode) {
      return '点击地图右上角「开始绘制」后在地图上设置范围，或用手动录入';
    }
    return switch (_type) {
      FenceType.rectangle ||
      FenceType.circle =>
        '绘制模式：地图不可拖动；拖拽画出范围后松手完成',
      FenceType.polygon =>
        '绘制模式：点击添加顶点；移动指针可预览连线（多边形）',
    };
  }

  LatLng? _latLngFromLocal(Offset local) {
    try {
      final cam = _formMapController.camera;
      if (cam.size.width == 0 || cam.size.height == 0) return null;
      return cam.screenOffsetToLatLng(local);
    } catch (_) {
      return null;
    }
  }

  void _handleMapPointerDown(PointerDownEvent e) {
    if (!_drawMode || !mounted) return;
    if (_type == FenceType.polygon) {
      _polygonPointerDownLocal = e.localPosition;
      _polygonPointerDownTime = e.timeStamp;
      return;
    }
    final p = _latLngFromLocal(e.localPosition);
    if (p == null) return;
    if (!mounted) return;
    setState(() {
      _dragStart = p;
      _dragCurrent = p;
    });
  }

  void _handleMapPointerMove(PointerMoveEvent e) {
    if (!_drawMode || !mounted) return;
    final p = _latLngFromLocal(e.localPosition);
    if (p == null) return;
    if (_type == FenceType.polygon) {
      if (_drawingPoints.isNotEmpty) {
        final last = _lastPolygonCursorLocal;
        if (last != null && (e.localPosition - last).distance < 2.5) {
          return;
        }
        _lastPolygonCursorLocal = e.localPosition;
        if (!mounted) return;
        setState(() => _cursorLatLng = p);
      }
    } else if (_dragStart != null) {
      if (!mounted) return;
      setState(() => _dragCurrent = p);
    }
  }

  void _handleMapPointerUp(PointerUpEvent e) {
    if (!_drawMode || !mounted) return;
    if (_type == FenceType.polygon) {
      final down = _polygonPointerDownLocal;
      final downTs = _polygonPointerDownTime;
      _polygonPointerDownTime = null;
      if (down == null) return;
      final dist = (e.localPosition - down).distance;
      final held = downTs != null ? e.timeStamp - downTs : const Duration(days: 1);
      final tap = dist <= 88 ||
          (held <= const Duration(milliseconds: 400) && dist <= 130);
      if (!tap) {
        _polygonPointerDownLocal = null;
        return;
      }
      final p = _latLngFromLocal(e.localPosition);
      if (p == null) {
        _polygonPointerDownLocal = null;
        return;
      }
      _onPolygonTap(p);
      return;
    }
    final p = _latLngFromLocal(e.localPosition);
    if (p == null || _dragStart == null) return;
    const th = 1e-12;
    final dLat = p.latitude - _dragStart!.latitude;
    final dLng = p.longitude - _dragStart!.longitude;
    if (dLat * dLat + dLng * dLng < th) {
      setState(_clearTransientGesture);
      return;
    }
    setState(() {
      _drawingPoints = [_dragStart!, p];
      _clearTransientGesture();
    });
  }

  void _handleMapPointerCancel(PointerCancelEvent e) {
    if (!_drawMode || !mounted) return;
    if (_type == FenceType.polygon) {
      _polygonPointerDownLocal = null;
      _polygonPointerDownTime = null;
      return;
    }
    setState(_clearTransientGesture);
  }

  void _onPolygonTap(LatLng point) {
    if (!mounted) return;
    setState(() {
      _polygonPointerDownLocal = null;
      _polygonPointerDownTime = null;
      _drawingPoints = [..._drawingPoints, point];
    });
  }

  void _toggleDrawMode() {
    if (!mounted) return;
    setState(() {
      _drawMode = !_drawMode;
      _clearTransientGesture();
    });
  }

  void _finishPolygonDraw() {
    if (!mounted) return;
    setState(() {
      _drawMode = false;
      _cursorLatLng = null;
      _polygonPointerDownLocal = null;
      _polygonPointerDownTime = null;
    });
  }

  void _resetDrawing() {
    setState(() {
      _drawingPoints = [];
      _clearTransientGesture();
    });
  }

  double _calcAreaHectares() {
    final pts = _getPreviewPoints();
    if (pts.length < 3) return 1.0;
    double area = 0;
    final n = pts.length;
    for (var i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += pts[i].longitude * pts[j].latitude;
      area -= pts[j].longitude * pts[i].latitude;
    }
    final avgLat = pts.fold(0.0, (s, p) => s + p.latitude) / n;
    final cosLat = cos(avgLat * pi / 180);
    final areaM2 = (area.abs() / 2) * 111320 * 111320 * cosLat;
    final ha = areaM2 / 10000;
    if (!ha.isFinite) return 1.0;
    final clamped = ha.clamp(0.01, 99999);
    final parsed = double.tryParse(clamped.toStringAsFixed(2));
    return parsed ?? 1.0;
  }

  Future<void> _showManualEntryDialog(BuildContext context) async {
    final inputController = TextEditingController();
    final previewPoints = _getPreviewPoints();
    if (previewPoints.isNotEmpty) {
      inputController.text = previewPoints
          .map((p) =>
              '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}')
          .join('\n');
    }

    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('手动录入坐标'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _type == FenceType.rectangle
                      ? '请输入2个对角顶点（纬度,经度）'
                      : _type == FenceType.circle
                          ? '请输入圆心和边界点（纬度,经度），共2行'
                          : '请输入各顶点坐标（至少3个），每行一个',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  key: const Key('fence-form-manual-input'),
                  controller: inputController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: '28.234000,112.940000\n28.230000,112.944000',
                    errorText: errorText,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              key: const Key('fence-form-manual-cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              key: const Key('fence-form-manual-apply'),
              onPressed: () {
                final lines = inputController.text.trim().split('\n');
                final points = <LatLng>[];
                for (final line in lines) {
                  if (line.trim().isEmpty) continue;
                  final parts = line.trim().split(RegExp(r'[,，\s]+'));
                  if (parts.length >= 2) {
                    final lat = double.tryParse(parts[0].trim());
                    final lng = double.tryParse(parts[1].trim());
                    if (lat != null && lng != null) {
                      points.add(LatLng(lat, lng));
                    }
                  }
                }
                final minRequired = switch (_type) {
                  FenceType.rectangle => 2,
                  FenceType.circle => 2,
                  FenceType.polygon => 3,
                };
                if (points.length < minRequired) {
                  setDialogState(
                      () => errorText = '至少需要 $minRequired 个有效坐标点');
                  return;
                }
                final usedPoints = switch (_type) {
                  FenceType.rectangle => points.take(2).toList(),
                  FenceType.circle => points.take(2).toList(),
                  FenceType.polygon => points,
                };
                setState(() {
                  _drawingPoints = usedPoints;
                  _drawMode = false;
                  _clearTransientGesture();
                });
                Navigator.of(ctx).pop();
                if (usedPoints.isNotEmpty) {
                  _formMapController.move(usedPoints.first, 15.0);
                }
              },
              child: const Text('应用'),
            ),
          ],
        ),
      ),
    );
    inputController.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final appMode = ref.read(appModeProvider);
    final controller = ref.read(fenceControllerProvider.notifier);

    if (appMode.isLive) {
      final coords = _getFinalPointsForSave();
      final body = <String, dynamic>{
        'name': _nameController.text.trim(),
        'type': _type.name,
        'coordinates': coords,
        'alarmEnabled': _alarmEnabled,
      };
      if (_isEdit) {
        body['status'] = _active ? 'active' : 'inactive';
      }
      final ok = _isEdit
          ? await ApiCache.instance.updateFenceRemote(
              apiRoleFromEnvironment,
              widget.fenceId!,
              body,
            )
          : await ApiCache.instance.createFenceRemote(
              apiRoleFromEnvironment,
              body,
            );
      if (!ok) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存失败，请稍后重试')),
          );
        }
        return;
      }
      await ApiCache.instance.refreshFencesAndMap(apiRoleFromEnvironment);
      controller.reloadFromRepository();
      if (mounted) {
        setState(() => _saving = false);
        context.pop();
      }
      return;
    }

    await Future.delayed(const Duration(milliseconds: 300));

    final finalPoints = _getPreviewPoints().isNotEmpty
        ? _getPreviewPoints()
        : FenceItem.defaultPointsForType(_type, DemoSeed.mapCenter);

    if (_isEdit) {
      final fenceState = ref.read(fenceControllerProvider);
      FenceItem? existing;
      for (final f in fenceState.fences) {
        if (f.id == widget.fenceId) {
          existing = f;
          break;
        }
      }
      if (existing != null) {
        controller.update(existing.copyWith(
          name: _nameController.text.trim(),
          type: _type,
          alarmEnabled: _alarmEnabled,
          active: _active,
          points: finalPoints,
          areaHectares: _isDrawingComplete() ? _calcAreaHectares() : existing.areaHectares,
        ));
      }
    } else {
      final id = 'fence_${DateTime.now().millisecondsSinceEpoch}';
      final fenceCount = ref.read(fenceControllerProvider).fences.length;
      controller.add(FenceItem(
        id: id,
        name: _nameController.text.trim(),
        type: _type,
        alarmEnabled: _alarmEnabled,
        active: _active,
        areaHectares: _isDrawingComplete() ? _calcAreaHectares() : 1.0,
        livestockCount: 0,
        colorValue:
            FenceItem.defaultColors[fenceCount % FenceItem.defaultColors.length],
        points: finalPoints,
      ));
    }

    if (mounted) {
      setState(() => _saving = false);
      context.pop();
    }
  }

  List<List<double>> _getFinalPointsForSave() {
    final pts = _getPreviewPoints().isNotEmpty
        ? _getPreviewPoints()
        : FenceItem.defaultPointsForType(_type, DemoSeed.mapCenter);
    return pts.map((p) => [p.longitude, p.latitude]).toList();
  }

  @override
  Widget build(BuildContext context) {
    _initForEdit();
    final previewPoints = _getPreviewPoints();
    final complete = _isDrawingComplete();
    final area = complete ? _calcAreaHectares() : 1.0;
    final markerPts = _markerPoints();
    final banner = _overlayBannerText();

    final mapCore = FlutterMap(
      key: const ValueKey<String>('fence-form-flutter-map'),
      mapController: _formMapController,
      options: MapOptions(
        initialCenter: _drawingPoints.isNotEmpty
            ? _drawingPoints.first
            : DemoSeed.mapCenter,
        initialZoom: 15.0,
        interactionOptions: InteractionOptions(
          flags: _drawMode ? InteractiveFlag.none : InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: MapConfig.tileUrlTemplate,
          userAgentPackageName: 'com.smartlivestock.demo',
          maxZoom: MapConfig.cacheMaxZoom.toDouble(),
        ),
        if (previewPoints.length >= 3)
          PolygonLayer(
            polygons: [
              Polygon(
                points: previewPoints,
                color: AppColors.primary.withValues(alpha: 0.2),
                borderColor: AppColors.primary,
                borderStrokeWidth: 2,
              ),
            ],
          ),
        if (_type == FenceType.polygon &&
            _drawingPoints.length >= 2 &&
            _drawingPoints.length < 3)
          PolylineLayer(
            polylines: [
              Polyline(
                points: List.from(_drawingPoints),
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ],
          ),
        if (_drawMode &&
            _type == FenceType.polygon &&
            _cursorLatLng != null &&
            _drawingPoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [_drawingPoints.last, _cursorLatLng!],
                color: AppColors.primary,
                strokeWidth: 2,
                pattern: StrokePattern.dashed(segments: const [10, 6, 4, 6]),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            for (var i = 0; i < markerPts.length; i++)
              Marker(
                key: Key('fence-form-map-point-$i'),
                point: markerPts[i],
                width: 28,
                height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: i == 0
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    final mapWrapped = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleMapPointerDown,
      onPointerMove: _handleMapPointerMove,
      onPointerUp: _handleMapPointerUp,
      onPointerCancel: _handleMapPointerCancel,
      child: mapCore,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑围栏' : '新建围栏'),
        leading: IconButton(
          key: const Key('fence-form-back'),
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        key: const Key('page-fence-form'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('fence-form-name'),
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '围栏名称',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入围栏名称' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              KeyedSubtree(
                key: const Key('fence-form-type'),
                child: DropdownButtonFormField<FenceType>(
                  key: ValueKey<FenceType>(_type),
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: '围栏类型',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: FenceType.rectangle,
                      child: Text('矩形'),
                    ),
                    DropdownMenuItem(
                      value: FenceType.circle,
                      child: Text('圆形'),
                    ),
                    DropdownMenuItem(
                      value: FenceType.polygon,
                      child: Text('多边形'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _type = v;
                        _drawingPoints = [];
                        _drawMode = false;
                        _clearTransientGesture();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '面积：$area 公顷',
                key: const Key('fence-form-area'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.lg),
                child: SizedBox(
                  key: const Key('fence-form-map'),
                  height: 260,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(child: mapWrapped),
                      if (_drawMode && banner.isNotEmpty)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Material(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.92),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.sm,
                                right: AppSpacing.xxl * 3,
                                top: AppSpacing.xs,
                                bottom: AppSpacing.xs,
                              ),
                              child: Text(
                                banner,
                                key: const Key('fence-form-draw-hint'),
                                maxLines: 3,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      if (_drawMode &&
                          _type == FenceType.polygon &&
                          _drawingPoints.length >= 3)
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: FilledButton.tonal(
                              key: const Key('fence-form-polygon-done'),
                              onPressed: _finishPolygonDraw,
                              child: Text(
                                '完成绘制（${_drawingPoints.length}个顶点）',
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                          color: Theme.of(context).colorScheme.surface,
                          child: InkWell(
                            key: const Key('fence-form-draw-toggle'),
                            onTap: _toggleDrawMode,
                            borderRadius: BorderRadius.circular(AppSpacing.sm),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _drawMode
                                        ? Icons.check
                                        : Icons.edit_location_alt,
                                    size: 20,
                                    color: _drawMode
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    _drawMode ? '结束' : '开始绘制',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: _drawMode
                                              ? AppColors.primary
                                              : null,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _footerHintText(),
                      key: const Key('fence-form-map-hint'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: complete
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                    ),
                  ),
                  TextButton(
                    key: const Key('fence-form-map-reset'),
                    onPressed: _drawingPoints.isEmpty ? null : _resetDrawing,
                    child: const Text('重置'),
                  ),
                  TextButton(
                    key: const Key('fence-form-map-manual'),
                    onPressed: () => _showManualEntryDialog(context),
                    child: const Text('手动录入'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                key: const Key('fence-form-alarm'),
                contentPadding: EdgeInsets.zero,
                title: const Text('启用告警'),
                value: _alarmEnabled,
                onChanged: (v) => setState(() => _alarmEnabled = v),
              ),
              SwitchListTile(
                key: const Key('fence-form-active'),
                contentPadding: EdgeInsets.zero,
                title: const Text('启用状态'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('fence-form-cancel'),
                      onPressed: () => context.pop(),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      key: const Key('fence-form-save'),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('保存围栏'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
