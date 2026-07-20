import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';

/// Match outcome of a single route RTK point.
enum RouteMatchStatus { matched, missed, ambiguous }

/// A route RTK point positioned by lat/lng for the route match chart.
class RouteMatchPoint {
  const RouteMatchPoint({
    required this.sequenceNo,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  final int sequenceNo;
  final double latitude;
  final double longitude;
  final RouteMatchStatus status;
}

/// Dynamic route match chart (no map tiles).
///
/// Draws the RTK route point sequence (connected in sequenceNo order with
/// numbered labels, colored by match outcome) plus the matched GPS pass
/// trajectory (blue polyline). Lat/lng bounds are auto-scaled to fit.
class RouteMatchChart extends StatelessWidget {
  const RouteMatchChart({
    super.key,
    required this.points,
    this.passes = const [],
    this.width = 560,
    this.height = 320,
  });

  final List<RouteMatchPoint> points;
  final List<DynamicMatchedPass> passes;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _RouteMatchPainter(points: points, passes: passes),
      ),
    );
  }
}

class _RouteMatchPainter extends CustomPainter {
  _RouteMatchPainter({required this.points, required this.passes});

  final List<RouteMatchPoint> points;
  final List<DynamicMatchedPass> passes;

  static const _padding = 28.0;
  static const _routeLineColor = Color(0xFFCBD5E1);
  static const _passColor = Color(0xFF2563EB);
  static const _matchedColor = Color(0xFF16A34A);
  static const _missedColor = Color(0xFFDC2626);
  static const _ambiguousColor = Color(0xFFF59E0B);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    final sortedPoints = List<RouteMatchPoint>.from(points)
      ..sort((a, b) => a.sequenceNo.compareTo(b.sequenceNo));
    final sortedPasses = List<DynamicMatchedPass>.from(passes)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    if (sortedPoints.isEmpty && sortedPasses.isEmpty) return;

    // Lat/lng bounds over route points and passes
    var minLat = double.infinity, maxLat = -double.infinity;
    var minLng = double.infinity, maxLng = -double.infinity;
    void absorb(double lat, double lng) {
      minLat = math.min(minLat, lat);
      maxLat = math.max(maxLat, lat);
      minLng = math.min(minLng, lng);
      maxLng = math.max(maxLng, lng);
    }

    for (final p in sortedPoints) {
      absorb(p.latitude, p.longitude);
    }
    for (final p in sortedPasses) {
      absorb(p.latitude, p.longitude);
    }

    // Uniform scale (fit inside padding), centered
    final dLat = math.max(maxLat - minLat, 1e-9);
    final dLng = math.max(maxLng - minLng, 1e-9);
    final scale = math.min(
      (size.width - _padding * 2) / dLng,
      (size.height - _padding * 2) / dLat,
    );
    final drawnW = dLng * scale;
    final drawnH = dLat * scale;
    final originX = (size.width - drawnW) / 2;
    final originY = (size.height - drawnH) / 2;

    Offset toOffset(double lat, double lng) => Offset(
          originX + (lng - minLng) * scale,
          originY + (maxLat - lat) * scale,
        );

    // Route sequence polyline
    if (sortedPoints.length > 1) {
      final routePaint = Paint()
        ..color = _routeLineColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      final first = toOffset(
          sortedPoints.first.latitude, sortedPoints.first.longitude);
      final path = Path()..moveTo(first.dx, first.dy);
      for (final p in sortedPoints.skip(1)) {
        final o = toOffset(p.latitude, p.longitude);
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, routePaint);
    }

    // Matched pass trajectory
    if (sortedPasses.length > 1) {
      final passPaint = Paint()
        ..color = _passColor.withValues(alpha: 0.8)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path();
      final first = toOffset(sortedPasses.first.latitude,
          sortedPasses.first.longitude);
      path.moveTo(first.dx, first.dy);
      for (final p in sortedPasses.skip(1)) {
        final o = toOffset(p.latitude, p.longitude);
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, passPaint);
    }
    final passDotPaint = Paint()..color = _passColor.withValues(alpha: 0.7);
    for (final p in sortedPasses) {
      canvas.drawCircle(toOffset(p.latitude, p.longitude), 2.5, passDotPaint);
    }

    // Route points: colored by match outcome + sequence number label
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final p in sortedPoints) {
      final color = switch (p.status) {
        RouteMatchStatus.matched => _matchedColor,
        RouteMatchStatus.missed => _missedColor,
        RouteMatchStatus.ambiguous => _ambiguousColor,
      };
      final o = toOffset(p.latitude, p.longitude);
      canvas.drawCircle(o, 7, Paint()..color = color);
      canvas.drawCircle(o, 7, borderPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: '${p.sequenceNo}',
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o + const Offset(10, -6));
    }
  }

  @override
  bool shouldRepaint(covariant _RouteMatchPainter oldDelegate) =>
      oldDelegate.points.length != points.length ||
      oldDelegate.passes.length != passes.length;
}
