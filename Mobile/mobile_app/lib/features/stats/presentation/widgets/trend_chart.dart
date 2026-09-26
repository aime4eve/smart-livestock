import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hkt_livestock_agentic/core/charts/chart_readout_layer.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/stats/domain/stats_repository.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.title,
    required this.trend,
    required this.color,
    this.suffix = '',
    this.minY,
    this.maxY,
  });

  final String title;
  final List<StatsTrendPoint> trend;
  final Color color;
  final String suffix;
  final double? minY;
  final double? maxY;

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (int i = 0; i < trend.length; i++) {
      spots.add(FlSpot(i.toDouble(), trend[i].value));
    }

    final values = trend.map((e) => e.value).toList();
    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final dataMax = values.reduce((a, b) => a > b ? a : b);
    final range = dataMax - dataMin;
    final yMin = minY ?? (dataMin - range * 0.2);
    final yMax = maxY ?? (dataMax + range * 0.2);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 160,
              child: LineChartReadout(
                timestamps: const [],
                readoutTitle: (index) => trend[index].date,
                formatValue: (value) => '${value.toStringAsFixed(2)}$suffix',
                chartDataBuilder: (touchData) => LineChartData(
                  minY: yMin,
                  maxY: yMax,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: range > 0 ? range / 4 : 1,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= trend.length) {
                            return const SizedBox.shrink();
                          }
                          final date = trend[idx].date;
                          final label = date.length >= 5
                              ? date.substring(5)
                              : date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toStringAsFixed(1)}$suffix',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: color,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: color,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  lineTouchData: touchData,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
