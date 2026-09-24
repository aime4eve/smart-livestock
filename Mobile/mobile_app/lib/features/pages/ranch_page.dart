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
import 'package:hkt_livestock_agentic/core/map/farm_map_center.dart';
import 'package:hkt_livestock_agentic/core/permissions/role_permission.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/fence_polygon_contains.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/features/twin_overview/presentation/twin_overview_controller.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/features/farm_switcher/farm_switcher_controller.dart';
import 'package:hkt_livestock_agentic/features/farm_switcher/farm_switcher_widget.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alert_summary.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/alerts_controller.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_detail_sheet.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/fence_status_card.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/unread_badge.dart';
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
  static const _fenceAlertTypes = {'FENCE_BREACH', 'FENCE_APPROACH', 'ZONE_APPROACH'};

  final _mapController = MapController();
  SmartTileProvider? _tileProvider;
  String? _selectedFenceId;
  String? _centeredFarmId;
  int _sheetTab = 0; // 0=overview, 1=fence, 2=alerts

  int _sheetSnap = 1; // 0=peek(tabs only), 1=half(40%), 2=full(85%)
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
      if (context.mounted) {
        ref.read(ranchControllerProvider.notifier).silentRefresh();
        ref.read(alertSummaryControllerProvider.notifier).silentRefresh();
      }
    });
  }

  Future<void> _initTileProvider() async {
    _tileProvider = await loadSmartTileProvider(
      ref,
      onSourceChanged: () {
        if (context.mounted) setState(() {});
      },
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
    final activeFarmId = ref.watch(farmSwitcherControllerProvider).activeFarmId;
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
        data: (overview) =>
            _buildMapWithSheet(context, overview, role, activeFarmId),
        loading: () => _buildSkeletonMap(context),
        error: (e, _) => _buildError(context, e.toString()),
      ),
    );
  }

  Widget _buildMapWithSheet(
    BuildContext context,
    RanchOverview overview,
    dynamic role,
    String? activeFarmId,
  ) {
    final canManage = role != null && RolePermission.canEditFence(role);
    // Transform decision follows the tiles actually serving the farm area:
    // 高德 online → GCJ-02, local offline/server OSM tiles → none.
    final refPoint = overview.fences.isNotEmpty &&
            overview.fences.first.points.isNotEmpty
        ? overview.fences.first.points.first
        : overview.livestockMarkers.isNotEmpty
            ? overview.livestockMarkers.first.toLatLng()
            : null;
    final shouldTransform = refPoint != null
        ? (_tileProvider?.shouldTransformAt(refPoint) ?? false)
        : (_tileProvider?.shouldTransformCoordinates() ?? false);
    _centerOnFarmOnce(overview, activeFarmId, shouldTransform);

    if (_selectedFenceId != null) {
      if (!_breathingController.isAnimating) {
        _breathingController.repeat(reverse: true);
      }
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
      } else if ((type == 'FENCE_APPROACH' || type == 'ZONE_APPROACH') &&
          existing != 'BREACH') {
        fenceStatusMap[alert.livestockId!] = 'APPROACH';
      }
    }

    // Supplement fence status from GPS containment check (for livestock without alert-derived status)
    final fenceRings = overview.fences.where((f) => f.points.length >= 3).map((
      f,
    ) {
      final pts = shouldTransform
          ? CoordTransform.wgs84ToGcj02All(f.points)
          : f.points;
      return pts;
    }).toList();
    for (final m in overview.livestockMarkers) {
      if (fenceStatusMap.containsKey(m.livestockId)) continue;
      final pos = shouldTransform
          ? CoordTransform.wgs84ToGcj02(m.toLatLng())
          : m.toLatLng();
      final insideAnyFence = fenceRings.any(
        (ring) => fencePolygonContainsLatLng(pos, ring),
      );
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
            initialCenter:
                _activeFarmCenter(shouldTransform) ?? MapConstants.mapCenter,
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
                            ? Color(fence.colorValue).withValues(
                                alpha: 0.3 + 0.1 * _breathingController.value,
                              )
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
            FenceBufferLayer(
              fences: overview.fences,
              bufferDistance: 50,
              shouldTransform: shouldTransform,
            ),
            MarkerLayer(
              markers: [
                // Fence name labels
                for (final fence in overview.fences)
                  if (fence.points.isNotEmpty)
                    Marker(
                      point: _fenceCenter(
                        shouldTransform
                            ? CoordTransform.wgs84ToGcj02All(fence.points)
                            : fence.points,
                      ),
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
                    point: shouldTransform
                        ? CoordTransform.wgs84ToGcj02(m.toLatLng())
                        : m.toLatLng(),
                    width: 32,
                    height: 32,
                    child: LivestockMapMarker(
                      key: Key('livestock-${m.livestockId}'),
                      livestockCode: m.livestockCode,
                      healthStatus: m.healthStatus,
                      primaryAlert: m.primaryAlert,
                      hasHealthTicket: m.hasHealthTicket,
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

  void _showLivestockDetail(
    BuildContext context,
    RanchLivestockMarker marker,
    RanchOverview overview,
  ) {
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
    // Badge = UNREAD active alerts (per-user), not the raw active total —
    // it drops to zero once everything is handled and grows with new alerts.
    final summary = ref.watch(alertSummaryControllerProvider).value;
    final unreadAlerts = summary?.unreadTotal ?? 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      constraints: BoxConstraints(
        maxHeight: switch (_sheetSnap) {
          0 => 80.0, // peek: handle + tab bar only
          1 => MediaQuery.of(context).size.height * 0.40,
          _ => MediaQuery.of(context).size.height * 0.85,
        },
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
            onTap: () => setState(() {
              // Cycle: peek(0) -> half(1) -> full(2) -> half(1) -> peek(0)
              if (_sheetSnap == 0) {
                _sheetSnap = 1;
              } else if (_sheetSnap == 1) {
                _sheetSnap = 2;
              } else {
                _sheetSnap = 0;
              }
            }),
            onVerticalDragEnd: (details) {
              final vel = details.primaryVelocity ?? 0;
              if (vel > 100) {
                // Swipe down: collapse
                setState(
                  () => _sheetSnap = _sheetSnap > 0 ? _sheetSnap - 1 : 0,
                );
              } else if (vel < -100) {
                // Swipe up: expand
                setState(
                  () => _sheetSnap = _sheetSnap < 2 ? _sheetSnap + 1 : 2,
                );
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 4,
            ),
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
                  badge: unreadAlerts,
                  isActive: _sheetTab == 2,
                  onTap: () => setState(() => _sheetTab = 2),
                ),
              ],
            ),
          ),
          // Tab content (hidden in peek mode)
          if (_sheetSnap > 0)
            Flexible(
              child: switch (_sheetTab) {
                0 => _buildOverviewTab(context, overview, summary),
                1 => SingleChildScrollView(
                  child: RanchFenceTab(
                    fences: overview.fences,
                    alerts: overview.alerts,
                    noGpsCount: overview.overallStats.noGpsCount,
                    outsideFenceCount: overview.overallStats.outsideFenceCount,
                    selectedFenceId: _selectedFenceId,
                    canManage: canManage,
                    onFenceSelected: (id) {
                      setState(() {
                        _selectedFenceId = id.isEmpty ? null : id;
                        if (id.isNotEmpty) {
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
                _ => _buildAlertsTab(context, overview, summary),
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
      BuildContext context, RanchOverview overview, RanchAlertSummary? summary) {
    final l10n = AppLocalizations.of(context)!;
    // Card numbers come from the shared summary endpoint (same source as the
    // alert center); client-side grouping is only the fallback until it loads.
    final fenceTotal =
        summary?.byGroup.fence ?? _clientGroupCount(overview, 'fence');
    final healthTotal =
        summary?.byGroup.health ?? _clientGroupCount(overview, 'health');
    final deviceAlerts =
        summary?.byGroup.device ?? _clientGroupCount(overview, 'device');
    final fenceUnread = summary?.byGroupUnread.fence ?? 0;
    final healthUnread = summary?.byGroupUnread.health ?? 0;
    final deviceUnread = summary?.byGroupUnread.device ?? 0;

    final twinAsync = ref.watch(twinOverviewControllerProvider);
    final twinStats = twinAsync.value?.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _buildDashCardWithUnread(
            UnreadBadge(count: fenceUnread),
            _DashCard(
              icon: Icons.fence,
              count: fenceTotal,
              label: l10n.ranchSectionFenceAlerts,
              color: AppColors.danger,
              onTap: () => context.push('${AppRoute.alerts.path}?category=fence'),
            ),
          ),
          _buildDashCardWithUnread(
            UnreadBadge(count: healthUnread),
            _DashCard(
              icon: Icons.favorite,
              count: healthTotal,
              label: l10n.ranchSectionHealthAlerts,
              color: AppColors.warning,
              onTap: () =>
                  context.push('${AppRoute.alerts.path}?category=health'),
            ),
          ),
          _buildDashCardWithUnread(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                UnreadBadge(count: deviceUnread),
                if (twinStats != null)
                  _dashRateCorner(
                      l10n.ranchStatDeviceOnline,
                      '${(twinStats.deviceOnlineRate * 100).toStringAsFixed(0)}%'),
              ],
            ),
            _DashCard(
              icon: Icons.devices,
              count: deviceAlerts,
              label: l10n.ranchSectionDeviceAlerts,
              color: AppColors.success,
              onTap: () =>
                  context.push('${AppRoute.alerts.path}?category=device'),
            ),
          ),
          _buildDashCardWithUnread(
            twinStats != null
                ? _dashRateCorner(
                    l10n.ranchStatHealthyRate,
                    twinStats.healthyRate > 0
                        ? '${(twinStats.healthyRate * 100).toStringAsFixed(0)}%'
                        : '-')
                : const SizedBox.shrink(),
            _DashCard(
              icon: Icons.pets,
              count: overview.overallStats.totalLivestock,
              label: l10n.ranchLivestockTotal,
              color: AppColors.info,
              onTap: () => context.push(AppRoute.livestockList.path),
            ),
          ),
        ],
          ),
          if (twinAsync.hasValue) ..._buildHealthIntegration(context, twinAsync.value!),
        ],
      ),
    );
  }

  // ── NIX-245 健康整合区块：五格统计 + 一行四格场景 + AI 观察 + 对账行 ──

  List<Widget> _buildHealthIntegration(BuildContext context, dynamic data) {
    final stats = data.stats;
    final scene = data.sceneSummary;
    if (stats == null || scene == null) return const [];

    final sceneAbnormal = scene.fever.abnormalCount +
        scene.digestive.abnormalCount +
        scene.estrus.highScoreCount;
    final activeTickets = scene.fever.activeAlertCount +
        scene.digestive.activeAlertCount +
        scene.estrus.activeAlertCount +
        scene.epidemic.activeAlertCount +
        (scene.ai?.activeAlertCount ?? 0);

    return [
      const SizedBox(height: AppSpacing.md),
      _buildSceneStrip(context, scene),
      const SizedBox(height: AppSpacing.sm),
      _buildAiRow(context, scene.ai),
      const SizedBox(height: AppSpacing.sm),
      _buildReconcileLine(context, sceneAbnormal, activeTickets),
      const SizedBox(height: AppSpacing.sm),
    ];
  }

  Widget _buildSceneStrip(BuildContext context, dynamic scene) {
    final l10n = AppLocalizations.of(context)!;
    Widget tile({
      required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required int tickets,
      required VoidCallback onTap,
    }) {
      return Stack(
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Column(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(height: 4),
                    Text(title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
          if (tickets > 0)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () =>
                    context.push('${AppRoute.alerts.path}?category=health'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$tickets',
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ),
        ],
      );
    }

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.15,
      children: [
        tile(
          icon: Icons.thermostat,
          color: Colors.orange,
          title: l10n.ranchSceneFeverMgmt,
          subtitle: l10n.sceneFeverTileSub(
              scene.fever.abnormalCount, scene.fever.criticalCount),
          tickets: scene.fever.activeAlertCount,
          onTap: () => context.go(AppRoute.twinFever.path),
        ),
        tile(
          icon: Icons.grain,
          color: Colors.brown,
          title: l10n.ranchSceneDigestiveMgmt,
          subtitle: l10n.sceneDigestiveTileSub(
              scene.digestive.abnormalCount, scene.digestive.watchCount),
          tickets: scene.digestive.activeAlertCount,
          onTap: () => context.go(AppRoute.twinDigestive.path),
        ),
        tile(
          icon: Icons.favorite,
          color: AppColors.estrus,
          title: l10n.ranchSceneEstrusMgmt,
          subtitle: l10n.sceneEstrusTileSub(scene.estrus.highScoreCount),
          tickets: scene.estrus.activeAlertCount,
          onTap: () => context.go(AppRoute.twinEstrus.path),
        ),
        tile(
          icon: Icons.shield,
          color: Colors.teal,
          title: l10n.ranchSceneEpidemic,
          subtitle: l10n
              .sceneEpidemicTileSub((scene.epidemic.abnormalRate * 100).toStringAsFixed(1)),
          tickets: scene.epidemic.activeAlertCount,
          onTap: () => context.go(AppRoute.twinEpidemic.path),
        ),
      ],
    );
  }

  Widget _buildAiRow(BuildContext context, dynamic ai) {
    final l10n = AppLocalizations.of(context)!;
    if (ai == null) return const SizedBox.shrink();
    final band = ai.avgScore >= 0.7
        ? l10n.aiBandAlarm
        : ai.avgScore >= 0.3
            ? l10n.aiBandWatch
            : l10n.aiBandCalm;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.smart_toy, color: AppColors.info, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l10n.aiObserveTitle,
                  style:
                      const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            Text('${l10n.aiObserveWatching} ${ai.anomalyCount}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(width: 12),
            Text('${l10n.aiObserveOverall} $band',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: ai.avgScore >= 0.7
                        ? AppColors.danger
                        : ai.avgScore >= 0.3
                            ? AppColors.warning
                            : AppColors.success)),
          ],
        ),
      ),
    );
  }

  Widget _buildReconcileLine(BuildContext context, int sceneAbnormal, int tickets) {
    final l10n = AppLocalizations.of(context)!;
    final ok = sceneAbnormal == tickets;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              ok
                  ? '${l10n.reconcileSceneAbnormal} $sceneAbnormal ${l10n.reconcileHeadUnit} · ${l10n.reconcileActiveTickets} $tickets ${l10n.reconcileTicketUnit}'
                  : '${l10n.reconcileSceneAbnormal} $sceneAbnormal ${l10n.reconcileHeadUnit} · ${l10n.reconcileActiveTickets} $tickets ${l10n.reconcileTicketUnit} · ${l10n.reconcileOffBy}${(tickets - sceneAbnormal).abs()}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success.withValues(alpha: 0.9)),
            ),
          ),
          const SizedBox(width: 4),
          Icon(ok ? Icons.check_circle : Icons.error_outline,
              size: 13, color: ok ? AppColors.success : AppColors.warning),
        ],
      ),
    );
  }

  /// Fallback grouping of overview alerts while the summary endpoint loads.
  int _clientGroupCount(RanchOverview overview, String group) {
    final groups = switch (group) {
      'fence' => _fenceAlertTypes,
      'device' => const {'DEVICE_TAMPER', 'DEVICE_LOW_BATTERY'},
      _ => const {
          'TEMPERATURE_ABNORMAL',
          'DIGESTIVE_ABNORMAL',
          'ESTRUS',
          'EPIDEMIC',
          'AI_ANOMALY'
        },
    };
    return overview.alerts
        .where((a) => a.status == 'ACTIVE' && groups.contains(a.type))
        .length;
  }

  /// NIX-245: dash-card top-right micro annotation (健康率/在线率)，
  /// 两行：数值（success 色）+ 微标签（次要色）。
  Widget _dashRateCorner(String label, String value) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success)),
          Text(label,
              style:
                  const TextStyle(fontSize: 8, color: AppColors.textSecondary)),
        ],
      );

  /// Overlays the unread pill on the card's top-right corner.
  Widget _buildDashCardWithUnread(Widget badge, Widget card) {
    return Stack(
      children: [
        card,
        Positioned(top: 6, right: 6, child: badge),
      ],
    );
  }

  Widget _buildAlertsTab(
      BuildContext context, RanchOverview overview, RanchAlertSummary? summary) {
    final l10n = AppLocalizations.of(context)!;
    final active = overview.alerts.where((a) => a.status == 'ACTIVE').toList();
    if (active.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_off,
              size: 32,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.alertEmptyTitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    // Aggregated fence status (livestock × fence, deduped) above the raw
    // event stream — answers "what is the situation now" at a glance.
    final fenceAlerts =
        active.where((a) => _fenceAlertTypes.contains(a.type)).toList();
    final livestockCodes = {
      for (final m in overview.livestockMarkers) m.livestockId: m.livestockCode,
    };
    final fenceNames = {
      for (final f in overview.fences) f.id: f.name,
    };
    final listTiles = <Widget>[
      if (fenceAlerts.isNotEmpty)
        FenceStatusCard(
          alerts: fenceAlerts,
          livestockCodes: livestockCodes,
          fenceNames: fenceNames,
          onViewAll: () => context.push('${AppRoute.alerts.path}?category=fence'),
          onRowTap: (alert) {
            final role = ref.read(sessionControllerProvider).role;
            if (role == null) return;
            showAlertDetailSheet(
              context,
              alert: AlertItem(
                id: alert.id,
                title: alert.message,
                subtitle: '',
                priority: alert.severity == 'CRITICAL'
                    ? 'P0'
                    : (alert.severity == 'WARNING' ? 'P1' : 'P2'),
                type: alert.type,
                stage: alert.status.toLowerCase(),
                livestockCode: alert.livestockId ?? '-',
                livestockId: alert.livestockId,
                severity: alert.severity,
                read: alert.read,
                occurredAt: alert.occurredAt,
                resolvedAt: alert.resolvedAt,
                fenceId: alert.fenceId,
              ),
              role: role,
            );
          },
        ),
      ...active.map((alert) {
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
            title: Text(
              alert.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _alertTypeLabel(AppLocalizations.of(context)!, alert.type),
              style: const TextStyle(fontSize: 10),
            ),
            onTap: () => context.push(
                '${AppRoute.alerts.path}?category=${_categoryOf(alert.type)}'),
          ),
        );
      }),
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: listTiles,
    );
  }

  String _categoryOf(String type) {
    if (_fenceAlertTypes.contains(type)) return 'fence';
    if (type == 'DEVICE_TAMPER' || type == 'DEVICE_LOW_BATTERY') return 'device';
    return 'health';
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

  String _alertTypeLabel(AppLocalizations l10n, String type) {
    return switch (type) {
      'FENCE_BREACH' => l10n.alertTypeFenceBreach,
      'FENCE_APPROACH' => l10n.alertTypeFenceApproach,
      'ZONE_APPROACH' => l10n.alertTypeZoneApproach,
      'TEMPERATURE_ABNORMAL' => l10n.alertTypeTemperatureAbnormal,
      'DIGESTIVE_ABNORMAL' => l10n.alertTypeDigestiveAbnormal,
      'ESTRUS' => l10n.alertTypeEstrus,
      'EPIDEMIC' => l10n.alertTypeEpidemic,
      'AI_ANOMALY' => l10n.alertTypeAiAnomaly,
      'DEVICE_TAMPER' => l10n.alertTypeDeviceTamper,
      'DEVICE_LOW_BATTERY' => l10n.alertTypeDeviceLowBattery,
      _ => type,
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

  /// 当前牧场的登记坐标（WGS-84，按瓦片源需要转换）；未登记时返回 null
  LatLng? _activeFarmCenter(bool shouldTransform) {
    final center = ref.read(farmSwitcherControllerProvider).activeFarmCenter;
    if (center == null) return null;
    return shouldTransform ? CoordTransform.wgs84ToGcj02(center) : center;
  }

  /// 首次加载后把地图定位到当前牧场的实际位置：
  /// 优先按围栏范围居中，牧场尚未画围栏时退回登记坐标，避免停在演示默认点。
  void _centerOnFarmOnce(
    RanchOverview overview,
    String? farmId,
    bool shouldTransform,
  ) {
    final farmKey = farmId ?? '';
    if (_centeredFarmId == farmKey) return;
    if (_tileProvider == null) return;

    final farm = ref.read(farmSwitcherControllerProvider).activeFarm;
    final center = resolveFarmMapCenter(
      fenceRings: overview.fences.map((f) => f.points),
      farmLatitude: farm?.latitude,
      farmLongitude: farm?.longitude,
      shouldTransform: shouldTransform,
    );
    if (center == null) return;

    final resolved = center;
    _centeredFarmId = farmKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _centeredFarmId == farmKey) {
        _mapController.move(resolved, MapConstants.defaultZoom);
      }
    });
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
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
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
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.commonLoadFailed,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () =>
                    ref.read(ranchControllerProvider.notifier).refresh(),
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
    // Transparent (AssetImage('') here threw per tile and left the map white).
    return MemoryImage(TileProvider.transparentImage);
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
    this.onTap,
  });

  final IconData icon;
  final int count;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasAlert = count > 0 && label.contains('告警');
    final card = Container(
      width:
          (MediaQuery.of(context).size.width -
              AppSpacing.md * 2 -
              AppSpacing.sm) /
          2,
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
              // No inline count pill here: the big number already shows the
              // active total, and the unread pill (UnreadBadge) sits on the
              // card's top-right corner — two pills would overlap.
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
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
    return onTap != null ? GestureDetector(onTap: onTap, child: card) : card;
  }
}
