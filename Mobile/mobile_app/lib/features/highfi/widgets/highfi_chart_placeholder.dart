import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';

class HighfiChartPlaceholder extends StatelessWidget {
  const HighfiChartPlaceholder({
    super.key,
    required this.title,
    required this.data,
    this.height = 160,
  });

  final String title;
  final List<StatsChartData> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: height,
          child: CustomPaint(
            size: Size(double.infinity, height),
            painter: _BarChartPainter(data: data, maxValue: maxValue),
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({
    required this.data,
    required this.maxValue,
  });

  final List<StatsChartData> data;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final barWidth = (size.width - (data.length + 1) * 8) / data.length;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      final barHeight = (item.value / maxValue) * (size.height - 24);
      final x = 8.0 + i * (barWidth + 8);
      final y = size.height - 20 - barHeight;

      paint.color = const Color(0xFF2F6B3B).withValues(alpha: 0.2);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rrect, paint..color = Color(item.color));
    }

    const tp = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 10,
    );
    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      final x = 8.0 + i * (barWidth + 8) + barWidth / 2;
      final tpainter = TextPainter(
        text: TextSpan(text: item.label, style: tp),
        textDirection: TextDirection.ltr,
      )..layout();
      tpainter.paint(
        canvas,
        Offset(x - tpainter.width / 2, size.height - 16),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      data != oldDelegate.data;
}
