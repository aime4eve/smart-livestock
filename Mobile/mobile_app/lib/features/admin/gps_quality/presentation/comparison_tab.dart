import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/web_file_utils.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/widgets/track_line_map.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

/// Tab 3: Quality comparison across devices.
/// Static: grouped by RTK point. Dynamic: grouped by route.
class ComparisonTab extends ConsumerStatefulWidget {
  const ComparisonTab({super.key});

  @override
  ConsumerState<ComparisonTab> createState() => _ComparisonTabState();
}

class _ComparisonTabState extends ConsumerState<ComparisonTab> {
  // 0 = 静态（按真值点）, 1 = 动态（按路线）, 2 = 轨迹（按设备）, 3 = 线路（按标准轨迹）
  int _segment = 0;
  int? _selectedRtkPointId;
  int? _selectedRouteId;
  // LINE comparison state (NIX-68, spatial matching: no time window)
  int? _selectedTrackLineId;
  final Set<String> _lineDevices = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rtkPoints = ref.watch(rtkPointsProvider).value ?? [];
    final routes = ref.watch(dynamicRoutesProvider).value ?? [];
    final trackLines = ref.watch(trackLinesProvider).value ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Filter bar
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(children: [
              // Type toggle
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(value: 0,
                    icon: const Icon(Icons.location_on, size: 16),
                    label: Text(l10n.gpsQualityTestTypeStatic, style: const TextStyle(fontSize: 12))),
                  ButtonSegment(value: 1,
                    icon: const Icon(Icons.directions_walk, size: 16),
                    label: Text(l10n.gpsQualityTestTypeDynamic, style: const TextStyle(fontSize: 12))),
                  ButtonSegment(value: 2,
                    icon: const Icon(Icons.satellite_alt, size: 16),
                    label: Text(l10n.gpsQualityTrajectoryChecks, style: const TextStyle(fontSize: 12))),
                  ButtonSegment(value: 3,
                    icon: const Icon(Icons.alt_route, size: 16),
                    label: Text(l10n.gpsQualityLineCheck, style: const TextStyle(fontSize: 12))),
                ],
                selected: {_segment},
                onSelectionChanged: (v) => setState(() {
                  _segment = v.first;
                  _selectedRtkPointId = null;
                  _selectedRouteId = null;
                  _selectedTrackLineId = null;
                  _lineDevices.clear();
                }),
              ),
              const SizedBox(width: AppSpacing.lg),
              // Point/Route/Track-line filter
              if (_segment == 0)
                Expanded(child: DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: l10n.gpsQualitySelectRtkPoint,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  initialValue: _selectedRtkPointId,
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.gpsQualityRtkPointList, style: const TextStyle(fontSize: 13))),
                    ...rtkPoints.map((p) => DropdownMenuItem(value: p.id,
                      child: Text('${p.pointLabel} - ${p.locationName}', style: const TextStyle(fontSize: 13)))),
                  ],
                  onChanged: (v) => setState(() => _selectedRtkPointId = v),
                ))
              else if (_segment == 1)
                Expanded(child: DropdownButtonFormField<int>(
                  key: const Key('dynamic-route-dropdown'),
                  decoration: InputDecoration(
                    labelText: l10n.gpsQualitySelectRoute,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  initialValue: _selectedRouteId,
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.gpsQualityRouteList, style: const TextStyle(fontSize: 13))),
                    ...routes.map((r) => DropdownMenuItem(value: r.id,
                      child: Text(r.name, style: const TextStyle(fontSize: 13)))),
                  ],
                  onChanged: (v) => setState(() => _selectedRouteId = v),
                ))
              else if (_segment == 3)
                Expanded(child: DropdownButtonFormField<int>(
                  key: const Key('line-track-line-dropdown'),
                  decoration: InputDecoration(
                    labelText: l10n.gpsQualityLineSelectTrack,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  initialValue: _selectedTrackLineId,
                  isExpanded: true,
                  items: trackLines.map((l) => DropdownMenuItem(value: l.id,
                    child: Text(
                      '${l.selected ? '★ ' : ''}${l.name}'
                      '（${l10n.gpsQualityTrackLinePointLength(l.pointCount, l.lengthM.toStringAsFixed(0))}）',
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ))).toList(),
                  onChanged: (v) => setState(() {
                    _selectedTrackLineId = v;
                    _lineDevices.clear();
                  }),
                )),
            ]),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Comparison body
        if (_segment == 0)
          _buildStaticComparison(l10n, rtkPoints)
        else if (_segment == 1)
          _buildDynamicComparison(l10n)
        else if (_segment == 2)
          _buildTrajectoryComparison(l10n)
        else
          _buildLineComparison(l10n),
      ]),
    );
  }

  // ── Static comparison ────────────────────────────────────────────

  Widget _buildStaticComparison(AppLocalizations l10n, List<RtkPoint> rtkPoints) {
    if (_selectedRtkPointId == null) {
      return const Card(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_alt_outlined, size: 40, color: AppColors.textSecondary),
                SizedBox(height: AppSpacing.sm),
                Text('请选择一个 RTK 点位查看对比', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }
    final rtk = rtkPoints.where((p) => p.id == _selectedRtkPointId).firstOrNull;
    return _buildStaticPanel(l10n, _selectedRtkPointId!, rtk);
  }

  Widget _buildStaticPanel(AppLocalizations l10n, int rtkPointId, RtkPoint? rtk) {
    final comparisonAsync = ref.watch(comparisonProvider(rtkPointId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: comparisonAsync.when(
          loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('$e', style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          data: (result) {
            final devices = result.devices;
            if (devices.isEmpty) return const SizedBox.shrink();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('${rtk?.pointLabel ?? "#$rtkPointId"} · ${rtk?.locationName ?? ""}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                  child: Text('${devices.length} 台设备',
                    style: const TextStyle(fontSize: 11, color: AppColors.primary))),
              ]),
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  columns: [
                    DataColumn(label: Text(l10n.gpsQualityDevice, style: const TextStyle(fontSize: 12))),
                    DataColumn(label: Text(l10n.gpsQualityTipMaxError, style: const TextStyle(fontSize: 12))),
                    const DataColumn(label: Text('P95', style: TextStyle(fontSize: 12))),
                    const DataColumn(label: Text('P50', style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text(l10n.gpsQualityTipMeanError, style: const TextStyle(fontSize: 12))),
                    DataColumn(label: Text(l10n.gpsQualityTipEffectivePoints, style: const TextStyle(fontSize: 12))),
                    DataColumn(label: Text(l10n.gpsQualityTipJitterDiameter, style: const TextStyle(fontSize: 12))),
                  ],
                  rows: devices.map((d) {
                    final s = d.stats;
                    return DataRow(cells: [
                      DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                        _GradeBadge(grade: d.grade),
                        const SizedBox(width: 8),
                        Text(d.deviceCode, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ])),
                      DataCell(Text('${s.maxError.toStringAsFixed(1)}m', style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${s.p95.toStringAsFixed(1)}m',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: s.p95 <= 10 ? AppColors.success : s.p95 <= 25 ? AppColors.warning : AppColors.danger))),
                      DataCell(Text('${s.p50.toStringAsFixed(1)}m', style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${s.meanError.toStringAsFixed(1)}m', style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${s.effectivePoints}', style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${s.jitterDiameter.toStringAsFixed(1)}m', style: const TextStyle(fontSize: 12))),
                    ]);
                  }).toList(),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  // ── Dynamic comparison ───────────────────────────────────────────

  Widget _buildDynamicComparison(AppLocalizations l10n) {
    if (_selectedRouteId == null) {
      return Card(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.route, size: 40, color: AppColors.textSecondary),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.gpsQualitySelectRoutePrompt,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }
    final comparisonAsync =
        ref.watch(dynamicComparisonProvider(_selectedRouteId!));

    return Card(
      key: const Key('dynamic-comparison-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: comparisonAsync.when(
          loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('$e', style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          data: (result) {
            final devices = result.devices;
            if (devices.isEmpty) {
              return Text(l10n.gpsQualityNoData,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12));
            }
            // Best rows: highest coverage, lowest error metrics
            final bestCoverage = devices.map((d) => d.coverage).reduce((a, b) => a > b ? a : b);
            final bestMeanError = devices.map((d) => d.meanError).reduce((a, b) => a < b ? a : b);
            final bestP50 = devices.map((d) => d.p50).reduce((a, b) => a < b ? a : b);
            final bestP95 = devices.map((d) => d.p95).reduce((a, b) => a < b ? a : b);
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(result.routeName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                  child: Text(l10n.gpsQualityDeviceCount(devices.length),
                    style: const TextStyle(fontSize: 11, color: AppColors.primary))),
              ]),
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  key: const Key('dynamic-comparison-table'),
                  columnSpacing: 16,
                  columns: [
                    DataColumn(label: Text(l10n.gpsQualityDeviceCode, style: const TextStyle(fontSize: 12))),
                    DataColumn(label: Text(l10n.gpsQualityDeviceEui, style: const TextStyle(fontSize: 12))),
                    DataColumn(label: Text(l10n.gpsQualityDynamicCoverage, style: const TextStyle(fontSize: 12))),
                    DataColumn(label: Text(l10n.gpsQualityDynamicMatched, style: const TextStyle(fontSize: 12))),
                    DataColumn(label: Text(l10n.gpsQualityDynamicMissed, style: const TextStyle(fontSize: 12))),
                    DataColumn(label: Text(l10n.gpsQualityDynamicAmbiguous, style: const TextStyle(fontSize: 12))),
                    DataColumn(label: Text(l10n.gpsQualityDynamicOrderOk, style: const TextStyle(fontSize: 12))),
                    DataColumn(label: Text(l10n.gpsQualityTipMeanError, style: const TextStyle(fontSize: 12))),
                    const DataColumn(label: Text('P50', style: TextStyle(fontSize: 12))),
                    const DataColumn(label: Text('P95', style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text(l10n.gpsQualityTimeRange, style: const TextStyle(fontSize: 12))),
                  ],
                  rows: devices.map((d) {
                    final timeRange = d.startedAt != null
                      ? '${DateFormat('MM-dd HH:mm').format(d.startedAt!)} → ${d.endedAt != null ? DateFormat('MM-dd HH:mm').format(d.endedAt!) : "..."}'
                      : '-';
                    return DataRow(cells: [
                      DataCell(Text(d.deviceCode, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                      DataCell(Text(d.eui.isEmpty ? '-' : d.eui, style: const TextStyle(fontSize: 12))),
                      DataCell(_metricCell('${d.coverage.toStringAsFixed(1)}%', d.coverage == bestCoverage)),
                      DataCell(Text('${d.matchedCount}', style: const TextStyle(fontSize: 12, color: AppColors.success))),
                      DataCell(Text('${d.missedCount}', style: TextStyle(fontSize: 12, color: d.missedCount > 0 ? AppColors.danger : AppColors.textPrimary))),
                      DataCell(Text('${d.ambiguousCount}', style: TextStyle(fontSize: 12, color: d.ambiguousCount > 0 ? AppColors.warning : AppColors.textPrimary))),
                      DataCell(Text(d.inOrder ? '✅' : '❌', style: const TextStyle(fontSize: 12))),
                      DataCell(_metricCell('${d.meanError.toStringAsFixed(1)}m', d.meanError == bestMeanError)),
                      DataCell(_metricCell('${d.p50.toStringAsFixed(1)}m', d.p50 == bestP50)),
                      DataCell(_metricCell('${d.p95.toStringAsFixed(1)}m', d.p95 == bestP95)),
                      DataCell(Text(timeRange, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                    ]);
                  }).toList(),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  /// Metric cell — best value highlighted in bold success green.
  Widget _metricCell(String text, bool isBest) {
    return Text(text, style: TextStyle(
      fontSize: 12,
      fontWeight: isBest ? FontWeight.w700 : FontWeight.w400,
      color: isBest ? AppColors.success : AppColors.textPrimary,
    ));
  }

  // ── Trajectory comparison (NIX-22) ─────────────────────────────

  Widget _buildTrajectoryComparison(AppLocalizations l10n) {
    final comparisonAsync = ref.watch(trajectoryComparisonProvider);

    return Card(
      key: const Key('trajectory-comparison-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: comparisonAsync.when(
          loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('$e', style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          data: (devices) {
            if (devices.isEmpty) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.satellite_alt, size: 40, color: AppColors.textSecondary),
                    const SizedBox(height: AppSpacing.sm),
                    Text(l10n.gpsQualityTrajectoryEmpty,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ]),
                ),
              );
            }
            final bestP95 = devices.map((d) => d.p95).reduce((a, b) => a < b ? a : b);
            final bestPairRate = devices.map((d) => d.pairRate).reduce((a, b) => a > b ? a : b);
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(l10n.gpsQualityTrajectoryComparison,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                  child: Text(l10n.gpsQualityDeviceCount(devices.length),
                    style: const TextStyle(fontSize: 11, color: AppColors.primary))),
              ]),
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  key: const Key('trajectory-comparison-table'),
                  columnSpacing: 16,
                  columns: [
                    DataColumn(label: Text(l10n.gpsQualityDeviceCode, style: const TextStyle(fontSize: 12))),
                    DataColumn(label: Text(l10n.gpsQualityTrajectoryPoints, style: const TextStyle(fontSize: 12))),
                    DataColumn(label: Text(l10n.gpsQualityPaired, style: const TextStyle(fontSize: 12))),
                    DataColumn(label: Text(l10n.gpsQualityPairRate, style: const TextStyle(fontSize: 12))),
                    DataColumn(label: Text(l10n.gpsQualityTipMeanError, style: const TextStyle(fontSize: 12))),
                    const DataColumn(label: Text('P50', style: TextStyle(fontSize: 12))),
                    const DataColumn(label: Text('P95', style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text(l10n.gpsQualityTimeRange, style: const TextStyle(fontSize: 12))),
                  ],
                  rows: devices.map((d) {
                    final timeRange = d.startedAt != null
                      ? '${DateFormat('MM-dd HH:mm').format(d.startedAt!)} → ${d.endedAt != null ? DateFormat('MM-dd HH:mm').format(d.endedAt!) : "..."}'
                      : '-';
                    return DataRow(cells: [
                      DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                        _GradeBadge(grade: d.grade),
                        const SizedBox(width: 8),
                        Text(d.deviceCode, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ])),
                      DataCell(Text('${d.totalPoints}', style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${d.paired}', style: const TextStyle(fontSize: 12, color: AppColors.success))),
                      DataCell(_metricCell('${d.pairRate.toStringAsFixed(1)}%', d.pairRate == bestPairRate)),
                      DataCell(Text('${d.meanError.toStringAsFixed(1)}m', style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${d.p50.toStringAsFixed(1)}m', style: const TextStyle(fontSize: 12))),
                      DataCell(_metricCell('${d.p95.toStringAsFixed(1)}m', d.p95 == bestP95)),
                      DataCell(Text(timeRange, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                    ]);
                  }).toList(),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  // ── LINE comparison (NIX-68) ───────────────────────────────────

  /// Device track color palette, cycled by row index (spec §8.6).
  static const _lineDeviceColors = [
    Color(0xFFC2564B),
    Color(0xFFD97706),
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFF0EA5E9),
    Color(0xFF16A34A),
  ];

  Widget _buildLineComparison(AppLocalizations l10n) {
    // Spatial matching: picking a track line in the filter bar loads the
    // comparison immediately; device chips toggle per-device tracks.
    if (_selectedTrackLineId == null) {
      return Card(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.alt_route, size: 40, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.gpsQualityLineSelectTrackPrompt,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ]),
          ),
        ),
      );
    }

    final query = (
      trackLineId: _selectedTrackLineId!,
      deviceCode: null,
    );
    final comparisonAsync = ref.watch(lineComparisonProvider(query));

    return Card(
      key: const Key('line-comparison-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: comparisonAsync.when(
          loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('$e', style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          data: (result) => _buildLineComparisonBody(l10n, result),
        ),
      ),
    );
  }

  Widget _buildLineComparisonBody(AppLocalizations l10n, LineComparisonResult result) {
    final rows = result.rows;
    if (rows.isEmpty) {
      return Text(l10n.gpsQualityLineComparisonEmpty,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12));
    }

    // Lazily load each selected device's track points (spec §7.6).
    final devicePolylines = <Polyline>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (!_lineDevices.contains(row.deviceCode)) continue;
      final trackAsync = ref.watch(lineComparisonProvider((
        trackLineId: _selectedTrackLineId!,
        deviceCode: row.deviceCode,
      )));
      final pts = trackAsync.value?.deviceTrack;
      if (pts != null && pts.length >= 2) {
        devicePolylines.add(Polyline(
          points: pts.map((p) => LatLng(p.lat, p.lng)).toList(),
          color: _lineDeviceColors[i % _lineDeviceColors.length],
          strokeWidth: 2,
          pattern: StrokePattern.dashed(segments: const [5, 4]),
        ));
      }
    }
    final trackLatLngs =
        result.trackLine.map((p) => LatLng(p.lat, p.lng)).toList();
    final polylines = <Polyline>[
      ...devicePolylines,
      if (trackLatLngs.length >= 2)
        Polyline(
          points: trackLatLngs,
          color: AppColors.primary,
          strokeWidth: 3.5,
        ),
    ];
    final markers = <Marker>[
      if (trackLatLngs.isNotEmpty) ...[
        Marker(point: trackLatLngs.first, width: 14, height: 14,
          child: const TrackDotMarker(color: AppColors.primary)),
        Marker(point: trackLatLngs.last, width: 14, height: 14,
          child: const TrackDotMarker(color: AppColors.primary)),
      ],
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(l10n.gpsQualityLineComparison,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
          child: Text(l10n.gpsQualityDeviceCount(rows.length),
            style: const TextStyle(fontSize: 11, color: AppColors.primary))),
        const SizedBox(width: 8),
        TextButton.icon(
          key: const Key('line-comparison-export'),
          onPressed: rows.isEmpty ? null : () => _exportLineCsv(l10n, rows),
          icon: const Icon(Icons.download, size: 16),
          label: Text(l10n.gpsQualityLineExportCsv,
              style: const TextStyle(fontSize: 12)),
        ),
      ]),
      const SizedBox(height: AppSpacing.sm),
      // Device chips (toggle to load that device's track onto the map)
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (var i = 0; i < rows.length; i++)
          _deviceChip(l10n, rows[i], _lineDeviceColors[i % _lineDeviceColors.length]),
      ]),
      const SizedBox(height: AppSpacing.sm),
      TrackLineMap(
        key: const Key('line-comparison-map'),
        polylines: polylines,
        markers: markers,
        height: 320,
      ),
      const SizedBox(height: AppSpacing.sm),
      Wrap(spacing: AppSpacing.lg, children: [
        _legend(AppColors.primary, l10n.gpsQualityLineMapStandard),
        for (var i = 0; i < rows.length; i++)
          if (_lineDevices.contains(rows[i].deviceCode))
            _legend(_lineDeviceColors[i % _lineDeviceColors.length],
              '${rows[i].deviceCode} (${rows[i].sampleCount})'),
      ]),
      const SizedBox(height: AppSpacing.md),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          key: const Key('line-comparison-table'),
          columnSpacing: 16,
          columns: [
            DataColumn(label: Text(l10n.gpsQualityDeviceCode, style: const TextStyle(fontSize: 12))),
            DataColumn(label: Text(l10n.gpsQualityLineSamples, style: const TextStyle(fontSize: 12))),
            DataColumn(label: Text(l10n.gpsQualityLineTripCount, style: const TextStyle(fontSize: 12))),
            DataColumn(label: Text(l10n.gpsQualityLineMeanDeviation, style: const TextStyle(fontSize: 12))),
            const DataColumn(label: Text('P50', style: TextStyle(fontSize: 12))),
            const DataColumn(label: Text('P95', style: TextStyle(fontSize: 12))),
            DataColumn(label: Text(l10n.gpsQualityLineMaxDeviation, style: const TextStyle(fontSize: 12))),
            DataColumn(label: Text(l10n.gpsQualityLineWithin15m, style: const TextStyle(fontSize: 12))),
            DataColumn(label: Text(l10n.gpsQualityLineWithin25m, style: const TextStyle(fontSize: 12))),
            DataColumn(label: Text(l10n.gpsQualityLineWithin40m, style: const TextStyle(fontSize: 12))),
            DataColumn(label: Text(l10n.gpsQualitySummaryGrade, style: const TextStyle(fontSize: 12))),
          ],
          rows: [
            for (var i = 0; i < rows.length; i++)
              DataRow(cells: [
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 9, height: 9,
                    decoration: BoxDecoration(
                      color: _lineDeviceColors[i % _lineDeviceColors.length],
                      shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(rows[i].deviceCode, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ])),
                DataCell(Text('${rows[i].sampleCount}', style: const TextStyle(fontSize: 12))),
                DataCell(Text('${rows[i].tripCount}', style: const TextStyle(fontSize: 12))),
                DataCell(Text('${rows[i].mean.toStringAsFixed(1)}m', style: const TextStyle(fontSize: 12))),
                DataCell(Text('${rows[i].p50.toStringAsFixed(1)}m', style: const TextStyle(fontSize: 12))),
                DataCell(Text('${rows[i].p95.toStringAsFixed(1)}m',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: rows[i].p95 <= 15 ? AppColors.success : rows[i].p95 <= 25 ? AppColors.warning : AppColors.danger))),
                DataCell(Text('${rows[i].max.toStringAsFixed(1)}m', style: const TextStyle(fontSize: 12))),
                DataCell(Text('${rows[i].within15mPct.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12))),
                DataCell(Text('${rows[i].within25mPct.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12))),
                DataCell(Text('${rows[i].within40mPct.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12))),
                DataCell(_GradeBadge(grade: rows[i].grade)),
              ]),
          ],
        ),
      ),
    ]);
  }

  /// Export the LINE comparison table as a UTF-8 (BOM) CSV for Excel.
  Future<void> _exportLineCsv(
      AppLocalizations l10n, List<LineComparisonRow> rows) async {
    String esc(String v) =>
        v.contains(',') || v.contains('"') || v.contains('\n')
            ? '"${v.replaceAll('"', '""')}"'
            : v;
    final sb = StringBuffer('﻿');
    sb.writeln([
      l10n.gpsQualityDeviceCode,
      l10n.gpsQualityLineSamples,
      l10n.gpsQualityLineTripCount,
      '${l10n.gpsQualityLineMeanDeviation}(m)',
      'P50(m)',
      'P95(m)',
      '${l10n.gpsQualityLineMaxDeviation}(m)',
      '${l10n.gpsQualityLineWithin15m}(%)',
      '${l10n.gpsQualityLineWithin25m}(%)',
      '${l10n.gpsQualityLineWithin40m}(%)',
      l10n.gpsQualitySummaryGrade,
    ].map(esc).join(','));
    for (final r in rows) {
      sb.writeln([
        r.deviceCode,
        '${r.sampleCount}',
        '${r.tripCount}',
        r.mean.toStringAsFixed(1),
        r.p50.toStringAsFixed(1),
        r.p95.toStringAsFixed(1),
        r.max.toStringAsFixed(1),
        r.within15mPct.toStringAsFixed(1),
        r.within25mPct.toStringAsFixed(1),
        r.within40mPct.toStringAsFixed(1),
        r.grade.name.toUpperCase(),
      ].map(esc).join(','));
    }
    final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    await downloadBytes(
        'line-comparison-$stamp.csv', utf8.encode(sb.toString()));
  }

  Widget _deviceChip(AppLocalizations l10n, LineComparisonRow row, Color color) {    final selected = _lineDevices.contains(row.deviceCode);
    return FilterChip(
      key: ValueKey('line-cmp-chip-${row.deviceCode}'),
      selected: selected,
      onSelected: (v) => setState(() {
        if (v) {
          _lineDevices.add(row.deviceCode);
        } else {
          _lineDevices.remove(row.deviceCode);
        }
      }),
      avatar: Container(width: 9, height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      label: Text(row.deviceCode,
        style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
      selectedColor: color.withValues(alpha: 0.15),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _legend(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 9, height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }
}

class _GradeBadge extends StatelessWidget {
  const _GradeBadge({required this.grade});
  final QualityGrade grade;
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (grade) {
      QualityGrade.excellent => ('EXCELLENT', const Color(0xFF16A34A)),
      QualityGrade.usable => ('USABLE', const Color(0xFF2563EB)),
      QualityGrade.marginal => ('MARGINAL', const Color(0xFFC2410C)),
      QualityGrade.unavailable => ('UNAVAILABLE', AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
