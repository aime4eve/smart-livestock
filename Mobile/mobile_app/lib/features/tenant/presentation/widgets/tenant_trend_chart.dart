import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';

import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';

class TenantTrendChart extends StatelessWidget {
  const TenantTrendChart({
    super.key,
    required this.dailyStats,
    this.maxDisplayPoints = 10,
    this.height = 150,
  });

  final List<DailyStatPoint> dailyStats;
  final int maxDisplayPoints;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (dailyStats.isEmpty) {
      return SizedBox(height: height);
    }

    final sorted = List<DailyStatPoint>.from(dailyStats)
      ..sort((a, b) => a.date.compareTo(b.date));

    final sampled = _uniformSample(sorted, maxDisplayPoints);

    final spots = <FlSpot>[];
    for (var i = 0; i < sampled.length; i++) {
      spots.add(FlSpot(i.toDouble(), sampled[i].alerts.toDouble()));
    }

    final maxY = spots.isEmpty
        ? 10.0
        : spots.map((s) => s.y).reduce(max).clamp(5.0, 50.0) * 1.2;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 20 ? 5 : 2,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.textSecondary.withAlpha(30),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: sampled.length > 5
                    ? (sampled.length / 4).ceilToDouble()
                    : 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sampled.length) {
                    return const SizedBox.shrink();
                  }
                  final d = sampled[idx].date;
                  return Text(
                    d.substring(5), // MM-DD
                    style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: AppColors.warning,
              barWidth: 2,
              dotData: FlDotData(
                show: sampled.length <= 10,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 2.5,
                  color: AppColors.warning,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.warning.withAlpha(25),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  List<DailyStatPoint> _uniformSample(List<DailyStatPoint> source, int maxPoints) {
    if (source.length <= maxPoints) return source;
    final result = <DailyStatPoint>[];
    final step = (source.length - 1) / (maxPoints - 1);
    for (var i = 0; i < maxPoints; i++) {
      final idx = (i * step).floor().clamp(0, source.length - 1);
      result.add(source[idx]);
    }
    return result;
  }
}
