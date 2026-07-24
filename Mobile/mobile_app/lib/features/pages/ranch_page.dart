import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/map/map_constants.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_factory.dart';
import 'package:hkt_livestock_agentic/core/map/tile_source_watermark.dart';
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
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/ranch_fence_tab.dart';
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
 int _sheetTab = 0; // 0=overview, 1=fence, 2=alerts
 bool _sheetExpanded = false;
 late final AnimationController _breathingController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _initTileProvider();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (context.mounted) ref.read(ranchControllerProvider.notifier).silentRefresh();
    });
  }

  Future<void> _initTileProvider() async {
    _tileProvider = await loadSmartTileProvider(
      ref,
      onSourceChanged: () { if (context.mounted) setState(() {}); },
    );
    if (context.mounted) setState(() {});
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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
         loading: () => _buildSkeletonMap(context),
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
      final pos = shouldTransform ? CoordTransform.wgs84ToGcj02(m.toLatLng()) : m.toLatLng();
      final insideAnyFence = fenceRings.any((ring) => fencePolygonContainsLatLng(pos, ring));
      if (!insideAnyFence && fenceRings.isNotEmpty) {
        fenceStatusMap[m.livestockId] = 'BREACH';
      }
    }


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
              key: ValueKey(_tileProvider?.activeSourceName),
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
            FenceBufferLayer(fences: overview.fences, bufferDistance: 50, shouldTransform: shouldTransform),
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
                    point: shouldTransform ? CoordTransform.wgs84ToGcj02(m.toLatLng()) : m.toLatLng(),
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

        // Bottom sheet with segmented tabs (overview / fence / alerts)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomSheet(context, overview, canManage),
        ),
        TileSourceWatermark(provider: _tileProvider),
      ],
    );
  }

 void _showLivestockDetail(BuildContext context, RanchLivestockMarker marker, RanchOverview overview) {
    final relatedAlerts = overview.alerts
        .where((a) => a.livestockId == marker.livestockId)
        .toList();
    showModalBottomSheet(
      context: context,
      builder: (_) =>
          LivestockDetailSheet(marker: marker, relatedAlerts: relatedAlerts),
    );
  }

  // ── Bottom sheet with segmented tabs ──

 Widget _buildBottomSheet(
   BuildContext context,
   RanchOverview overview,
   bool canManage,
 ) {
   final l10n = AppLocalizations.of(context)!;
   final activeAlerts =
       overview.alerts.where((a) => a.status == 'ACTIVE').length;
 
  return AnimatedContainer(
     duration: const Duration(milliseconds: 280),
     curve: Curves.easeOutCubic,
     constraints: BoxConstraints(
       maxHeight: _sheetExpanded
           ? MediaQuery.of(context).size.height * 0.85
           : MediaQuery.of(context).size.height * 0.40,
     ),
     decoration: const BoxDecoration(
       color: AppColors.surfaceAlt,
       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
       boxShadow: [
         BoxShadow(
           offset: Offset(0, -4),
           blurRadius: 24,
           color: Color.fromRGBO(38, 49, 38, 0.15),
         ),
       ],
     ),
     child: Column(
       mainAxisSize: MainAxisSize.min,
       children: [
         // Drag handle — tap to toggle expand/collapse, drag to swipe
        GestureDetector(
          onTap: () => setState(() => _sheetExpanded = !_sheetExpanded),
          onVerticalDragEnd: (details) {
            final vel = details.primaryVelocity ?? 0;
            if (vel > 100) {
              setState(() => _sheetExpanded = false);
            } else if (vel < -100) {
              setState(() => _sheetExpanded = true);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
            child: Container(
              width: 32,
              height: 3,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        // Segmented tabs
         Container(
           padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
           decoration: const BoxDecoration(
             border: Border(bottom: BorderSide(color: AppColors.border)),
           ),
           child: Row(
             children: [
               _SheetTab(
                 icon: Icons.dashboard_outlined,
                 label: l10n.ranchTabOverview,
                 isActive: _sheetTab == 0,
                 onTap: () => setState(() => _sheetTab = 0),
               ),
               _SheetTab(
                 icon: Icons.fence,
                 label: l10n.ranchTabFence,
                 isActive: _sheetTab == 1,
                 onTap: () => setState(() => _sheetTab = 1),
               ),
               _SheetTab(
                 icon: Icons.notifications,
                 label: l10n.ranchTabAlerts,
                 badge: activeAlerts,
                 isActive: _sheetTab == 2,
                 onTap: () => setState(() => _sheetTab = 2),
               ),
             ],
           ),
         ),
         // Tab content
         Flexible(
           child: switch (_sheetTab) {
             0 => _buildOverviewTab(context, overview),
             1 => SingleChildScrollView(
                child: RanchFenceTab(
                  fences: overview.fences,
                  alerts: overview.alerts,
                  selectedFenceId: _selectedFenceId,
                  canManage: canManage,
                  onFenceSelected: (id) {
                     setState(() {
                       _selectedFenceId = id.isEmpty ? null : id;
                       if (!id.isEmpty) {
                         final fence = overview.fences
                             .where((f) => f.id == id)
                             .firstOrNull;
                         if (fence != null) {
                           _mapController.move(
                             _fenceCenter(fence.points),
                             16.0,
                           );
                         }
                       }
                     });
                   },
                 ),
               ),
             _ => _buildAlertsTab(context, overview),
           },
         ),
       ],
     ),
   );
 }
 
 Widget _buildOverviewTab(BuildContext context, RanchOverview overview) {
   final l10n = AppLocalizations.of(context)!;
   final fenceSummary = overview.fenceAlertSummary;
   final healthSummary = overview.healthAlertSummary;
   final fenceTotal = fenceSummary.values.fold(0, (a, b) => a + b);
   final healthTotal = healthSummary.values.fold(0, (a, b) => a + b);
   final deviceAlerts = overview.alerts
       .where((a) =>
           a.status == 'ACTIVE' &&
           (a.type == 'DEVICE_TAMPER' || a.type == 'DEVICE_LOW_BATTERY'))
       .length;
 
   return SingleChildScrollView(
     padding: const EdgeInsets.symmetric(
         horizontal: AppSpacing.md, vertical: AppSpacing.sm),
     child: Wrap(
       spacing: AppSpacing.sm,
       runSpacing: AppSpacing.sm,
       children: [
         _DashCard(
           icon: Icons.fence,
           count: fenceTotal,
           label: l10n.ranchSectionFenceAlerts,
           color: AppColors.danger,
         ),
         _DashCard(
           icon: Icons.favorite,
           count: healthTotal,
           label: l10n.ranchSectionHealthAlerts,
           color: AppColors.warning,
         ),
         _DashCard(
           icon: Icons.devices,
           count: deviceAlerts,
           label: l10n.ranchSectionDeviceAlerts,
           color: AppColors.success,
         ),
         _DashCard(
           icon: Icons.pets,
           count: overview.overallStats.totalLivestock,
           label: l10n.ranchLivestockTotal,
           color: AppColors.info,
         ),
       ],
     ),
   );
 }
 
 Widget _buildAlertsTab(BuildContext context, RanchOverview overview) {
   final l10n = AppLocalizations.of(context)!;
   final active = overview.alerts.where((a) => a.status == 'ACTIVE').toList();
   if (active.isEmpty) {
     return Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           const Icon(Icons.notifications_off, size: 32, color: AppColors.textSecondary),
           const SizedBox(height: AppSpacing.sm),
           Text(l10n.alertEmptyTitle,
               style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
         ],
       ),
     );
   }
   return ListView.builder(
     padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
     itemCount: active.length,
     itemBuilder: (context, index) {
       final alert = active[index];
       return Card(
         margin: const EdgeInsets.only(bottom: AppSpacing.xs),
         child: ListTile(
           dense: true,
           leading: Icon(
             _alertIcon(alert.type),
             size: 18,
             color: alert.severity == 'CRITICAL'
                 ? AppColors.danger
                 : AppColors.warning,
           ),
           title: Text(alert.message, maxLines: 1, overflow: TextOverflow.ellipsis),
           subtitle: Text(alert.type, style: const TextStyle(fontSize: 10)),
           onTap: () => context.push(AppRoute.alerts.path),
         ),
       );
     },
   );
 }
 
 IconData _alertIcon(String type) {
   return switch (type) {
     'FENCE_BREACH' => Icons.fence,
     'FENCE_APPROACH' => Icons.warning_amber,
     'TEMPERATURE_ABNORMAL' => Icons.thermostat,
     'ESTRUS' => Icons.favorite,
     'EPIDEMIC' => Icons.shield,
     'AI_ANOMALY' => Icons.psychology,
     'DEVICE_TAMPER' => Icons.sensors,
     'DEVICE_LOW_BATTERY' => Icons.battery_alert,
     _ => Icons.notifications,
   };
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

  /// Skeleton map shown while ranch data loads — shows map background immediately
  /// with a small loading indicator, instead of a blank spinner screen.
  Widget _buildSkeletonMap(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: MapConstants.mapCenter,
            initialZoom: MapConstants.defaultZoom,
          ),
          children: [
            TileLayer(
              tileProvider: _tileProvider ?? _PlaceholderTileProvider(),
              urlTemplate: '',
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.xl,
          child: Center(
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(AppLocalizations.of(context)!.commonLoading),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
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


// ── Bottom sheet tab button ──

class _SheetTab extends StatelessWidget {
  const _SheetTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              if (badge != null && badge! > 0) ...[
                const SizedBox(width: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 12),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$badge',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dashboard card for overview tab ──

class _DashCard extends StatelessWidget {
  const _DashCard({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasAlert = count > 0 && label.contains('告警');
    return Container(
      width: (MediaQuery.of(context).size.width - AppSpacing.md * 2 - AppSpacing.sm) / 2,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: hasAlert ? color.withValues(alpha: 0.03) : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasAlert ? color.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 12, color: color),
              ),
              const Spacer(),
              if (count > 0 && hasAlert)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
