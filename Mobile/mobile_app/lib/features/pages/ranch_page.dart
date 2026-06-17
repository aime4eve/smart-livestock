import 'dart:math' show min;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/map/map_constants.dart';
import 'package:hkt_livestock_agentic/core/map/map_config.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/map/tile_source_resolver.dart';
import 'package:hkt_livestock_agentic/core/map/mbtiles_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/map/coord_transform.dart';
import 'package:hkt_livestock_agentic/core/permissions/role_permission.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/fence_polygon_contains.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/features/farm_switcher/farm_switcher_controller.dart';
import 'package:hkt_livestock_agentic/features/farm_switcher/farm_switcher_widget.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/ranch_controller.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/livestock_map_marker.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/health_bottom_sheet.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/livestock_detail_sheet.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/fence_buffer_layer.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

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
    String? regionUrl;
    if (ApiClient.instance.activeFarmId != null) {
      try {
        final sources = await ref.read(tileSourceResolverProvider).resolve(0);
        regionUrl = sources.isEmpty ? null : sources.first.tileUrl;
      } catch (_) {}
    }
    final tp = await SmartTileProvider.create(
      selfHostedTileUrl: regionUrl,
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
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(ranchControllerProvider);
    final farmName = ref.watch(farmSwitcherControllerProvider).activeFarmName;
    final role = ref.watch(sessionControllerProvider).role;

    return Scaffold(
      key: const Key('page-ranch'),
      appBar: AppBar(
        title: Text(farmName.isNotEmpty ? farmName : l10n.navRanch),
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
    final l10n = AppLocalizations.of(context)!;
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

    // Build fence status map per livestock (from active fence alerts)
    final fenceStatusMap = <String, String>{};
    for (final alert in overview.alerts) {
      if (alert.status != 'ACTIVE' || alert.livestockId == null) continue;
      final type = alert.type;
      final existing = fenceStatusMap[alert.livestockId!];
      if (type == 'FENCE_BREACH') {
        fenceStatusMap[alert.livestockId!] = 'BREACH';
      } else if ((type == 'FENCE_APPROACH' || type == 'ZONE_APPROACH') && existing != 'BREACH') {
        fenceStatusMap[alert.livestockId!] = 'APPROACH';
      }
    }

    // Supplement fence status from GPS containment check (for livestock without alert-derived status)
    final fenceRings = overview.fences
        .where((f) => f.points.length >= 3)
        .map((f) {
          final pts = shouldTransform
              ? CoordTransform.wgs84ToGcj02All(f.points)
              : f.points;
          return pts;
        }).toList();
    for (final m in overview.livestockMarkers) {
      if (fenceStatusMap.containsKey(m.livestockId)) continue;
      final pos = m.toLatLng();
      final insideAnyFence = fenceRings.any((ring) => fencePolygonContainsLatLng(pos, ring));
      if (!insideAnyFence && fenceRings.isNotEmpty) {
        fenceStatusMap[m.livestockId] = 'BREACH';
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
                // Livestock markers (unified)
                for (final m in overview.livestockMarkers)
                  Marker(
                    point: m.toLatLng(),
                    width: 32,
                    height: 32,
                    child: LivestockMapMarker(
                      key: Key('livestock-${m.livestockId}'),
                      livestockCode: m.livestockCode,
                      healthStatus: m.healthStatus,
                      primaryAlert: m.primaryAlert,
                      fenceStatus: fenceStatusMap[m.livestockId] ?? 'SAFE',
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
                              Text(l10n.ranchFenceList, style: Theme.of(context).textTheme.titleMedium),
                              const Spacer(),
                              if (canManage)
                                IconButton(
                                  onPressed: () {
                                    context.push(AppRoute.fenceForm.path).then((_) {
                                      ref.read(ranchControllerProvider.notifier).refresh();
                                    });
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                  tooltip: l10n.ranchNewFence,
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
                                      l10n.ranchNoFence,
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
                    tooltip: _fencePanelOpen ? l10n.ranchCollapseFenceList : l10n.ranchFenceList,
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
                    label: Text(l10n.ranchEditBoundary),
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.commonConfirmDelete),
        content: Text(l10n.ranchConfirmDeleteFence(fence.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonDelete, style: const TextStyle(color: AppColors.danger)),
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
          ..showSnackBar(SnackBar(content: Text(l10n.ranchFenceDeleted(fence.name))));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.commonDeleteFailed(e.toString()))));
      }
    }
  }

  Widget _buildError(BuildContext context, String error) {
    final l10n = AppLocalizations.of(context)!;
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
              Text(l10n.commonLoadFailed, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => ref.read(ranchControllerProvider.notifier).refresh(),
                child: Text(l10n.commonRetry),
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
    final l10n = AppLocalizations.of(context)!;
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
                            fence.active ? l10n.ranchFenceActive : l10n.ranchFenceInactive,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: fence.active ? AppColors.success : AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(l10n.ranchLivestockCountHead(fence.livestockCount.toString()),
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
                  tooltip: l10n.commonEdit,
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: l10n.commonDelete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
