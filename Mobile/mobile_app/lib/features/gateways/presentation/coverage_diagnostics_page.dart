import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/map/map_config.dart';
import 'package:hkt_livestock_agentic/core/map/coord_transform.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_factory.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'gateway_controller.dart';
import 'package:latlong2/latlong.dart';

/// F8 coverage diagnostics (prototype screen 5): tier percentages, 100m-grid
/// heat map over the ranch, and rule-based gateway relocation advice.
class CoverageDiagnosticsPage extends ConsumerStatefulWidget {
  const CoverageDiagnosticsPage({super.key});

  @override
  ConsumerState<CoverageDiagnosticsPage> createState() =>
      _CoverageDiagnosticsPageState();
}

class _CoverageDiagnosticsPageState
    extends ConsumerState<CoverageDiagnosticsPage> {
  SmartTileProvider? _tileProvider;
  final _mapController = MapController();

  // Cell centroids and gateway registry positions are WGS-84. Whether they
  // are transformed to GCJ-02 for rendering follows the tiles actually
  // serving each point: 高德 online → yes; local offline/server (OSM) → no.
  LatLng _toDisplay(LatLng p) {
    final t = _tileProvider;
    return t != null && t.shouldTransformAt(p)
        ? CoordTransform.wgs84ToGcj02(p)
        : p;
  }

  @override
  void initState() {
    super.initState();
    _initTileProvider();
  }

  Future<void> _initTileProvider() async {
    final provider = await loadSmartTileProvider(
      ref,
      onSourceChanged: () {
        if (mounted) {
          setState(() {});
          _recenterOnCells();
        }
      },
    );
    if (mounted) setState(() => _tileProvider = provider);
  }

  /// Re-anchor the view when the tile source (and with it the projection)
  /// changes, so the heat circles stay centred and correctly placed.
  void _recenterOnCells() {
    final cell = _firstCell();
    if (cell != null) _mapController.move(_toDisplay(cell), 14);
  }

  LatLng? _firstCell() {
    final cells =
        (ref.read(coverageDiagnosticControllerProvider).value as Map?)?['cells'] as List?;
    if (cells == null || cells.isEmpty) return null;
    final c = cells.first as Map;
    return LatLng((c['lat'] as num).toDouble(), (c['lng'] as num).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(coverageDiagnosticControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l10n.coverageTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(e.toString(),
                style: const TextStyle(color: AppColors.textSecondary)),
            TextButton(
              onPressed: () => ref
                  .read(coverageDiagnosticControllerProvider.notifier)
                  .refresh(),
              child: Text(l10n.commonRetry),
            ),
          ]),
        ),
        data: (dataRaw) {
          final d = (dataRaw as Map?) ?? const {};
          if ((d['status'] as String?) == 'ACCUMULATING') {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Card(
                color: AppColors.infoSoft,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.sm)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(l10n.coverageAccumulating(
                      (d['daysCovered'] as num?)?.toInt() ?? 0),
                  style: const TextStyle(fontSize: 14, height: 1.6)),
                ),
              ),
            );
          }
          final cells = (d['cells'] as List?) ?? const [];
          final suggestions = (d['suggestions'] as List?) ?? const [];
          final gateways = (d['gateways'] as List?) ?? const [];
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.coverageWindowFrames(
                      (d['totalFrames'] as num?)?.toInt() ?? 0),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                _stat('${d['stablePct'] ?? 0}%', l10n.coverageStatStable,
                    AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                _stat('${d['weakPct'] ?? 0}%', l10n.coverageStatWeak,
                    AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                _stat('${d['edgePct'] ?? 0}%', l10n.coverageStatEdge,
                    AppColors.danger),
              ]),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 260,
                child: _tileProvider == null
                    ? const Center(child: CircularProgressIndicator())
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: cells.isNotEmpty
                                ? _toDisplay(LatLng(
                                    (cells.first['lat'] as num).toDouble(),
                                    (cells.first['lng'] as num).toDouble()))
                                : const LatLng(28.2280, 112.9400),
                            initialZoom: 14,
                          ),
                          children: [
                            TileLayer(
                              key: ValueKey(_tileProvider?.activeSourceName),
                              urlTemplate: _tileProvider == null
                                  ? MapConfig.tileUrlTemplate
                                  : null,
                              tileProvider: _tileProvider,
                              userAgentPackageName:
                                  'com.smartlivestock.demo',
                            ),
                            CircleLayer(
                              circles: cells.map((c) {
                                final rssi = (c['avgRssi'] as num).toDouble();
                                final color = rssi >= -90
                                    ? AppColors.success
                                    : rssi >= -100
                                        ? AppColors.warning
                                        : AppColors.danger;
                                return CircleMarker(
                                  point: _toDisplay(LatLng(
                                      (c['lat'] as num).toDouble(),
                                      (c['lng'] as num).toDouble())),
                                  radius: 60,
                                  useRadiusInMeter: true,
                                  color: color.withValues(alpha: 0.35),
                                );
                              }).toList(),
                            ),
                            MarkerLayer(
                              markers: gateways.map((g) {
                                return Marker(
                                  point: _toDisplay(LatLng(
                                      (g['lat'] as num).toDouble(),
                                      (g['lng'] as num).toDouble())),
                                  width: 26,
                                  height: 26,
                                  child: const Icon(Icons.wifi_tethering,
                                      color: AppColors.info, size: 26),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                _legend(l10n.coverageLegendGood, AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                _legend(l10n.coverageLegendPoor, AppColors.danger),
                const SizedBox(width: AppSpacing.sm),
                _legend(l10n.coverageLegendNoData, AppColors.border),
              ]),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.coverageAdviceTitle,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              for (final s in suggestions)
                _adviceCard(s as Map, l10n),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.coverageFootnote,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.6)),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String value, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
      );

  Widget _legend(String label, Color color) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ]);

  Widget _adviceCard(Map s, AppLocalizations l10n) {
    final type = (s['type'] as String?) ?? 'NONE';
    if (type == 'NONE') {
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.successSoft,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(l10n.coverageAdviceNone)),
        ]),
      );
    }
    final isAdd = type == 'ADD_GATEWAY';
    final edgeBefore = (s['edgePctBefore'] as num?)?.toDouble() ?? 0;
    final edgeAfter = (s['edgePctAfter'] as num?)?.toDouble() ?? 0;
    final gain = (s['rssiGainDb'] as num?)?.toDouble() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(
          left: BorderSide(
              width: 3, color: isAdd ? AppColors.danger : AppColors.warning),
          top: const BorderSide(color: AppColors.border),
          right: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
        ),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                  isAdd
                      ? l10n.coverageAdviceAddGateway
                      : l10n.coverageAdviceMoveAntenna(
                          (s['direction'] as String?) ?? '--'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isAdd ? AppColors.danger : AppColors.warning)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                  isAdd
                      ? l10n.coverageAdviceAtCluster
                      : l10n.coverageAdviceWeakDirection,
                  style: TextStyle(
                      fontSize: 11, color: isAdd ? AppColors.danger : AppColors.warning)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (isAdd && s['targetLat'] != null)
          Text(l10n.coverageAdviceCoord(
              (s['targetLat'] as num).toString(),
              (s['targetLng'] as num).toString()),
            style: const TextStyle(fontSize: 12)),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.coverageAdviceExpected(edgeBefore.round(), edgeAfter.round()),
            style: const TextStyle(fontSize: 12)),
        Text(l10n.coverageAdviceCaliber(gain.toStringAsFixed(0)),
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }
}
