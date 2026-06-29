import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/ai_anomaly/domain/anomaly_models.dart';
import 'package:hkt_livestock_agentic/features/ai_anomaly/presentation/anomaly_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Anomaly score trend chart (fl_chart), y-axis 0..1 with a 0.7 alert threshold.
class AnomalyHistoryChart extends ConsumerWidget {
  const AnomalyHistoryChart({super.key, required this.livestockId});
  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncHistory = ref.watch(anomalyHistoryProvider(livestockId));

    return asyncHistory.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return _buildChart(context, l10n, items);
      },
    );
  }

  Widget _buildChart(
    BuildContext context,
    AppLocalizations l10n,
    List<AnomalyScoreHistoryItem> items,
  ) {
    final spots = items
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.anomalyScore))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.aiAnomalyViewHistory,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: LineChart(LineChartData(
                minY: 0,
                maxY: 1,
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text('${(v * 100).toInt()}%',
                          style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 0.7,
                      color: AppColors.danger.withValues(alpha: 0.4),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                       style:
                           const TextStyle(fontSize: 9, color: AppColors.danger),
                        labelResolver: (_) => l10n.aiAnomalyAlertThreshold,
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.info,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }
}
