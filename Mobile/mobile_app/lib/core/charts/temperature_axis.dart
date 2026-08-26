import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

AxisTitles temperatureAxisTitles({
  required double minY,
  required double maxY,
}) {
  return AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 40,
      interval: temperatureAxisInterval(minY: minY, maxY: maxY),
      minIncluded: false,
      maxIncluded: false,
      getTitlesWidget: (value, _) => Text(
        '${value.toStringAsFixed(1)}°',
        style: const TextStyle(fontSize: 10),
      ),
    ),
  );
}

double temperatureAxisInterval({
  required double minY,
  required double maxY,
}) {
  final range = (maxY - minY).abs();
  const candidates = [0.1, 0.2, 0.5, 1.0, 2.0, 5.0];
  for (final candidate in candidates) {
    if (range / candidate <= 5) return candidate;
  }
  return (range / 5).ceilToDouble();
}
