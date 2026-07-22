import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';

/// Trajectory comparison chart (no map tiles).
///
/// Draws the RTK truth track (solid green polyline), the device-reported
/// track (dashed red polyline), pair links between matched points, and
/// hollow markers for unpaired points. Lat/lng bounds auto-scale to fit.
class TrajectoryChart extends StatelessWidget {
  const TrajectoryChart({
    super.key,
    required this.points,
    this.width = 560,
    this.height = 300,
  });

  final List<TrajectoryTrackPoint> points;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _TrajectoryPainter(points: points)),
    );
  }
}

class _TrajectoryPainter extends CustomPainter {
  _TrajectoryPainter({required this.points});

  final List<TrajectoryTrackPoint> points;

  static const _padding = 24.0;
  static const _gridColor = Color(0xFFE2E8F0);
  static const _rtkColor = Color(0xFF2F6B3B);
  static const _deviceColor = Color(0xFFC2564B);
  static const _linkColor = Color(0xFF8BA95A);
  static const _unpairedColor = Color(0xFFD28A2D);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFEDEBE3),
    );

    // Grid
    final gridPaint = Paint()
      ..color = _gridColor
      ..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      final x = size.width * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    if (points.isEmpty) return;

    double minLat = double.infinity, maxLat = -double.infinity;
    double minLng = double.infinity, maxLng = -double.infinity;
    void extend(double lat, double lng) {
      minLat = math.min(minLat, lat);
      maxLat = math.max(maxLat, lat);
      minLng = math.min(minLng, lng);
      maxLng = math.max(maxLng, lng);
    }

    for (final p in points) {
      extend(p.rtkLatitude, p.rtkLongitude);
      if (p.paired) extend(p.deviceLatitude!, p.deviceLongitude!);
    }
    // Guard against degenerate bounds (single point / all identical)
    if ((maxLat - minLat) < 1e-9) {
      minLat -= 0.0001;
      maxLat += 0.0001;
    }
    if ((maxLng - minLng) < 1e-9) {
      minLng -= 0.0001;
      maxLng += 0.0001;
    }

    Offset project(double lat, double lng) {
      final w = size.width - _padding * 2;
      final h = size.height - _padding * 2;
      final x = _padding + (lng - minLng) / (maxLng - minLng) * w;
      final y = size.height - _padding - (lat - minLat) / (maxLat - minLat) * h;
      return Offset(x, y);
    }

    // RTK truth track (solid)
    final rtkPaint = Paint()
      ..color = _rtkColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final rtkPath = Path();
    for (int i = 0; i < points.length; i++) {
      final o = project(points[i].rtkLatitude, points[i].rtkLongitude);
      if (i == 0) {
        rtkPath.moveTo(o.dx, o.dy);
      } else {
        rtkPath.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(rtkPath, rtkPaint);

    // Pair links + device track (dashed)
    final linkPaint = Paint()
      ..color = _linkColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final devicePaint = Paint()
      ..color = _deviceColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    Offset? prevDevice;
    for (final p in points) {
      final rtkO = project(p.rtkLatitude, p.rtkLongitude);
      if (p.paired) {
        final devO = project(p.deviceLatitude!, p.deviceLongitude!);
        _drawDashedLine(canvas, rtkO, devO, linkPaint, dash: 2, gap: 2);
        if (prevDevice != null) {
          _drawDashedLine(canvas, prevDevice, devO, devicePaint, dash: 5, gap: 4);
        }
        prevDevice = devO;
      } else {
        // Unpaired: hollow marker
        canvas.drawCircle(
          rtkO,
          5,
          Paint()
            ..color = _unpairedColor
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
        );
      }
    }

    // RTK dots on top
    final dotPaint = Paint()..color = _rtkColor;
    for (final p in points) {
      canvas.drawCircle(project(p.rtkLatitude, p.rtkLongitude), 3.5, dotPaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint,
      {double dash = 5, double gap = 4}) {
    final total = (to - from).distance;
    if (total < 1e-6) return;
    final dir = (to - from) / total;
    double pos = 0;
    while (pos < total) {
      final end = math.min(pos + dash, total);
      canvas.drawLine(from + dir * pos, from + dir * end, paint);
      pos = end + gap;
    }
  }

  @override
  bool shouldRepaint(_TrajectoryPainter oldDelegate) =>
      oldDelegate.points != points;
}
