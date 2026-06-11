import 'dart:math' show min;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/map/map_constants.dart';
import 'package:smart_livestock_demo/core/map/map_config.dart';
import 'package:smart_livestock_demo/core/map/smart_tile_provider.dart';
import 'package:smart_livestock_demo/core/map/mbtiles_tile_provider.dart';
import 'package:smart_livestock_demo/core/map/coord_transform.dart';
import 'package:smart_livestock_demo/core/permissions/role_permission.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_controller.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_widget.dart';
import 'package:smart_livestock_demo/features/ranch/domain/ranch_models.dart';
import 'package:smart_livestock_demo/features/ranch/presentation/ranch_controller.dart';
import 'package:smart_livestock_demo/features/ranch/presentation/widgets/health_marker.dart';
import 'package:smart_livestock_demo/features/ranch/presentation/widgets/alert_marker.dart';
import 'package:smart_livestock_demo/features/ranch/presentation/widgets/health_bottom_sheet.dart';
import 'package:smart_livestock_demo/features/ranch/presentation/widgets/livestock_detail_sheet.dart';
import 'package:smart_livestock_demo/features/ranch/presentation/widgets/fence_buffer_layer.dart';

class RanchPage extends ConsumerStatefulWidget {
  const RanchPage({super.key});

  @override
  ConsumerState<RanchPage> createState() => _RanchPageState();
}

