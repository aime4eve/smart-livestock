import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/widgets/grade_badge.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/widgets/track_line_map.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

/// LINE quality report panel (NIX-68, spec §8.5), shown inline in the right
/// column of the check list: metric chips + map comparison (green standard
/// track vs red device track) + per-point deviation table. Reads the
/// snapshot via /tests/{id}/line-report (+ /track and /deviations).
class LineReportPanel extends ConsumerWidget {
  const LineReportPanel({super.key, required this.testId});

  final int testId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reportAsync = ref.watch(lineReportProvider(testId));

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
      data: (report) => _buildReport(context, l10n, ref, report),
    );
  }

  Widget _buildReport(BuildContext context, AppLocalizations l10n,
      WidgetRef ref, LineQualityReport r) {
    final timeFmt = DateFormat('MM-dd HH:mm');

    return Card(
      key: const Key('line-report-panel'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(l10n.gpsQualityLineReport,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: AppSpacing.sm),
              _lineTypeTag(l10n),
              const SizedBox(width: AppSpacing.sm),
              GradeBadge(grade: r.grade),
              const Spacer(),
              Text(
                '${timeFmt.format(r.startedAt)} → ${r.endedAt != null ? timeFmt.format(r.endedAt!) : "..."}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              '${l10n.gpsQualityLineMapStandard}: ${r.trackLineName}'
              ' · ${r.deviceCode}'
              ' · ${l10n.gpsQualityLineCalcNoteShort}',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ]),
        ),

        // ── Metric chips ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            _chip('${r.sampleCount}', l10n.gpsQualityLineSamples),
            _chip('${r.tripCount}', l10n.gpsQualityLineTripCount),
            _chip('${r.meanDeviation.toStringAsFixed(1)}m',
                l10n.gpsQualityLineMeanDeviation,
                color: AppColors.primary),
            _chip('${r.p50.toStringAsFixed(1)}m', 'P50'),
            _chip('${r.p95.toStringAsFixed(1)}m', 'P95'),
            _chip('${r.maxDeviation.toStringAsFixed(1)}m',
                l10n.gpsQualityLineMaxDeviation,
                color: AppColors.warning),
            _chip('${r.within15mPct.toStringAsFixed(1)}%',
                l10n.gpsQualityLineWithin15m,
                color: AppColors.success),
            _chip('${r.within25mPct.toStringAsFixed(1)}%',
                l10n.gpsQualityLineWithin25m),
            _chip('${r.within40mPct.toStringAsFixed(1)}%',
                l10n.gpsQualityLineWithin40m),
          ]),
        ),
        const Divider(height: 1),

        // ── Map comparison + deviation table ──────────────────────
        _buildMapAndTable(l10n, ref, r),

        // ── Footer callout ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.lineTeal.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: const Border(
                  left: BorderSide(color: AppColors.lineTeal, width: 3)),
            ),
            child: Text(l10n.gpsQualityLineGotoComparison,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
        ),
      ]),
    );
  }

  Widget _buildMapAndTable(
      AppLocalizations l10n, WidgetRef ref, LineQualityReport r) {
    final trackAsync = ref.watch(lineReportTrackProvider(testId));
    final deviationsAsync = ref.watch(lineReportDeviationsProvider(testId));

    final trackPts = trackAsync.value ?? [];
    final deviations = deviationsAsync.value ?? [];

    final trackLatLngs = trackPts.map((p) => LatLng(p.lat, p.lng)).toList();
    final deviceLatLngs =
        deviations.map((d) => LatLng(d.lat, d.lng)).toList();

    LineDeviation? maxDev;
    for (final d in deviations) {
      if (maxDev == null || d.deviationM > maxDev.deviationM) maxDev = d;
    }

    final polylines = <Polyline>[
      if (deviceLatLngs.length >= 2)
        Polyline(
          points: deviceLatLngs,
          color: AppColors.danger,
          strokeWidth: 2,
          pattern: StrokePattern.dashed(segments: const [5, 4]),
        ),
      if (trackLatLngs.length >= 2)
        Polyline(
          points: trackLatLngs,
          color: AppColors.primary,
          strokeWidth: 3.5,
        ),
    ];
    final markers = <Marker>[
      if (trackLatLngs.isNotEmpty) ...[
        Marker(
            point: trackLatLngs.first,
            width: 14,
            height: 14,
            child: const TrackDotMarker(color: AppColors.primary)),
        Marker(
            point: trackLatLngs.last,
            width: 14,
            height: 14,
            child: const TrackDotMarker(color: AppColors.primary)),
      ],
      if (maxDev != null)
        Marker(
          point: LatLng(maxDev.lat, maxDev.lng),
          width: 18,
          height: 18,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.warning, width: 2),
            ),
          ),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (trackAsync.isLoading || deviationsAsync.isLoading)
          const SizedBox(
              height: 120, child: Center(child: CircularProgressIndicator()))
        else ...[
          TrackLineMap(
            key: const Key('line-report-map'),
            polylines: polylines,
            markers: markers,
            height: 280,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(spacing: AppSpacing.lg, children: [
            _legend(AppColors.primary, l10n.gpsQualityLineMapStandard),
            _legend(AppColors.danger,
                '${l10n.gpsQualityLineMapDevice} (${deviations.length})'),
            if (maxDev != null)
              _legend(AppColors.warning,
                  '${l10n.gpsQualityLineMapMax} ${maxDev.deviationM.toStringAsFixed(1)}m'),
          ]),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.gpsQualityLineDeviationTable,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              key: const Key('line-deviation-table'),
              headingRowHeight: 32,
              dataRowMinHeight: 30,
              dataRowMaxHeight: 36,
              columnSpacing: 16,
              columns: [
                const DataColumn(label: Text('#', style: _th)),
                DataColumn(
                    label: Text(l10n.gpsQualityLineColTime, style: _th)),
                DataColumn(
                    label: Text(l10n.gpsQualityLatitude, style: _th)),
                DataColumn(
                    label: Text(l10n.gpsQualityLongitude, style: _th)),
                DataColumn(
                    label: Text(l10n.gpsQualityLineColSegment, style: _th)),
                DataColumn(
                    label:
                        Text(l10n.gpsQualityLineColDeviation, style: _th)),
              ],
              rows: deviations.map((d) {
                const mono = TextStyle(fontSize: 11, fontFamily: 'monospace');
                final isMax = identical(d, maxDev);
                final errColor = d.deviationM <= 15
                    ? AppColors.success
                    : d.deviationM <= 25
                        ? AppColors.warning
                        : AppColors.danger;
                return DataRow(
                    key: ValueKey('line-dev-${d.sequenceNo}'),
                    cells: [
                      DataCell(Text('${d.sequenceNo}', style: mono)),
                      DataCell(Text(
                          DateFormat('HH:mm:ss').format(d.recordedAt),
                          style: mono)),
                      DataCell(Text(d.lat.toStringAsFixed(5), style: mono)),
                      DataCell(Text(d.lng.toStringAsFixed(5), style: mono)),
                      DataCell(Text('#${d.segmentNo}–#${d.segmentNo + 1}',
                          style: mono)),
                      DataCell(Text(
                        '${d.deviationM.toStringAsFixed(1)}m${isMax ? ' ⚠ max' : ''}',
                        style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            color: errColor),
                      )),
                    ]);
              }).toList(),
            ),
          ),
        ],
      ]),
    );
  }

  static const _th = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

  Widget _lineTypeTag(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.lineTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: AppColors.lineTeal, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(l10n.gpsQualityLineCheck,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.lineTeal)),
      ]),
    );
  }

  Widget _chip(String value, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style:
              const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }
}
