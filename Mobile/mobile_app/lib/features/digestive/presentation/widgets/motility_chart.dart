import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';

class MotilityChart extends StatelessWidget {
  const MotilityChart({
    super.key,
    required this.records,
    required this.baseline,
  });

  final List<MotilityRecord> records;
  final double baseline;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const SizedBox(height: 200);
    }
    final spots = records
        .map(
          (r) => FlSpot(
            r.timestamp.millisecondsSinceEpoch.toDouble(),
            r.frequency,
          ),
        )
        .toList();
    final minX = spots.first.x;
    final maxX = spots.last.x;
    final maxY = baseline * 1.5;
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (v) => FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: (maxX - minX) / 4,
                getTitlesWidget: (v, _) => Text(
                  '${(v / 3600000).round()}h',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: maxY / 4,
                getTitlesWidget: (v, _) => Text(
                  v.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.accent,
              barWidth: 2,
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.accent.withValues(alpha: 0.18),
              ),
              dotData: const FlDotData(show: false),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: baseline,
                color: AppColors.success,
                strokeWidth: 1,
                dashArray: [6, 4],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
