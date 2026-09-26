import 'package:fl_chart/fl_chart.dart';
LineTouchData healthLineTouchData({
  required List<DateTime?> timestamps,
  required String Function(double value) formatValue,
}) {
  return const LineTouchData(
    enabled: false,
  );
}
