import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/widgets/quality_grade_badge.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/widgets/scatter_chart.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/widgets/session_trajectory_sheet.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Tab 2: Quality report — multi-device comparison + statistics.
class QualityReportTab extends ConsumerStatefulWidget {
  const QualityReportTab({super.key});

  @override
  ConsumerState<QualityReportTab> createState() => _QualityReportTabState();
}

class _QualityReportTabState extends ConsumerState<QualityReportTab> {
  String? _selectedLocation;
  bool _excludeSuspect = false;
  int? _expandedSessionId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pointsAsync = ref.watch(rtkPointsProvider);

    return pointsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text('$e',
              style: const TextStyle(color: AppColors.danger)),
        ),
      ),
      data: (points) {
        final locations = _distinctLocations(points);
        if (_selectedLocation == null && locations.isNotEmpty) {
          _selectedLocation = locations.first;
        } else if (_selectedLocation != null &&
            !locations.contains(_selectedLocation)) {
          _selectedLocation = locations.isNotEmpty ? locations.first : null;
        }
        final locationPoints =
            points.where((p) => p.locationName == _selectedLocation).toList();

        return Column(
          children: [
            _buildFilterBar(l10n, locations),
            const Divider(height: 1),
            Expanded(
              child: _buildBody(l10n, locationPoints),
            ),
          ],
        );
      },
    );
  }

  // ── Filter bar ───────────────────────────────────────────────────

  Widget _buildFilterBar(AppLocalizations l10n, List<String> locations) {
    return Container(
      key: const Key('quality-filter-bar'),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      color: AppColors.surfaceAlt,
      child: Wrap(
        spacing: AppSpacing.lg,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              key: const Key('report-location-select'),
              decoration:
                  InputDecoration(labelText: l10n.gpsQualityLocationName),
              value: _selectedLocation,
              isExpanded: true,
              items: locations
                  .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedLocation = v;
                  _expandedSessionId = null;
                });
              },
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                key: const Key('exclude-suspect-checkbox'),
                value: _excludeSuspect,
                onChanged: (v) =>
                    setState(() => _excludeSuspect = v ?? false),
              ),
              GestureDetector(
                onTap: () => setState(() => _excludeSuspect = !_excludeSuspect),
                child: Text(l10n.gpsQualityExcludeSuspect,
                    style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Body: comparison table + device detail ───────────────────────

  Widget _buildBody(AppLocalizations l10n, List<RtkPoint> locationPoints) {
    if (locationPoints.isEmpty) {
      return Center(
          child: Text(l10n.gpsQualityNoData,
              style: const TextStyle(color: AppColors.textSecondary)));
    }

    // Merge comparison data across all points in the location.
    final devices = <DeviceComparison>[];
    bool anyLoading = false;
    String? errorMsg;
    for (final p in locationPoints) {
      final av = ref.watch(comparisonProvider(p.id));
      if (av.isLoading) anyLoading = true;
      if (av.hasError) errorMsg = av.error.toString();
      if (av.hasValue) devices.addAll(av.value!.devices);
    }

    if (anyLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMsg != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(errorMsg,
              style: const TextStyle(color: AppColors.danger)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _buildComparisonTable(l10n, devices),
        if (_expandedSessionId != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _DeviceDetailCard(
            key: ValueKey('device-detail-$_expandedSessionId'),
            sessionId: _expandedSessionId!,
            excludeSuspect: _excludeSuspect,
          ),
        ],
      ],
    );
  }

  Widget _buildComparisonTable(
      AppLocalizations l10n, List<DeviceComparison> devices) {
    return Card(
      key: const Key('comparison-table-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: AppSpacing.sm, bottom: AppSpacing.md),
              child: Row(
                children: [
                  Text(l10n.gpsQualityComparisonTitle,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${devices.length}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
            if (devices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xl, horizontal: AppSpacing.md),
                child: Center(
                  child: Text(l10n.gpsQualityNoData,
                      style: const TextStyle(
                          color: AppColors.textSecondary)),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  key: const Key('comparison-table'),
                  columnSpacing: 24,
                  showCheckboxColumn: false,
                  columns: [
                    DataColumn(label: Text(l10n.gpsQualityDevice)),
                    DataColumn(
                        label: _labelWithTip(
                            l10n.gpsQualityEffectivePoints, null)),
                    DataColumn(
                        label: _labelWithTip(l10n.gpsQualityP50, 'tip-50')),
                    DataColumn(
                        label:
                            _labelWithTip(l10n.gpsQualityP95, 'tip-95')),
                    DataColumn(
                        label: _labelWithTip(
                            l10n.gpsQualityJitterDiameter, 'tip-diam')),
                    DataColumn(
                        label:
                            _labelWithTip(l10n.gpsQualityOutlierCount, 'tip-out')),
                    DataColumn(label: Text(l10n.gpsQualityStatus)),
                  ],
                  rows: devices.map((d) {
                    final expanded = _expandedSessionId == d.sessionId;
                    return DataRow(
                      key: ValueKey('comparison-row-${d.sessionId}'),
                      selected: expanded,
                      onSelectChanged: (_) => setState(() {
                        _expandedSessionId =
                            expanded ? null : d.sessionId;
                      }),
                      cells: [
                        DataCell(Text(d.deviceCode,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600))),
                        DataCell(Text('${d.stats.effectivePoints}')),
                        DataCell(Text('${d.stats.p50.toStringAsFixed(1)} m')),
                        DataCell(Text('${d.stats.p95.toStringAsFixed(1)} m')),
                        DataCell(Text(
                            '${d.stats.jitterDiameter.toStringAsFixed(1)} m')),
                        DataCell(Text('${d.stats.outlierCount}')),
                        DataCell(QualityGradeBadge(grade: d.grade)),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _labelWithTip(String label, String? tipKey) {
    final l10n = AppLocalizations.of(context)!;
    if (tipKey == null) return Text(label);
    final tipText = _tipText(l10n, tipKey);
    if (tipText == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: 2),
        Tooltip(
          message: tipText,
          child: Icon(Icons.help_outline, size: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String? _tipText(AppLocalizations l10n, String key) => switch (key) {
        'tip-50' => l10n.gpsQualityTipP50,
        'tip-95' => l10n.gpsQualityTipP95,
        'tip-mean' => l10n.gpsQualityTipMeanError,
        'tip-max' => l10n.gpsQualityTipMaxError,
        'tip-diam' => l10n.gpsQualityTipJitterDiameter,
        'tip-out' => l10n.gpsQualityTipOutlier,
        _ => null,
      };
}

// ── Device detail card ─────────────────────────────────────────────

class _DeviceDetailCard extends ConsumerWidget {
  const _DeviceDetailCard({
    super.key,
    required this.sessionId,
    required this.excludeSuspect,
  });

  final int sessionId;
  final bool excludeSuspect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(qualityReportProvider(
      (sessionId: sessionId, excludeSuspect: excludeSuspect),
    ));

    return Card(
      child: reportAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text('$e',
              style: const TextStyle(color: AppColors.danger)),
        ),
        data: (report) => _DetailContent(report: report),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.report});
  final GpsQualityReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header: device + grade
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.gpsQualityDevice}: ${report.deviceCode}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${report.rtkPoint.locationName} · ${report.rtkPoint.pointLabel}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              QualityGradeBadge(grade: report.grade),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _GradeStandardPanel(),
          const SizedBox(height: AppSpacing.lg),
          _StatGrid(stats: report.stats),
          const SizedBox(height: AppSpacing.lg),
          // scatter chart
          if (report.scatter.isNotEmpty) ...[
            _SectionTitle(title: l10n.gpsQualityScatterChart),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: GpsScatterChart(
                key: const Key('scatter-chart'),
                points: report.scatter,
                p50: report.stats.p50,
                p95: report.stats.p95,
                rtkLatitude: report.rtkPoint.latitude,
                rtkLongitude: report.rtkPoint.longitude,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const _ScatterLegend(),
            const SizedBox(height: AppSpacing.lg),
          ],
          // trajectory button
          Center(
            child: OutlinedButton.icon(
              key: const Key('view-trajectory-btn'),
              icon: const Icon(Icons.timeline, size: 18),
              label: Text(l10n.gpsQualityViewTrajectory),
              onPressed: () =>
                  showSessionTrajectorySheet(
                    context,
                    report.sessionId,
                    deviceCode: report.deviceCode,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat grid ──────────────────────────────────────────────────────

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});
  final GpsQualityStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cards = <_StatData>[
      _StatData(l10n.gpsQualityTotalPoints, '${stats.totalPoints}', l10n.gpsQualityTipTotalPoints),
      _StatData(l10n.gpsQualityEffectivePoints, '${stats.effectivePoints}', l10n.gpsQualityTipEffectivePoints),
      _StatData(l10n.gpsQualitySuspectPoints, '${stats.suspectPoints}', l10n.gpsQualityTipSuspectPoints),
      _StatData(l10n.gpsQualityMeanError, '${stats.meanError.toStringAsFixed(1)} m', l10n.gpsQualityTipMeanError),
      _StatData(l10n.gpsQualityP50, '${stats.p50.toStringAsFixed(1)} m', l10n.gpsQualityTipP50),
      _StatData(l10n.gpsQualityP95, '${stats.p95.toStringAsFixed(1)} m', l10n.gpsQualityTipP95),
      _StatData(l10n.gpsQualityMaxError, '${stats.maxError.toStringAsFixed(1)} m', l10n.gpsQualityTipMaxError),
      _StatData(l10n.gpsQualityJitterDiameter, '${stats.jitterDiameter.toStringAsFixed(1)} m', l10n.gpsQualityTipJitterDiameter),
      _StatData(l10n.gpsQualityOutlierCount, '${stats.outlierCount}', l10n.gpsQualityTipOutlier),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: cards
          .map((c) => SizedBox(
                width: 150,
                child: _StatCard(data: c),
              ))
          .toList(),
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value, this.tip);
  final String label;
  final String value;
  final String? tip;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});
  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      key: Key('stat-${data.label}'),
      message: data.tip ?? data.label,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(data.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ),
                const Icon(Icons.help_outline,
                    size: 12, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 4),
            Text(data.value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ── Grade standard panel ───────────────────────────────────────────

class _GradeStandardPanel extends StatefulWidget {
  @override
  State<_GradeStandardPanel> createState() => _GradeStandardPanelState();
}

class _GradeStandardPanelState extends State<_GradeStandardPanel> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            key: const Key('grade-standard-toggle'),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
              child: Row(
                children: [
                  Icon(_open ? Icons.expand_less : Icons.expand_more,
                      size: 18, color: AppColors.primary),
                  Text(l10n.gpsQualityGradeStandard,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary)),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: Column(
                children: [
                  _gradeRow(QualityGrade.excellent,
                      l10n.gpsQualityGradeExcellent, l10n.gpsQualityGradeExcellentDesc),
                  _gradeRow(QualityGrade.usable,
                      l10n.gpsQualityGradeUsable, l10n.gpsQualityGradeUsableDesc),
                  _gradeRow(QualityGrade.marginal,
                      l10n.gpsQualityGradeMarginal, l10n.gpsQualityGradeMarginalDesc),
                  _gradeRow(QualityGrade.unavailable, l10n.gpsQualityGradeUnavailable,
                      l10n.gpsQualityGradeUnavailableDesc),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _gradeRow(QualityGrade grade, String label, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QualityGradeBadge(grade: grade, compact: true),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(desc,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

// ── Scatter legend ─────────────────────────────────────────────────

class _ScatterLegend extends StatelessWidget {
  const _ScatterLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      children: [
        _legendDot(const Color(0xFF2563EB), l10n.gpsQualityDevice),
        _legendDot(const Color(0xFFF59E0B), l10n.gpsQualitySuspectPoints),
        _legendDot(const Color(0xFFDC2626), l10n.gpsQualitySelectRtkPoint),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600));
  }
}

// ── Helpers ────────────────────────────────────────────────────────

List<String> _distinctLocations(List<RtkPoint> points) {
  final seen = <String>[];
  for (final p in points) {
    if (!seen.contains(p.locationName)) seen.add(p.locationName);
  }
  return seen;
}
