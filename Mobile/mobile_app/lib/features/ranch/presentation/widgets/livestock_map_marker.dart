import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';

/// Maps health status + primary alert type to fill color.
Color livestockHealthColor(String healthStatus, String primaryAlert) {
  if (healthStatus == 'NORMAL') return AppColors.success;
  return switch (primaryAlert) {
    'FEVER' => AppColors.danger,
    'DIGESTIVE' => AppColors.warning,
    'ESTRUS' => AppColors.estrus,
    'EPIDEMIC' => AppColors.info,
    _ => AppColors.danger,
  };
}

/// Unified map marker for livestock showing health status (fill color)
/// and fence status (border style) as two independent visual channels.
///
/// Fill color encodes health type:
///   NORMAL=green, FEVER=red, DIGESTIVE=orange, ESTRUS=pink, EPIDEMIC=blue
///
/// Border style encodes fence status:
///   SAFE=none, APPROACH=dashed dark gray, BREACH=solid black + pulse glow
class LivestockMapMarker extends StatefulWidget {
  const LivestockMapMarker({
    super.key,
    required this.livestockCode,
    required this.healthStatus,
    required this.primaryAlert,
    required this.fenceStatus,
    this.onTap,
  });

  final String livestockCode;
  final String healthStatus; // NORMAL / WARNING / CRITICAL
  final String primaryAlert; // FEVER / DIGESTIVE / ESTRUS / EPIDEMIC / '' / ...
  final String fenceStatus; // SAFE / APPROACH / BREACH
  final VoidCallback? onTap;

  @override
  State<LivestockMapMarker> createState() => _LivestockMapMarkerState();
}

class _LivestockMapMarkerState extends State<LivestockMapMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breachController;

  @override
  void initState() {
    super.initState();
    _breachController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant LivestockMapMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fenceStatus != oldWidget.fenceStatus) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.fenceStatus == 'BREACH') {
      _breachController.repeat(reverse: true);
    } else {
      _breachController.stop();
      _breachController.value = 0;
    }
  }

  @override
  void dispose() {
    _breachController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortLabel = widget.livestockCode.replaceAll('SL-2024-', '');
    final fillColor =
        livestockHealthColor(widget.healthStatus, widget.primaryAlert);

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: AnimatedBuilder(
          animation: _breachController,
          builder: (context, child) {
            return CustomPaint(
              painter: _LivestockMarkerPainter(
                fillColor: fillColor,
                fenceStatus: widget.fenceStatus,
                breachProgress:
                    widget.fenceStatus == 'BREACH'
                        ? _breachController.value
                        : 0.0,
              ),
              child: child,
            );
          },
          child: Center(
            child: Text(
              shortLabel.isNotEmpty ? shortLabel : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter for the livestock marker.
///
/// Draws a filled circle (health color) and an optional fence border:
/// - APPROACH: dashed dark gray circle
/// - BREACH: solid thick black circle with pulsing glow
class _LivestockMarkerPainter extends CustomPainter {
  const _LivestockMarkerPainter({
    required this.fillColor,
    required this.fenceStatus,
    required this.breachProgress,
  });

  final Color fillColor;
  final String fenceStatus;
  final double breachProgress;

  static const double _baseRadius = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // BREACH: outer glow that pulses
    if (fenceStatus == 'BREACH') {
      final glowAlpha = 0.15 + 0.2 * breachProgress;
      final glowPaint = Paint()
        ..color = AppColors.fenceBreach.withValues(alpha: glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center, _baseRadius + 3, glowPaint);
    }

    // Filled circle (health color)
    canvas.drawCircle(center, _baseRadius, Paint()..color = fillColor);

    // Shadow for depth
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center, _baseRadius + 1, shadowPaint);

    // Fence border
    if (fenceStatus == 'APPROACH') {
      _drawDashedCircle(canvas, center, _baseRadius + 2);
    } else if (fenceStatus == 'BREACH') {
      final borderAlpha = 0.6 + 0.4 * breachProgress;
      final borderPaint = Paint()
        ..color = AppColors.fenceBreach.withValues(alpha: borderAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(center, _baseRadius + 1.5, borderPaint);
    }
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius) {
    const dashCount = 16;
    const sweepAngle = 2 * pi / 16;
    const halfDash = sweepAngle * 0.4;

    final paint = Paint()
      ..color = AppColors.fenceApproach
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromCircle(center: center, radius: radius);
    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * sweepAngle;
      canvas.drawArc(rect, startAngle, halfDash, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LivestockMarkerPainter old) {
    return fillColor != old.fillColor ||
        fenceStatus != old.fenceStatus ||
        breachProgress != old.breachProgress;
  }
}
