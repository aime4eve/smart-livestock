import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';

LineTouchData healthLineTouchData({
  required List<DateTime?> timestamps,
  required String Function(double value) formatValue,
}) {
  return LineTouchData(
    touchTooltipData: LineTouchTooltipData(
      getTooltipColor: (_) => AppColors.surfaceAlt,
      tooltipRoundedRadius: 8,
      tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      tooltipMargin: 10,
      maxContentWidth: 140,
      tooltipBorder: const BorderSide(color: AppColors.border),
      fitInsideHorizontally: true,
      fitInsideVertically: true,
      getTooltipItems: (spots) =>
          spots.where((spot) => spot.barIndex == 0).map((spot) {
            final index = spot.x.toInt();
            final timestamp = index >= 0 && index < timestamps.length
                ? timestamps[index]
                : null;
            final timeLabel = timestamp == null
                ? ''
                : '${timestamp.month}/${timestamp.day} '
                      '${timestamp.hour.toString().padLeft(2, '0')}:'
                      '${timestamp.minute.toString().padLeft(2, '0')}';
            return LineTooltipItem(
              '${formatValue(spot.y)}\n$timeLabel',
              const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
    ),
  );
}
