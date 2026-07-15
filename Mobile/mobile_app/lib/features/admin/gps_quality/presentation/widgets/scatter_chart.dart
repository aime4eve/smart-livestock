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
    required this.p50,
    required this.p95,
    required this.rtkLatitude,
    required this.rtkLongitude,
    this.size = 300,
  });

  final List<ScatterPoint> points;
  final double p50;
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
          p50: p50,
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
    required this.p50,
    required this.p95,
    required this.rtkLat,
    required this.rtkLng,
  });

  final List<ScatterPoint> points;
  final double p50;
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

    // Determine view radius: show core distribution clearly.
    // Use max(p50*3, 40m) as the view radius — this focuses on the bulk of
    // points rather than zooming out to fit extreme outliers.
    // Cap at 80m so very bad devices still show a meaningful view.
    final viewRadius = math.min(math.max(p50 * 3, 40.0), 80.0);
    final usableHalf = math.min(cx, cy) - 12;
    final scale = usableHalf / viewRadius;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Grade threshold reference circles (15m/25m/40m)
    // These give visual context: points inside 15m are "excellent" quality.
    const thresholds = [15.0, 25.0, 40.0];
    const thresholdColors = [
      Color(0x3066BB6A), // green-ish for 15m
      Color(0x302563EB), // blue-ish for 25m
      Color(0x30F59E0B), // amber for 40m
    ];
    for (int i = 0; i < thresholds.length; i++) {
      final r = thresholds[i] * scale;
      if (r <= 0 || r > usableHalf) continue;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = thresholdColors[i],
      );
    }

    // P95 ring (dashed blue) — only if it fits within the view
    if (p95 * scale <= usableHalf) {
      _drawDashedCircle(canvas, Offset(cx, cy), p95 * scale,
          const Color(0xFF2563EB));
    }

    // Scatter points — normal (blue), suspect (amber), off-screen (gray edge)
    final normalPaint = Paint()..color = const Color(0x992563EB);
    final suspectPaint = Paint()..color = const Color(0x99F59E0B);
    final offscreenPaint = Paint()..color = const Color(0x3394A3B8);
    final viewRadiusSq = viewRadius * viewRadius;

    for (final o in offsets) {
      final distSq = o.dx * o.dx + o.dy * o.dy;
      final isOffscreen = distSq > viewRadiusSq;

      double px, py;
      if (isOffscreen) {
        // Project to edge of circle
        final dist = math.sqrt(distSq);
        final ratio = (usableHalf - 4) / (dist * scale);
        px = cx + o.dx * scale * ratio;
        py = cy - o.dy * scale * ratio;
        canvas.drawCircle(Offset(px, py), 2, offscreenPaint);
      } else {
        px = cx + o.dx * scale;
        py = cy - o.dy * scale;
        canvas.drawCircle(Offset(px, py), 3,
            o.suspect ? suspectPaint : normalPaint);
      }
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
      oldDelegate.p50 != p50 ||
      oldDelegate.p95 != p95 ||
      oldDelegate.rtkLat != rtkLat ||
      oldDelegate.rtkLng != rtkLng ||
      oldDelegate.points.length != points.length;

  double _toRad(double deg) => deg * math.pi / 180;
}
