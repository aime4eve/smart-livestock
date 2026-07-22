import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

/// Tab 3: Quality comparison across devices.
/// Static: grouped by RTK point. Dynamic: grouped by route.
class ComparisonTab extends ConsumerStatefulWidget {
  const ComparisonTab({super.key});

  @override
  ConsumerState<ComparisonTab> createState() => _ComparisonTabState();
}

class _ComparisonTabState extends ConsumerState<ComparisonTab> {
  // 0 = 静态（按真值点）, 1 = 动态（按路线）, 2 = 轨迹（按设备）
  int _segment = 0;
  int? _selectedRtkPointId;
  int? _selectedRouteId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rtkPoints = ref.watch(rtkPointsProvider).value ?? [];
    final routes = ref.watch(dynamicRoutesProvider).value ?? [];

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
                ],
                selected: {_segment},
                onSelectionChanged: (v) => setState(() {
                  _segment = v.first;
                  _selectedRtkPointId = null;
                  _selectedRouteId = null;
                }),
              ),
              const SizedBox(width: AppSpacing.lg),
              // Point/Route filter
              if (_segment == 0)
                Expanded(child: DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: l10n.gpsQualitySelectRtkPoint,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  value: _selectedRtkPointId,
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
                  value: _selectedRouteId,
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.gpsQualityRouteList, style: const TextStyle(fontSize: 13))),
                    ...routes.map((r) => DropdownMenuItem(value: r.id,
                      child: Text(r.name, style: const TextStyle(fontSize: 13)))),
                  ],
                  onChanged: (v) => setState(() => _selectedRouteId = v),
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
        else
          _buildTrajectoryComparison(l10n),
      ]),
    );
  }

  // ── Static comparison ────────────────────────────────────────────

  Widget _buildStaticComparison(AppLocalizations l10n, List<RtkPoint> rtkPoints) {
    if (_selectedRtkPointId == null) {
      return Card(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_alt_outlined, size: 40, color: AppColors.textSecondary),
                const SizedBox(height: AppSpacing.sm),
                Text('请选择一个 RTK 点位查看对比', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                    DataColumn(label: Text('P95', style: const TextStyle(fontSize: 12))),
                    DataColumn(label: Text('P50', style: const TextStyle(fontSize: 12))),
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
                    DataColumn(label: Text('P50', style: const TextStyle(fontSize: 12))),
                    DataColumn(label: Text('P95', style: const TextStyle(fontSize: 12))),
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
                    DataColumn(label: Text('P50', style: const TextStyle(fontSize: 12))),
                    DataColumn(label: Text('P95', style: const TextStyle(fontSize: 12))),
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
}

class _GradeBadge extends StatelessWidget {
  const _GradeBadge({required this.grade});
  final QualityGrade grade;
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (grade) {
      QualityGrade.excellent => ('EXCELLENT', const Color(0xFF16A34A)),
      QualityGrade.usable => ('USABLE', const Color(0xFF2563EB)),
      QualityGrade.marginal => ('MARGINAL', const Color(0xFFB45309)),
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
