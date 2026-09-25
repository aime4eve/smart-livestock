import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';

LineTouchData healthLineTouchData({
  required List<DateTime?> timestamps,
  required String Function(double value) formatValue,
}) {
  return LineTouchData(
    touchTooltipData: LineTouchTooltipData(
      getTooltipColor: (_) => Colors.transparent,
      tooltipRoundedRadius: 0,
      tooltipPadding: EdgeInsets.zero,
      tooltipMargin: 0,
      maxContentWidth: 120,
      tooltipBorder: BorderSide.none,
      fitInsideHorizontally: true,
      fitInsideVertically: true,
      getTooltipItems: (spots) =>
          spots.where((spot) => spot.barIndex == 0).map((spot) {
            return LineTooltipItem(
              formatValue(spot.y),
              const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            );
          }).toList(),
    ),
  );
}
