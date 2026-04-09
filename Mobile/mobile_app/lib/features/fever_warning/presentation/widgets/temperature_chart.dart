import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';

class TemperatureChart extends StatelessWidget {
  const TemperatureChart({
    super.key,
    required this.records,
    required this.baselineTemp,
    required this.threshold,
  });

  final List<TemperatureRecord> records;
  final double baselineTemp;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const SizedBox(height: 200);
    }
    final sorted = List<TemperatureRecord>.from(records)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final ms0 = sorted.first.timestamp.millisecondsSinceEpoch;
    final spots = sorted
        .map(
          (r) => FlSpot(
            (r.timestamp.millisecondsSinceEpoch - ms0) / 3600000.0,
            r.temperature,
          ),
        )
        .toList();
    const minX = 0.0;
    final maxX = spots.last.x;
    final minY = baselineTemp - 1.0;
    final maxY = baselineTemp + 2.0;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.5,
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
                  '${v.round()}h',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 0.5,
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
              isCurved: false,
              color: AppColors.info,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  final t = spot.y;
                  final over = t >= threshold;
                  return FlDotCirclePainter(
                    radius: 3,
                    color: over ? AppColors.danger : AppColors.info,
                    strokeWidth: 0,
                  );
                },
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: baselineTemp,
                color: AppColors.success,
                strokeWidth: 1,
                dashArray: [6, 4],
              ),
              HorizontalLine(
                y: threshold,
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
