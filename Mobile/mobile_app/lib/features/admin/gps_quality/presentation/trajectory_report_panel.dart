import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/widgets/trajectory_chart.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

/// TRAJECTORY quality report card (NIX-22): pairing overview, trajectory
/// chart, error distribution + static comparison, per-sample detail table.
class TrajectoryReportPanel extends ConsumerWidget {
  const TrajectoryReportPanel({super.key, required this.testId});

  final int testId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reportAsync = ref.watch(trajectoryReportProvider(testId));

    return reportAsync.when(
      loading: () => const Card(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text('$e', style: const TextStyle(color: AppColors.danger)),
        ),
      ),
      data: (report) => _buildReport(context, l10n, report),
    );
  }

  Widget _buildReport(
      BuildContext context, AppLocalizations l10n, TrajectoryQualityReport r) {
    final timeFmt = DateFormat('MM-dd HH:mm');
    final timeSecFmt = DateFormat('HH:mm:ss');

    return Card(
      key: const Key('trajectory-report-panel'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(children: [
            Text(l10n.gpsQualityTrajectoryReport,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(width: AppSpacing.sm),
            _GradeBadge(grade: r.grade),
            const Spacer(),
            Text(
              '${timeFmt.format(r.startedAt)} → ${r.endedAt != null ? timeFmt.format(r.endedAt!) : "..."} · ±${r.toleranceSec}s',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ]),
        ),

        // ── Pairing overview chips ────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            _chip('${r.totalPoints}', l10n.gpsQualityTrajectoryPoints),
            _chip('${r.filePaired}', l10n.gpsQualityFilePaired,
                color: const Color(0xFF7C3AED)),
            _chip('${r.logPaired}', l10n.gpsQualityLogPaired,
                color: const Color(0xFF4A7F9D)),
            _chip('${r.unpaired}', l10n.gpsQualityUnpaired,
                color: r.unpaired > 0 ? AppColors.warning : null),
            _chip('${r.pairRate.toStringAsFixed(1)}%', l10n.gpsQualityPairRate),
            _chip('${r.meanError.toStringAsFixed(1)}m', l10n.gpsQualityTrajectoryMeanError,
                color: AppColors.primary),
            _chip('${r.p50.toStringAsFixed(1)}m', 'P50'),
            _chip('${r.p95.toStringAsFixed(1)}m', 'P95'),
            _chip('${r.maxError.toStringAsFixed(1)}m', l10n.gpsQualityTrajectoryMaxError,
                color: AppColors.danger),
          ]),
        ),
        const Divider(height: 1),

        // ── Trajectory chart ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LayoutBuilder(builder: (context, constraints) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TrajectoryChart(
                  key: const Key('trajectory-chart'),
                  points: r.points,
                  width: constraints.maxWidth,
                  height: 280,
                ),
              );
            }),
            const SizedBox(height: AppSpacing.sm),
            Wrap(spacing: AppSpacing.lg, children: [
              _legend(const Color(0xFF2F6B3B), l10n.gpsQualityTrajectoryLegendRtk),
              _legend(const Color(0xFFC2564B), l10n.gpsQualityTrajectoryLegendDevice),
              _legend(const Color(0xFF8BA95A), l10n.gpsQualityTrajectoryLegendLink),
              _legend(const Color(0xFFD28A2D), l10n.gpsQualityTrajectoryLegendUnpaired),
            ]),
          ]),
        ),
        const Divider(height: 1),

        // ── Error distribution + static comparison ────────────────
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.gpsQualityTrajectoryErrorDist,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            _ErrorHistogram(points: r.points),
            const SizedBox(height: AppSpacing.md),
            _buildStaticComparison(l10n, r),
          ]),
        ),
        const Divider(height: 1),

        // ── Per-sample detail table ───────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            key: const Key('trajectory-detail-table'),
            headingRowHeight: 32,
            dataRowMinHeight: 30,
            dataRowMaxHeight: 36,
            columnSpacing: 14,
            columns: [
              DataColumn(label: Text('#', style: _th)),
              DataColumn(label: Text(l10n.gpsQualityTrajectoryColTime, style: _th)),
              DataColumn(label: Text(l10n.gpsQualityTrajectoryColRtkLat, style: _th)),
              DataColumn(label: Text(l10n.gpsQualityTrajectoryColRtkLng, style: _th)),
              DataColumn(label: Text(l10n.gpsQualityTrajectoryColDevLat, style: _th)),
              DataColumn(label: Text(l10n.gpsQualityTrajectoryColDevLng, style: _th)),
              DataColumn(label: Text(l10n.gpsQualityTrajectoryError, style: _th)),
              DataColumn(label: Text(l10n.gpsQualityTrajectorySource, style: _th)),
            ],
            rows: r.points.map((p) {
              const mono = TextStyle(fontSize: 11, fontFamily: 'monospace');
              final errColor = p.error == null
                  ? AppColors.textSecondary
                  : p.error! <= 10
                      ? AppColors.success
                      : p.error! <= 15
                          ? AppColors.warning
                          : AppColors.danger;
              return DataRow(cells: [
                DataCell(Text('${p.sequenceNo}', style: mono)),
                DataCell(Text(timeSecFmt.format(p.collectedAt), style: mono)),
                DataCell(Text(p.rtkLatitude.toStringAsFixed(5), style: mono)),
                DataCell(Text(p.rtkLongitude.toStringAsFixed(5), style: mono)),
                DataCell(Text(p.deviceLatitude?.toStringAsFixed(5) ?? '—', style: mono)),
                DataCell(Text(p.deviceLongitude?.toStringAsFixed(5) ?? '—', style: mono)),
                DataCell(Text(
                  p.error != null ? '${p.error!.toStringAsFixed(1)}m' : '—',
                  style: TextStyle(fontSize: 11, fontFamily: 'monospace',
                      fontWeight: FontWeight.w600, color: errColor),
                )),
                DataCell(_sourceTag(l10n, p)),
              ]);
            }).toList(),
          ),
        ),
        if (r.unpaired > 0)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF6EA),
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                    left: BorderSide(color: AppColors.warning, width: 3)),
              ),
              child: Text(
                l10n.gpsQualityTrajectoryUnpairedDetail(r.unpaired, r.toleranceSec),
                style: const TextStyle(fontSize: 12, color: Color(0xFF7A5416)),
              ),
            ),
          ),
      ]),
    );
  }

  static const _th = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

  Widget _chip(String value, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ]),
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

  Widget _sourceTag(AppLocalizations l10n, TrajectoryTrackPoint p) {
    final (label, color) = switch (p.matchSource) {
      'FILE' => (l10n.gpsQualityTrajectoryMatchFile, const Color(0xFF7C3AED)),
      'GPS_LOG' => (l10n.gpsQualityTrajectoryMatchLog, const Color(0xFF4A7F9D)),
      _ => (l10n.gpsQualityTrajectoryMatchUnpaired, AppColors.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildStaticComparison(AppLocalizations l10n, TrajectoryQualityReport r) {
    final cmp = r.staticComparison;
    if (cmp == null) {
      return Text(l10n.gpsQualityTrajectoryNoStatic,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary));
    }
    final better = cmp.deltaP95 < 0;
    final color = better ? AppColors.success : AppColors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: better ? const Color(0xFFEEF7EF) : const Color(0xFFFDF6EA),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Text(
        l10n.gpsQualityTrajectoryStaticDelta(
          cmp.staticP95.toStringAsFixed(1),
          r.p95.toStringAsFixed(1),
          cmp.deltaP95.abs().toStringAsFixed(1),
          better ? l10n.gpsQualityTrajectorySmaller : l10n.gpsQualityTrajectoryLarger,
        ),
        style: TextStyle(fontSize: 12, color: better ? const Color(0xFF2F5D3A) : const Color(0xFF7A5416)),
      ),
    );
  }
}

