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
  bool _isStatic = true;
  int? _selectedRtkPointId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rtkPoints = ref.watch(rtkPointsProvider).value ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Filter bar
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(children: [
              // Type toggle
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true,
                    icon: const Icon(Icons.location_on, size: 16),
                    label: Text(l10n.gpsQualityTestTypeStatic, style: const TextStyle(fontSize: 12))),
                  ButtonSegment(value: false,
                    icon: const Icon(Icons.directions_walk, size: 16),
                    label: Text(l10n.gpsQualityTestTypeDynamic, style: const TextStyle(fontSize: 12))),
                ],
                selected: {_isStatic},
                onSelectionChanged: (v) => setState(() {
                  _isStatic = v.first;
                  _selectedRtkPointId = null;
                }),
              ),
              const SizedBox(width: AppSpacing.lg),
              // Point/Route filter
              if (_isStatic)
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
              else
                Expanded(child: Text(l10n.gpsQualityRouteList,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
            ]),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Comparison body
        if (_isStatic)
          _buildStaticComparison(l10n, rtkPoints)
        else
          _buildDynamicComparison(l10n),
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
    final routesAsync = ref.watch(dynamicRoutesProvider);
    return routesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('$e', style: const TextStyle(color: AppColors.danger)),
      data: (routes) {
        if (routes.isEmpty) {
          return Card(child: SizedBox(height: 200, child: Center(child: Column(
            mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.route, size: 40, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.gpsQualityNoData, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ]))));
        }
        return Column(
          children: routes.map((r) => _buildDynamicPanel(l10n, r)).toList(),
        );
      },
    );
  }

  Widget _buildDynamicPanel(AppLocalizations l10n, DynamicRoute route) {
    // Dynamic comparison needs a different API — for now show route info
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(route.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
              child: const Text('路线', style: TextStyle(fontSize: 11, color: AppColors.primary))),
          ]),
          if (route.description != null)
            Padding(padding: const EdgeInsets.only(top: 4),
              child: Text(route.description!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.gpsQualityDynamicNoTest, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ]),
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
