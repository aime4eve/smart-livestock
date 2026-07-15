import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/utils/geo_utils.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';

/// Static GPS scatter chart centred on the RTK truth point.
///
/// Plots every GPS sample as an offset (meters) from the RTK truth. The dashed
/// blue circle marks the P95 jitter radius; the red cross marks RTK truth.
/// Normal points are blue, suspected-motion points are amber.
class GpsScatterChart extends StatelessWidget {
  const GpsScatterChart({
    super.key,
    required this.points,
    required this.p95,
    required this.rtkLatitude,
    required this.rtkLongitude,
    this.size = 300,
  });

  final List<ScatterPoint> points;
  final double p95;
  final double rtkLatitude;
  final double rtkLongitude;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ScatterPainter(
          points: points,
          p95: p95,
          rtkLat: rtkLatitude,
          rtkLng: rtkLongitude,
        ),
      ),
    );
  }
}

class _OffsetPoint {
  const _OffsetPoint(this.dx, this.dy, this.suspect);
  final double dx; // meters east (+) / west (-)
  final double dy; // meters north (+) / south (-)
  final bool suspect;
}

class _ScatterPainter extends CustomPainter {
  _ScatterPainter({
    required this.points,
    required this.p95,
    required this.rtkLat,
    required this.rtkLng,
  });

  final List<ScatterPoint> points;
  final double p95;
  final double rtkLat;
  final double rtkLng;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Compute meter-offsets for every sample.
    final offsets = <_OffsetPoint>[];
    for (final p in points) {
      final d = haversineDistance(rtkLat, rtkLng, p.latitude, p.longitude);
      if (d <= 0) continue;
      // bearing from RTK to sample
      final y = math.sin(_toRad(p.longitude - rtkLng)) *
          math.cos(_toRad(p.latitude));
      final x = math.cos(_toRad(rtkLat)) * math.sin(_toRad(p.latitude)) -
          math.sin(_toRad(rtkLat)) *
              math.cos(_toRad(p.latitude)) *
              math.cos(_toRad(p.longitude - rtkLng));
      final bearing = math.atan2(y, x);
      offsets.add(_OffsetPoint(
        d * math.sin(bearing),
        d * math.cos(bearing),
        p.suspect,
      ));
    }

    // Determine scale: fit max(p95*2, maxAbsOffset) into half the canvas.
    final maxAbsOffset = offsets.fold<double>(
      p95 * 2.2,
      (prev, e) => math.max(prev, e.dx.abs()),
    );
    final maxAbsOffsetY = offsets.fold<double>(
      p95 * 2.2,
      (prev, e) => math.max(prev, e.dy.abs()),
    );
    final dataRadius = math.max(maxAbsOffset, maxAbsOffsetY);
    final usableHalf = math.min(cx, cy) - 8;
    final scale = dataRadius > 0 ? usableHalf / dataRadius : 1.0;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Grid circles at p95 and p95*2
    for (final r in [p95, p95 * 2]) {
      final px = r * scale;
      if (px <= 0 || px > usableHalf) continue;
      canvas.drawCircle(
        Offset(cx, cy),
        px,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = const Color(0xFFCBD5E1),
      );
    }

    // P95 ring (dashed blue)
    _drawDashedCircle(canvas, Offset(cx, cy), p95 * scale, const Color(0xFF2563EB));

    // Scatter points
    final normalPaint = Paint()..color = const Color(0x992563EB);
    final suspectPaint = Paint()..color = const Color(0x99F59E0B);
    for (final o in offsets) {
      final px = (cx + o.dx * scale).clamp(2.0, size.width - 2);
      final py = (cy - o.dy * scale).clamp(2.0, size.height - 2);
      canvas.drawCircle(Offset(px, py), 3, o.suspect ? suspectPaint : normalPaint);
    }

    // RTK truth crosshair (center)
    final centerPaint = Paint()
      ..color = const Color(0xFFDC2626)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 6, cy), Offset(cx + 6, cy), centerPaint);
    canvas.drawLine(Offset(cx, cy - 6), Offset(cx, cy + 6), centerPaint);
    canvas.drawCircle(
      Offset(cx, cy),
      3,
      Paint()..color = const Color(0xFFDC2626),
    );
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Color color) {
    if (radius <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: 0.5);
    const dashCount = 48;
    final circumference = 2 * math.pi * radius;
    final dashLen = circumference / dashCount / 2;
    for (int i = 0; i < dashCount; i++) {
      final start = (i / dashCount) * 2 * math.pi;
      final end = start + dashLen / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        end - start,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScatterPainter oldDelegate) =>
      oldDelegate.p95 != p95 ||
      oldDelegate.rtkLat != rtkLat ||
      oldDelegate.rtkLng != rtkLng ||
      oldDelegate.points.length != points.length;

  double _toRad(double deg) => deg * math.pi / 180;
}
