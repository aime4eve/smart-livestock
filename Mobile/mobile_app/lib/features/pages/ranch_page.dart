import 'dart:async';
import 'dart:math' as math;
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
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/utils/app_time.dart';
import 'package:hkt_livestock_agentic/features/twin_overview/presentation/twin_overview_controller.dart';
import 'package:hkt_livestock_agentic/features/farm_switcher/farm_switcher_controller.dart';
import 'package:hkt_livestock_agentic/features/farm_switcher/farm_switcher_widget.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alert_summary.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/alerts_controller.dart';
import 'package:hkt_livestock_agentic/features/alerts/data/alerts_api_repository.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alert_workbench.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/alert_workbench_controller.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_workbench_detail_sheet.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_detail_sheet.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_workbench_view.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/widgets/trajectory_sheet.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/ranch_controller.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/livestock_map_marker.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/ranch_fence_tab.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/livestock_detail_sheet.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/fence_buffer_layer.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/ranch_summary_tile.dart';
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
    final refPoint =
        overview.fences.isNotEmpty && overview.fences.first.points.isNotEmpty
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
          child: _buildBottomSheet(
            context,
            overview,
            canManage,
            fenceStatusMap: fenceStatusMap,
          ),
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
    bool canManage, {
    required Map<String, String> fenceStatusMap,
  }) {
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
                    totalLivestock: overview.overallStats.totalLivestock,
                    fenceUnread: summary?.byGroupUnread.fence ?? 0,
                    fenceStatusMap: fenceStatusMap,
                    livestockMarkers: overview.livestockMarkers,
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

  // ── 方案 D「晨报看板」（NIX-246 裁决 23）：Hero + 三色瓷砖 + 2×2 场景 + AI ──
  // 1:1 蓝本 = docs/prototypes/health-scenario-alert-integration-prototype.html 屏 1/1b

  static const Color _heroGrad1 = Color(0xFF1C3F25);
  static const Color _heroGrad2 = Color(0xFF2F6B3B);
  static const Color _heroGrad3 = Color(0xFF3E7F4C);
  static const Color _heroRing = Color(0xFF8FD694);
  static const Color _tileRed1 = Color(0xFFB3453B);
  static const Color _tileRed2 = Color(0xFFC9664F);
  static const Color _tileOrange1 = Color(0xFFC07A22);
  static const Color _tileOrange2 = Color(0xFFDB9C40);

  Widget _buildOverviewTab(
    BuildContext context,
    RanchOverview overview,
    RanchAlertSummary? summary,
  ) {
    // Card numbers come from the shared summary endpoint (same source as the
    // alert center); client-side grouping is only the fallback until it loads.
    final fenceTotal =
        summary?.byGroup.fence ?? _clientGroupCount(overview, 'fence');
    final healthTotal =
        summary?.byGroup.health ?? _clientGroupCount(overview, 'health');
    final deviceAlerts =
        summary?.byGroup.device ?? _clientGroupCount(overview, 'device');
    final fenceUnread = summary?.byGroupUnread.fence ?? 0;

    final twinAsync = ref.watch(twinOverviewControllerProvider);
    final stats = twinAsync.value?.stats;
    final scene = twinAsync.value?.sceneSummary;
    final farmName = ref.watch(farmSwitcherControllerProvider).activeFarmName;

    // 围栏去重数与"持续超 6 小时"发热单：同一份活跃告警列表派生（不加查询）
    final now = DateTime.now();
    final activeAlerts = overview.alerts
        .where((a) => a.status == 'ACTIVE')
        .toList();
    final breachedFences = activeAlerts
        .where(
          (a) =>
              (a.fenceId ?? '').isNotEmpty &&
              const {
                'FENCE_BREACH',
                'FENCE_APPROACH',
                'ZONE_APPROACH',
              }.contains(a.type),
        )
        .map((a) => a.fenceId)
        .toSet()
        .length;
    final feverOver6h = activeAlerts.where((a) {
      if (a.type != 'TEMPERATURE_ABNORMAL') return false;
      final t = DateTime.tryParse(a.occurredAt ?? '');
      return t != null && now.difference(t).inHours >= 6;
    }).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeroCard(
            context,
            stats: stats,
            farmName: farmName,
            overview: overview,
            criticalCount: overview.overallStats.criticalCount,
            outsideFenceCount: overview.overallStats.outsideFenceCount,
            severeAlertCount: activeAlerts
                .where((a) => a.severity == 'CRITICAL')
                .length,
          ),
          _buildNeedsAttentionSection(
            context,
            fenceTotal: fenceTotal,
            fenceUnread: fenceUnread,
            healthTotal: healthTotal,
            deviceAlerts: deviceAlerts,
            breachedFences: breachedFences,
            scene: scene,
          ),
          if (scene != null) ...[
            _buildSceneSection(context, scene, feverOver6h: feverOver6h),
            const SizedBox(height: AppSpacing.sm),
            _buildAiCard(context, scene.ai),
          ],
        ],
      ),
    );
  }

  /// Hero 晨报卡：渐变 + 日期/牧场名 + 按健康率生成标题（裁决 24）+ 环形 + 两枚 chip。
  Widget _buildHeroCard(
    BuildContext context, {
    required dynamic stats,
    required String farmName,
    required RanchOverview overview,
    required int criticalCount,
    required int outsideFenceCount,
    required int severeAlertCount,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final weekdays = [
      l10n.weekday0,
      l10n.weekday1,
      l10n.weekday2,
      l10n.weekday3,
      l10n.weekday4,
      l10n.weekday5,
      l10n.weekday6,
    ];
    final dateText = l10n.heroDatePattern(
      now.month,
      now.day,
      weekdays[now.weekday % 7],
    );

    final double rate = stats?.healthyRate ?? 0;
    final total = stats?.totalLivestock ?? 0;
    final healthy = (rate * total).round();
    final attentionLabels = <String>[
      if (criticalCount > 0) l10n.heroAttentionHealth(criticalCount),
      if (outsideFenceCount > 0) l10n.heroAttentionOutside(outsideFenceCount),
      if (severeAlertCount > 0) l10n.heroAttentionAlerts(severeAlertCount),
    ];
    final isCalm = rate >= 0.95 &&
        criticalCount == 0 &&
        outsideFenceCount == 0 &&
        severeAlertCount == 0;
    final title = isCalm
        ? l10n.heroTitleCalm
        : attentionLabels.length == 1
            ? attentionLabels.single
            : l10n.heroTitleNeedsAttention;
    final online = stats?.deviceOnlineRate ?? 0;
    final criticalLivestock = overview.livestockMarkers
        .where((marker) => marker.healthStatus == 'CRITICAL')
        .toList();
    final outsideFenceLivestock = _outsideFenceLivestock(overview);
    final severeAlerts = overview.alerts
        .where((alert) => alert.status == 'ACTIVE' && alert.severity == 'CRITICAL')
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, 0.62, 1],
          colors: [_heroGrad1, _heroGrad2, _heroGrad3],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            farmName.isNotEmpty ? '$dateText · $farmName' : dateText,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.heroSub(healthy, total),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 64,
                height: 64,
                child: CustomPaint(
                  painter: _RingProgressPainter(
                    progress: rate.clamp(0.0, 1.0),
                    track: Colors.white.withValues(alpha: 0.22),
                    progressColor: _heroRing,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(rate * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          l10n.heroRingLabel,
                          style: TextStyle(
                            fontSize: 7,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (attentionLabels.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (criticalCount > 0)
                  _buildAttentionChip(
                    label: l10n.heroAttentionHealth(criticalCount),
                    icon: Icons.monitor_heart_outlined,
                    color: AppColors.danger,
                    onTap: () => _showCriticalLivestockSheet(
                      context,
                      overview,
                      criticalLivestock,
                    ),
                  ),
                if (outsideFenceCount > 0)
                  _buildAttentionChip(
                    label: l10n.heroAttentionOutside(outsideFenceCount),
                    icon: Icons.fence,
                    color: AppColors.warning,
                    onTap: () => _showOutsideFenceSheet(
                      context,
                      overview,
                      outsideFenceLivestock,
                    ),
                  ),
                if (severeAlertCount > 0)
                  _buildAttentionChip(
                    label: l10n.heroAttentionAlerts(severeAlertCount),
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.danger,
                    onTap: () => _showSevereAlertSheet(
                      context,
                      overview,
                      severeAlerts,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(child: _heroChip('$total', l10n.heroChipHead)),
              const SizedBox(width: 7),
              Expanded(
                child: _heroChip(
                  '${(online * 100).round()}%',
                  l10n.heroChipDevice,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCriticalLivestockSheet(
    BuildContext context,
    RanchOverview overview,
    List<RanchLivestockMarker> livestock,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.55,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.monitor_heart_outlined,
                        size: 16,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          l10n.ranchCriticalLivestockTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                  child: Text(
                    livestock.isEmpty
                        ? l10n.ranchCriticalLivestockEmpty
                        : l10n.ranchCriticalLivestockHint,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    itemCount: livestock.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (sheetContext, index) {
                      final marker = livestock[index];
                      final reason = _criticalAlertLabel(
                        marker.primaryAlert,
                        AppLocalizations.of(sheetContext)!,
                      );
                      return Material(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _showLivestockDetail(context, marker, overview);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        marker.livestockCode,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        reason == null
                                            ? l10n.ranchHealthStatusCritical
                                            : '${l10n.ranchHealthStatusCritical} · $reason',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      context.push(
                        '${AppRoute.alerts.path}?asset=health&source=hero',
                      );
                    },
                    child: Text(l10n.ranchCriticalAlertHistory),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<RanchLivestockMarker> _outsideFenceLivestock(RanchOverview overview) {
    final activeFences = overview.fences
        .where((fence) => fence.active && fence.points.length >= 3)
        .toList();
    if (activeFences.isEmpty) return const [];

    return overview.livestockMarkers
        .where(
          (marker) => !activeFences.any(
            (fence) => fencePolygonContainsLatLng(
              marker.toLatLng(),
              fence.points,
            ),
          ),
        )
        .toList();
  }

  void _showAttentionDetailSheet(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String hint,
    required int itemCount,
    required Widget Function(BuildContext sheetContext, int index) itemBuilder,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.62,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: iconColor),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                  child: Text(
                    itemCount == 0
                        ? AppLocalizations.of(sheetContext)!
                            .ranchCriticalLivestockEmpty
                        : hint,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    itemCount: itemCount,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (sheetContext, index) =>
                        itemBuilder(sheetContext, index),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      onAction();
                    },
                    child: Text(actionLabel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOutsideFenceSheet(
    BuildContext context,
    RanchOverview overview,
    List<RanchLivestockMarker> livestock,
  ) {
    final l10n = AppLocalizations.of(context)!;
    _showAttentionDetailSheet(
      context,
      icon: Icons.fence,
      iconColor: AppColors.warning,
      title: l10n.ranchOutsideFenceTitle,
      hint: l10n.ranchOutsideFenceHint,
      itemCount: livestock.length,
      itemBuilder: (sheetContext, index) =>
          _outsideFenceLivestockRow(
            context,
            overview,
            livestock[index],
            sheetContext,
          ),
      actionLabel: l10n.ranchOutsideFenceView,
      onAction: () => setState(() {
        _sheetTab = 1;
        _sheetSnap = math.max(_sheetSnap, 1);
      }),
    );
  }

  Widget _outsideFenceLivestockRow(
    BuildContext context,
    RanchOverview overview,
    RanchLivestockMarker marker,
    BuildContext sheetContext,
  ) {
    final l10n = AppLocalizations.of(sheetContext)!;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          _showLivestockDetail(context, marker, overview);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marker.livestockCode,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.ranchOutsideFenceStatus,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSevereAlertSheet(
    BuildContext context,
    RanchOverview overview,
    List<RanchAlertData> alerts,
  ) {
    final l10n = AppLocalizations.of(context)!;
    _showAttentionDetailSheet(
      context,
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.danger,
      title: l10n.ranchSevereAlertTitle,
      hint: l10n.ranchSevereAlertHint,
      itemCount: alerts.length,
      itemBuilder: (sheetContext, index) =>
          _severeAlertRow(context, overview, alerts[index], sheetContext),
      actionLabel: l10n.ranchSevereAlertCenter,
      onAction: () => setState(() {
        _sheetTab = 2;
        _sheetSnap = math.max(_sheetSnap, 1);
      }),
    );
  }

  Widget _severeAlertRow(
    BuildContext context,
    RanchOverview overview,
    RanchAlertData alert,
    BuildContext sheetContext,
  ) {
    final l10n = AppLocalizations.of(sheetContext)!;
    final occurredAt = DateTime.tryParse(alert.occurredAt ?? '');
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          _openSevereAlertDetail(context, overview, alert);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      occurredAt == null
                          ? l10n.ranchTimeUnknown
                          : formatMdhm(occurredAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSevereAlertDetail(
    BuildContext context,
    RanchOverview overview,
    RanchAlertData alert,
  ) async {
    final role = ref.watch(sessionControllerProvider).role;
    if (role == null) return;
    await showAlertDetailSheet(
      context,
      role: role,
      alert: AlertItem(
        id: alert.id,
        title: alert.message,
        subtitle: _criticalAlertLabel(alert.type, AppLocalizations.of(context)!) ?? alert.type,
        priority: alert.severity,
        type: alert.type,
        stage: alert.status,
        livestockCode: overview.livestockMarkers
                .where((marker) => marker.livestockId == alert.livestockId)
                .firstOrNull
                ?.livestockCode ??
            '',
        livestockId: alert.livestockId,
        severity: alert.severity,
        read: alert.read,
        occurredAt: alert.occurredAt,
        fenceId: alert.fenceId,
        deviceCode: alert.deviceCode,
      ),
    );
  }

  String? _criticalAlertLabel(String primaryAlert, AppLocalizations l10n) {
    return switch (primaryAlert) {
      'FEVER' => l10n.ranchAlertTypeFever,
      'DIGESTIVE_ABNORMAL' => l10n.ranchAlertTypeDigestive,
      'ESTRUS' => l10n.ranchAlertTypeEstrus,
      'EPIDEMIC' => l10n.ranchAlertTypeEpidemic,
      _ => null,
    };
  }

  Widget _buildAttentionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: StadiumBorder(
        side: BorderSide(color: color.withValues(alpha: 0.55)),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroChip(String value, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.white.withValues(alpha: 0.78),
          ),
        ),
      ],
    ),
  );

  /// 需要处理段：红围栏 / 橙健康 / 白设备（0=绿"正常"，>0 升橙底）。
  Widget _buildNeedsAttentionSection(
    BuildContext context, {
    required int fenceTotal,
    required int fenceUnread,
    required int healthTotal,
    required int deviceAlerts,
    required int breachedFences,
    required dynamic scene,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final total = fenceTotal + healthTotal + deviceAlerts;

    String healthSub = l10n.tileHealthSubNone;
    if (scene != null) {
      if (scene.fever.abnormalCount > 0) {
        healthSub = l10n.tileHealthSubFever;
      } else if (scene.digestive.abnormalCount > 0) {
        healthSub = l10n.tileHealthSubDigestive;
      } else if (scene.estrus.highScoreCount > 0) {
        healthSub = l10n.tileHealthSubEstrus;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 13),
        Row(
          children: [
            Container(
              width: 3,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              l10n.secNeedsAttention,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              l10n.secNeedsAttentionTotal(total),
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: RanchSummaryTile(
                  colored: fenceTotal > 0,
                  c1: _tileRed1,
                  c2: _tileRed2,
                  label: l10n.tileFence,
                  big: '$fenceTotal',
                  sub: fenceTotal > 0
                      ? l10n.tileFenceSub(breachedFences)
                      : l10n.tileFenceSubClear,
                  subColor: AppColors.success,
                  badge: fenceUnread,
                  onTap: () => context.push(
                    '${AppRoute.alerts.path}?asset=fence&source=overview',
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: RanchSummaryTile(
                  colored: healthTotal > 0,
                  c1: _tileOrange1,
                  c2: _tileOrange2,
                  label: l10n.tileHealth,
                  big: '$healthTotal',
                  sub: healthSub,
                  subColor: AppColors.textSecondary,
                  onTap: () => context.push(
                    '${AppRoute.alerts.path}?asset=health&source=overview',
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: RanchSummaryTile(
                  colored: deviceAlerts > 0,
                  c1: _tileOrange1,
                  c2: _tileOrange2,
                  label: l10n.tileDevice,
                  big: '$deviceAlerts',
                  sub: deviceAlerts > 0
                      ? l10n.tileDeviceAbnormal
                      : l10n.tileDeviceNormal,
                  subColor: deviceAlerts > 0
                      ? AppColors.textSecondary
                      : AppColors.success,
                  onTap: () => context.push(
                    '${AppRoute.alerts.path}?asset=device&source=overview',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 健康管理段：2×2 场景卡（状态胶囊 + 人话副标）。
  Widget _buildSceneSection(
    BuildContext context,
    dynamic scene, {
    required int feverOver6h,
  }) {
    final l10n = AppLocalizations.of(context)!;

    Widget pill(Color color, String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );

    Widget card({
      required IconData icon,
      required Color color,
      required String name,
      required Widget statusPill,
      required String foot,
      TextSpan? footBold,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 14, color: color),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  statusPill,
                ],
              ),
              const SizedBox(height: 6),
              if (footBold != null)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: foot,
                        style: const TextStyle(
                          fontSize: 9,
                          height: 1.3,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      footBold,
                    ],
                  ),
                )
              else
                Text(
                  foot,
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1.3,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final feverN = scene.fever.abnormalCount - scene.fever.elevatedCount;
    final lowN = scene.fever.elevatedCount;
    final epiRate = (scene.epidemic.abnormalRate * 100).toStringAsFixed(1);
    final epiOver = scene.epidemic.abnormalRate >= 0.10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 13),
        Row(
          children: [
            Container(
              width: 3,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              l10n.secHealthMgmt,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              l10n.secHealthAll,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 7,
          crossAxisSpacing: 7,
          childAspectRatio: 3.75,
          children: [
            card(
              icon: Icons.thermostat,
              color: const Color(0xFFD97B29),
              name: l10n.ranchSceneFeverMgmt,
              statusPill: scene.fever.abnormalCount == 0
                  ? pill(AppColors.success, l10n.pillSteady)
                  : pill(
                      scene.fever.criticalCount > 0
                          ? AppColors.danger
                          : AppColors.warning,
                      l10n.pillAbnormal(scene.fever.abnormalCount),
                    ),
              foot: scene.fever.abnormalCount == 0
                  ? l10n.sceneFeverCalm
                  : l10n.sceneFeverFoot(feverN, lowN),
              footBold: scene.fever.abnormalCount > 0 && feverOver6h > 0
                  ? TextSpan(
                      text: l10n.sceneFeverFootOver(feverOver6h),
                      style: const TextStyle(
                        fontSize: 9,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    )
                  : null,
              onTap: () => context.push(AppRoute.twinFever.path),
            ),
            card(
              icon: Icons.grain,
              color: const Color(0xFF8D6E4F),
              name: l10n.ranchSceneDigestiveMgmt,
              statusPill: scene.digestive.abnormalCount == 0
                  ? pill(AppColors.success, l10n.pillSteady)
                  : pill(
                      AppColors.warning,
                      l10n.pillAbnormal(scene.digestive.abnormalCount),
                    ),
              foot: scene.digestive.abnormalCount == 0
                  ? l10n.sceneDigestiveCalm
                  : l10n.sceneDigestiveFoot(scene.digestive.abnormalCount),
              onTap: () => context.push(AppRoute.twinDigestive.path),
            ),
            card(
              icon: Icons.favorite,
              color: AppColors.estrus,
              name: l10n.ranchSceneEstrusMgmt,
              statusPill: scene.estrus.highScoreCount == 0
                  ? pill(AppColors.success, l10n.pillSteady)
                  : pill(
                      AppColors.estrus,
                      l10n.pillHigh(scene.estrus.highScoreCount),
                    ),
              foot: scene.estrus.highScoreCount == 0
                  ? l10n.sceneEstrusCalm
                  : l10n.sceneEstrusFoot(scene.estrus.highScoreCount),
              onTap: () => context.push(AppRoute.twinEstrus.path),
            ),
            card(
              icon: Icons.shield,
              color: const Color(0xFF2E7D74),
              name: l10n.ranchSceneEpidemic,
              statusPill: epiOver
                  ? pill(AppColors.danger, l10n.pillRate(epiRate))
                  : scene.epidemic.abnormalRate > 0
                  ? pill(AppColors.warning, l10n.pillRate(epiRate))
                  : pill(AppColors.success, l10n.pillSteady),
              foot: epiOver
                  ? l10n.sceneEpidemicFootAbove(epiRate)
                  : l10n.sceneEpidemicFootBelow(epiRate),
              onTap: () => context.push(AppRoute.twinEpidemic.path),
            ),
          ],
        ),
        // 对账提示：仅场景异常数 ≠ 活跃单数时出现（裁决 23）
        _buildReconcileLine(
          context,
          scene.fever.abnormalCount +
              scene.digestive.abnormalCount +
              scene.estrus.highScoreCount,
          scene.fever.activeAlertCount +
              scene.digestive.activeAlertCount +
              scene.estrus.activeAlertCount +
              scene.epidemic.activeAlertCount +
              (scene.ai?.activeAlertCount ?? 0),
        ),
      ],
    );
  }

  /// AI 观察卡（方案 D：标题 + 摘要句 + 档位胶囊；排行入口 Phase 4 接 S5）。
  Widget _buildAiCard(BuildContext context, dynamic ai) {
    final l10n = AppLocalizations.of(context)!;
    final empty = ai == null || ai.anomalyCount == 0;
    final color = empty
        ? AppColors.textSecondary
        : ai.avgScore >= 0.7
        ? AppColors.danger
        : ai.avgScore >= 0.3
        ? AppColors.warning
        : AppColors.success;
    final band = ai.avgScore >= 0.7
        ? l10n.aiBandAlarm
        : ai.avgScore >= 0.3
        ? l10n.aiBandWatch
        : l10n.aiBandCalm;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy, size: 15, color: AppColors.info),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.aiObserveTitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  empty
                      ? l10n.aiNotReady
                      : l10n.aiSummaryWatching(ai.anomalyCount),
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!empty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                band,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 琥珀对账条：场景异常数与活跃健康单不一致时提醒（一致时不渲染）。
  Widget _buildReconcileLine(
    BuildContext context,
    int sceneAbnormal,
    int tickets,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (sceneAbnormal == tickets) return const SizedBox.shrink();
    final diff = (tickets - sceneAbnormal).abs();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 12, color: AppColors.warning),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '${l10n.reconcileSceneAbnormal} $sceneAbnormal ${l10n.reconcileHeadUnit} · ${l10n.reconcileActiveTickets} $tickets ${l10n.reconcileTicketUnit} · ${l10n.reconcileOffBy}$diff${l10n.recHint}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning.withValues(alpha: 0.95),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fallback grouping of overview alerts while the summary endpoint loads.
  int _clientGroupCount(RanchOverview overview, String group) {
    const fenceTypes = {'FENCE_BREACH', 'FENCE_APPROACH', 'ZONE_APPROACH'};
    const deviceTypes = {'DEVICE_TAMPER', 'DEVICE_LOW_BATTERY'};
    final groups = <String, Set<String>>{
      'fence': fenceTypes,
      'device': deviceTypes,
      'health': const {
        'TEMPERATURE_ABNORMAL',
        'DIGESTIVE_ABNORMAL',
        'ESTRUS',
        'EPIDEMIC',
        'AI_ANOMALY',
      },
    };
    final types = groups[group]!;
    return overview.alerts
        .where((a) => a.status == 'ACTIVE' && types.contains(a.type))
        .length;
  }

  Widget _buildAlertsTab(
    BuildContext context,
    RanchOverview overview,
    RanchAlertSummary? summary,
  ) {
    final farmId = ref.watch(farmSwitcherControllerProvider).activeFarmId;
    final asyncData = farmId == null
        ? const AsyncLoading<AlertWorkbenchData>()
        : ref.watch(ranchAlertWorkbenchProvider(farmId));
    return asyncData.when(
      data: (data) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: AlertWorkbenchView(
          data: data,
          selectedBucket: 'all',
          selectedAsset: const {'all'},
          onBucket: (bucket) => context.push(
            '${AppRoute.alerts.path}?bucket=$bucket&source=overview',
          ),
          onAsset: (asset) {
            final value = asset.first;
            context.push(
              '${AppRoute.alerts.path}?asset=$value&source=${value == 'fence' ? 'fence' : 'overview'}',
            );
          },
          onItem: (item) => _openWorkbenchDetail(context, item),
          onLoadMore: () async {},
          onRanking: () => showAiRankingSheet(context, data.items),
          compact: true,
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (farmId != null)
              TextButton(
                onPressed: () =>
                    ref.invalidate(ranchAlertWorkbenchProvider(farmId)),
                child: Text(AppLocalizations.of(context)!.commonRetry),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWorkbenchDetail(
    BuildContext context,
    WorkbenchItem item,
  ) async {
    final role = ref.read(sessionControllerProvider).role;
    final farmId = ref.read(farmSwitcherControllerProvider).activeFarmId;
    if (role == null || farmId == null) return;
    await showAlertWorkbenchDetailSheet(
      context,
      item: item,
      role: role,
      onMarkRead: (detail) async {
        final ids = detail.reasons
            .where((reason) => !reason.read)
            .map((reason) => reason.alertId)
            .toList();
        if (ids.isNotEmpty) {
          await const AlertsApiRepository().batchRead(ids);
        }
        ref.invalidate(ranchAlertWorkbenchProvider(farmId));
        ref.invalidate(alertSummaryControllerProvider);
      },
      onDismiss: (detail) async {
        for (final reason in detail.reasons) {
          await const AlertsApiRepository().dismiss(reason.alertId);
        }
        ref.invalidate(ranchAlertWorkbenchProvider(farmId));
        ref.invalidate(alertSummaryControllerProvider);
      },
      onNavigate: (route) => context.push(route),
      onTrajectory: (detail) => showTrajectorySheet(
        context,
        detail.asset.id,
        livestockCode: detail.asset.name,
      ),
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

/// 健康率环形进度（方案 D Hero 卡，#8FD694）。
class _RingProgressPainter extends CustomPainter {
  _RingProgressPainter({
    required this.progress,
    required this.track,
    required this.progressColor,
  });

  final double progress;
  final Color track;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 4;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingProgressPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.progressColor != progressColor;
}
