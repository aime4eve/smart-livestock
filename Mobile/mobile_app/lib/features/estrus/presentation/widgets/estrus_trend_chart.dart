import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';

class EstrusTrendChart extends StatelessWidget {
  const EstrusTrendChart({super.key, required this.trend7d});

  final List<EstrusTrendPoint> trend7d;

  @override
  Widget build(BuildContext context) {
    if (trend7d.isEmpty) {
      return const SizedBox(height: 180);
    }
    final spots = trend7d
        .map(
          (p) => FlSpot(
            p.timestamp.millisecondsSinceEpoch.toDouble(),
            p.score,
          ),
        )
        .toList();
    final minX = spots.first.x;
    final maxX = spots.last.x;
    final high = spots.any((s) => s.y >= 70);
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (v) => const FlLine(
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
                  '${DateTime.fromMillisecondsSinceEpoch(v.toInt()).month}/${DateTime.fromMillisecondsSinceEpoch(v.toInt()).day}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 25,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
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
              color: high ? AppColors.danger : AppColors.info,
              barWidth: 2,
              belowBarData: BarAreaData(
                show: high,
                color: AppColors.danger.withValues(alpha: 0.12),
              ),
              dotData: const FlDotData(show: true),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 70,
                color: AppColors.warning,
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