/// Error histogram: paired errors bucketed into 10 equal ranges up to max.
class _ErrorHistogram extends StatelessWidget {
  const _ErrorHistogram({required this.points});

  final List<TrajectoryTrackPoint> points;

  @override
  Widget build(BuildContext context) {
    final errors = points.where((p) => p.error != null).map((p) => p.error!).toList();
    if (errors.isEmpty) {
      return const SizedBox(height: 60,
          child: Center(child: Text('—', style: TextStyle(color: AppColors.textSecondary))));
    }
    final maxErr = errors.reduce((a, b) => a > b ? a : b);
    const bucketCount = 10;
    final bucketWidth = maxErr / bucketCount;
    final buckets = List<int>.filled(bucketCount, 0);
    for (final e in errors) {
      int idx = bucketWidth == 0 ? 0 : (e / bucketWidth).floor();
      if (idx >= bucketCount) idx = bucketCount - 1;
      buckets[idx]++;
    }
    final maxCount = buckets.reduce((a, b) => a > b ? a : b);

    return Column(children: [
      SizedBox(
        height: 80,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: buckets.map((count) {
            final frac = maxCount == 0 ? 0.0 : count / maxCount;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: FractionallySizedBox(
                  heightFactor: frac == 0 ? 0.03 : frac,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF8BA95A),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 2),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('0m', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        Text('${(maxErr / 2).toStringAsFixed(1)}m',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        Text('${maxErr.toStringAsFixed(1)}m',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ]),
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
      QualityGrade.marginal => ('MARGINAL', const Color(0xFFB45309)),
      QualityGrade.unavailable => ('UNAVAILABLE', AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