class _RanchPageState extends ConsumerState<RanchPage>
    with TickerProviderStateMixin {
  final _mapController = MapController();
  SmartTileProvider? _tileProvider;
  String? _selectedFenceId;
  bool _fencePanelOpen = false;
  late final AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _initTileProvider();
  }

  Future<void> _initTileProvider() async {
    MBTilesTileProvider? mbtiles;
    if (!kIsWeb) {
      mbtiles = await MBTilesTileProvider.fromAsset();
    }
    final region = const String.fromEnvironment('REGION', defaultValue: 'china');
    final isChina = region == 'china';
    final tp = await SmartTileProvider.create(
      selfHostedTileUrl: MapConfig.selfHostedTileUrl,
      mbtilesProvider: mbtiles,
      fallbackUrl: isChina ? MapConfig.chinaFallbackUrl : MapConfig.overseasFallbackUrl,
      isGcj02Fallback: isChina,
      onSourceChanged: () { if (mounted) setState(() {}); },
    );
    _tileProvider = tp;
    _tileProvider!.startHealthMonitor();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tileProvider?.dispose();
    _breathingController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(ranchControllerProvider);
    final farmName = ref.watch(farmSwitcherControllerProvider).activeFarmName;
    final role = ref.watch(sessionControllerProvider).role;

    return Scaffold(
      key: const Key('page-ranch'),
      appBar: AppBar(
        title: Text(farmName.isNotEmpty ? farmName : '牧场'),
        actions: const [
          FarmSwitcher(),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: asyncData.when(
        data: (overview) => _buildMapWithSheet(context, overview, role),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(context, e.toString()),
      ),
    );
  }

  Widget _buildMapWithSheet(BuildContext context, RanchOverview overview, dynamic role) {
    final canManage = role != null && RolePermission.canEditFence(role);
    final shouldTransform = _tileProvider?.shouldTransformCoordinates() ?? false;

    if (_selectedFenceId != null) {
      if (!_breathingController.isAnimating) _breathingController.repeat(reverse: true);
    } else {
      if (_breathingController.isAnimating) {
        _breathingController.stop();
        _breathingController.value = 0;
      }
    }

    final alertLivestockIds = <String>{};
    for (final alert in overview.alerts) {
      if (alert.status != 'HANDLED' && alert.status != 'ARCHIVED' && alert.livestockId != null) {
        alertLivestockIds.add(alert.livestockId!);
      }
    }

    // Build fence status map per livestock (from active fence alerts)
    final fenceStatusMap = <String, String>{};
    for (final alert in overview.alerts) {
      if (alert.status != 'ACTIVE' || alert.livestockId == null) continue;
      final type = alert.type;
      final existing = fenceStatusMap[alert.livestockId!];
      if (type == 'FENCE_BREACH') {
        fenceStatusMap[alert.livestockId!] = 'BREACHED';
      } else if ((type == 'FENCE_APPROACH' || type == 'ZONE_APPROACH') && existing != 'BREACHED') {
        fenceStatusMap[alert.livestockId!] = 'APPROACHING';
      }
    }

    const panelAnimDuration = Duration(milliseconds: 280);
    const panelCurve = Curves.easeOutCubic;

    return Stack(
      children: [
        // Map layer
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: MapConstants.mapCenter,
            initialZoom: MapConstants.defaultZoom,
            onTap: (_, point) => _handleMapTap(point),
          ),
          children: [
            TileLayer(
              tileProvider: _tileProvider ?? _PlaceholderTileProvider(),
              urlTemplate: '',
            ),
            if (_selectedFenceId == null)
              PolygonLayer(
                polygons: [
                  for (final fence in overview.fences)
                    Polygon(
                      points: shouldTransform
                          ? CoordTransform.wgs84ToGcj02All(fence.points)
                          : fence.points,
                      color: Color(fence.colorValue).withValues(alpha: 0.15),
                      borderColor: Color(fence.colorValue),
                      borderStrokeWidth: 2,
                    ),
                ],
              )
            else
              AnimatedBuilder(
                animation: _breathingController,
                builder: (context, _) => PolygonLayer(
                  polygons: [
                    for (final fence in overview.fences)
                      Polygon(
                        points: shouldTransform
                            ? CoordTransform.wgs84ToGcj02All(fence.points)
                            : fence.points,
                        color: fence.id == _selectedFenceId
                            ? Color(fence.colorValue).withValues(alpha: 0.3 + 0.1 * _breathingController.value)
                            : Color(fence.colorValue).withValues(alpha: 0.08),
                        borderColor: fence.id == _selectedFenceId
                            ? Color(fence.colorValue)
                            : Color(fence.colorValue).withValues(alpha: 0.4),
                        borderStrokeWidth: fence.id == _selectedFenceId
                            ? 3.0 + 1.5 * _breathingController.value
                            : 1.5,
                      ),
                  ],
                ),
              ),
            FenceBufferLayer(fences: overview.fences, bufferDistance: 50),
            MarkerLayer(
              markers: [
                // Fence name labels
                for (final fence in overview.fences)
                  if (fence.points.isNotEmpty)
                    Marker(
                      point: _fenceCenter(shouldTransform
                          ? CoordTransform.wgs84ToGcj02All(fence.points)
                          : fence.points),
                      width: 120,
                      height: 28,
                      child: _FenceMapNameChip(
                        name: fence.name,
                        colorValue: fence.colorValue,
                        selected: fence.id == _selectedFenceId,
                      ),
                    ),
                // Livestock markers (non-alert)
                for (final m in overview.livestockMarkers)
                  if (!alertLivestockIds.contains(m.livestockId))
                    Marker(
                      point: m.toLatLng(),
                      width: 32,
                      height: 32,
                      child: HealthMarker(
                        key: Key('livestock-${m.livestockId}'),
                        label: m.livestockCode,
                        healthStatus: m.healthStatus,
                        onTap: () => _showLivestockDetail(context, m, overview),
                      ),
                    ),
                // Alert markers (with pulsing)
                for (final m in overview.livestockMarkers)
                  if (alertLivestockIds.contains(m.livestockId))
                    Marker(
                      point: m.toLatLng(),
                      width: 36,
                      height: 36,
                      child: AlertMarker(
                        key: Key('alert-livestock-${m.livestockId}'),
                        label: m.livestockCode,
                        severity: _alertSeverityForLivestock(m.livestockId, overview),
                        onTap: () => _showLivestockDetail(context, m, overview),
                      ),
                    ),
              ],
            ),
          ],
        ),

        // Fence list sidebar overlay
        LayoutBuilder(builder: (context, constraints) {
          final panelW = min(280.0, constraints.maxWidth * 0.78);
          return Stack(
            children: [
              AnimatedPositioned(
                duration: panelAnimDuration,
                curve: panelCurve,
                left: _fencePanelOpen ? 0 : -panelW,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Text('围栏列表', style: Theme.of(context).textTheme.titleMedium),
                              const Spacer(),
                              if (canManage)
                                IconButton(
                                  onPressed: () {
                                    context.push(AppRoute.fenceForm.path).then((_) {
                                      ref.read(ranchControllerProvider.notifier).refresh();
                                    });
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                  tooltip: '新建围栏',
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            children: [
                              if (overview.fences.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                                  child: Center(
                                    child: Text(
                                      '暂无围栏',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                for (final fence in overview.fences)
                                  _RanchFenceCard(
                                    fence: fence,
                                    isSelected: fence.id == _selectedFenceId,
                                    canManage: canManage,
                                    onTap: () {
                                      setState(() => _selectedFenceId = fence.id);
                                      _mapController.move(
                                        _fenceCenter(shouldTransform
                                            ? CoordTransform.wgs84ToGcj02All(fence.points)
                                            : fence.points),
                                        16.0,
                                      );
                                    },
                                    onEdit: () => context.go(AppRoute.fence.path),
                                    onDelete: () => _showDeleteDialog(context, fence),
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Fence panel toggle button
              AnimatedPositioned(
                duration: panelAnimDuration,
                curve: panelCurve,
                left: _fencePanelOpen ? panelW + 8 : 8,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: FloatingActionButton.small(
                    key: const Key('ranch-fence-panel-toggle'),
                    heroTag: 'ranch-fence-panel-toggle',
                    onPressed: () => setState(() => _fencePanelOpen = !_fencePanelOpen),
                    tooltip: _fencePanelOpen ? '收起围栏列表' : '围栏列表',
                    child: Icon(_fencePanelOpen ? Icons.chevron_left : Icons.menu),
                  ),
                ),
              ),

              // Edit boundary FAB (only when fence selected)
              if (canManage && _selectedFenceId != null)
                Positioned(
                  right: AppSpacing.md,
                  bottom: 140,
                  child: FloatingActionButton.extended(
                    key: const Key('ranch-edit-fence-btn'),
                    heroTag: 'ranch-edit-fence',
                    onPressed: () => context.go(AppRoute.fence.path),
                    icon: const Icon(Icons.edit_location_alt_outlined),
                    label: const Text('编辑边界'),
                  ),
                ),

              // Add fence FAB (only when no fence selected)
              if (canManage && _selectedFenceId == null)
                Positioned(
                  right: AppSpacing.md,
                  bottom: 140,
                  child: FloatingActionButton.small(
                    key: const Key('ranch-add-fence-btn'),
                    heroTag: 'ranch-add-fence',
                    onPressed: () => context.push(AppRoute.fenceForm.path).then((_) {
                      ref.read(ranchControllerProvider.notifier).refresh();
                    }),
                    child: const Icon(Icons.add),
                  ),
                ),
            ],
          );
        }),

        // Bottom health sheet — anchored to bottom, full width
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: HealthBottomSheet(overview: overview),
        ),
      ],
    );
  }

  String _alertSeverityForLivestock(String livestockId, RanchOverview overview) {
    for (final alert in overview.alerts) {
      if (alert.livestockId == livestockId &&
          alert.status != 'HANDLED' &&
          alert.status != 'ARCHIVED') {
        return alert.severity;
      }
    }
    return 'LOW';
  }

  void _showLivestockDetail(BuildContext context, RanchLivestockMarker marker, RanchOverview overview) {
    final relatedAlerts = overview.alerts
        .where((a) => a.livestockId == marker.livestockId)
        .toList();
    showModalBottomSheet(
      context: context,
      builder: (_) => LivestockDetailSheet(marker: marker, relatedAlerts: relatedAlerts),
    );
  }

  void _handleMapTap(LatLng point) {
    setState(() => _selectedFenceId = null);
  }

  LatLng _fenceCenter(List<LatLng> points) {
    double lat = 0, lng = 0;
    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  Future<void> _showDeleteDialog(BuildContext context, RanchFenceData fence) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确认删除「${fence.name}」？删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ApiClient.instance.farmDelete('/fences/${fence.id}');
        if (!mounted) return;
        ref.read(ranchControllerProvider.notifier).refresh();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('已删除「${fence.name}」')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(AppSpacing.xl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: AppSpacing.md),
              Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => ref.read(ranchControllerProvider.notifier).refresh(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder tile provider used before SmartTileProvider initializes.
class _PlaceholderTileProvider extends TileProvider {
  _PlaceholderTileProvider();
  @override
  ImageProvider getImage(TileCoordinates coords, TileLayer layer) {
    return const AssetImage('');
  }
}

// ── Fence name chip on map ──────────────────────────────────────────────

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
          constraints: const BoxConstraints(maxWidth: 116),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            border: Border.all(
              color: selected ? accent : accent.withValues(alpha: 0.45),
              width: selected ? 2 : 1,
            ),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
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

// ── Fence card in sidebar ──────────────────────────────────────────────

class _RanchFenceCard extends StatelessWidget {
  const _RanchFenceCard({
    required this.fence,
    required this.isSelected,
    required this.canManage,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final RanchFenceData fence;
  final bool isSelected;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('ranch-fence-card-${fence.id}'),
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
                height: 36,
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
                    Text(fence.name, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 1),
                          decoration: BoxDecoration(
                            color: fence.active
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.textSecondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            fence.active ? '启用' : '停用',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: fence.active ? AppColors.success : AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text('${fence.livestockCount}头',
                          style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              if (canManage) ...[
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: '编辑',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
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
