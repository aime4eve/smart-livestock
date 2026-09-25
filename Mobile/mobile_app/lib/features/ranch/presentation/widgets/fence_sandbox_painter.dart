import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;

import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';

/// Livestock fence status for sandbox dot coloring. Values mirror the
/// `fenceStatusMap` built by RanchPage (SAFE / APPROACH / BREACH).
enum FenceDotStatus { safe, watch, alert }

class FenceSandboxDot {
  const FenceSandboxDot({
    required this.id,
    required this.position,
    this.status = FenceDotStatus.safe,
  });

  final String id;
  final LatLng position;
  final FenceDotStatus status;
}

enum FenceSandboxMode { list, detail }

/// Pure geographic-to-canvas mapping shared by the painter and unit tests.
class FenceSandboxGeometry {
  const FenceSandboxGeometry._();

  static const double marginRatio = 0.12;

  /// Shared master loop: the common period of scan 3.8s, watch 1.9s and
  /// alert 1.2s, so every phase wraps without a visible jump. The scan
  /// derives 6 cycles, watch 12, alert 19.
  static const double masterPeriodSeconds = 22.8;

  /// Minimum share of the usable canvas side the shorter shape span keeps.
  ///
  /// Visibility beats shape fidelity for degenerate spans (Spec §6): an
  /// extreme line-like fence is stretched to stay readable instead of
  /// collapsing into an invisible line.
  static const double minAxisShare = 0.2;

  static Rect _boundsOf(List<LatLng> ring, List<FenceSandboxDot> dots) {
    var minX = 0.0, minY = 0.0, maxX = 0.0, maxY = 0.0;
    var first = true;
    void add(LatLng p) {
      if (first) {
        minX = maxX = p.longitude;
        minY = maxY = p.latitude;
        first = false;
        return;
      }
      minX = math.min(minX, p.longitude);
      maxX = math.max(maxX, p.longitude);
      minY = math.min(minY, p.latitude);
      maxY = math.max(maxY, p.latitude);
    }

    for (final p in ring) {
      add(p);
    }
    for (final d in dots) {
      add(d.position);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Builds a lat/lng -> canvas mapper. Returns null when there is nothing
  /// to draw (no ring points).
  static Offset Function(LatLng)? mapperFor({
    required List<LatLng> ring,
    required List<FenceSandboxDot> dots,
    required Size size,
  }) {
    if (ring.isEmpty || size.isEmpty) {
      return null;
    }
    final bounds = _boundsOf(ring, dots);
    final spanX = bounds.width.abs() < 1e-9 ? 1e-9 : bounds.width;
    final spanY = bounds.height.abs() < 1e-9 ? 1e-9 : bounds.height;

    final usableW = size.width * (1 - marginRatio * 2);
    final usableH = size.height * (1 - marginRatio * 2);
    final uniform = math.min(usableW / spanX, usableH / spanY);

    var sx = uniform;
    var sy = uniform;
    final floorH = usableH * minAxisShare;
    final floorW = usableW * minAxisShare;
    if (spanY * sy < floorH) {
      sy = floorH / spanY;
    }
    if (spanX * sx < floorW) {
      sx = floorW / spanX;
    }

    final drawnW = spanX * sx;
    final drawnH = spanY * sy;
    final originX = (size.width - drawnW) / 2;
    final originY = (size.height - drawnH) / 2;

    return (LatLng p) => Offset(
          originX + (p.longitude - bounds.left) * sx,
          originY + (bounds.bottom - p.latitude) * sy,
        );
  }

  /// Pulse opacity for non-safe dots. The shared master loop is the common
  /// period [masterPeriodSeconds], so every phase completes an integer
  /// number of cycles per loop and never jumps at the wrap point.
  static double pulseOpacity(FenceDotStatus status, double progress) {
    if (status == FenceDotStatus.safe) {
      return 1;
    }
    final cycles = status == FenceDotStatus.watch ? 12 : 19;
    final phase = (progress * cycles) % 1;
    // Keyframes mirror the prototype: opacity 1 at phase 0, 0.30 at 0.5.
    return 0.30 + 0.70 * (0.5 + 0.5 * math.cos(2 * math.pi * phase));
  }

  /// Builds the polygon outline as alternating dash segments, closing the
  /// loop. Flutter has no Skia-style PathEffect, so dashes are emitted
  /// manually. An on-dash crossing a vertex stays in the same subpath
  /// (lineTo continues) so corners join like a continuous stroke.
  static Path dashedRingPath(
    List<Offset> points,
    double onLen,
    double offLen,
  ) {
    final path = Path();
    if (points.length < 2) {
      return path;
    }
    final loop = [...points, points.first];
    var drawing = true;
    var remain = onLen;
    var penActive = false;
    for (var i = 0; i < loop.length - 1; i++) {
      var start = loop[i];
      final end = loop[i + 1];
      final delta = end - start;
      var segLen = delta.distance;
      if (segLen <= 0) {
        continue;
      }
      final dir = delta / segLen;
      while (segLen > 0) {
        final step = math.min(segLen, remain);
        final next = start + dir * step;
        if (drawing) {
          if (!penActive) {
            path.moveTo(start.dx, start.dy);
          }
          path.lineTo(next.dx, next.dy);
          penActive = true;
        } else if (penActive) {
          penActive = false;
        }
        segLen -= step;
        start = next;
        remain -= step;
        if (remain <= 0) {
          drawing = !drawing;
          remain = drawing ? onLen : offLen;
        }
      }
    }
    return path;
  }
}

class FenceSandboxData {
  const FenceSandboxData({
    required this.ring,
    this.dots = const [],
    this.mode = FenceSandboxMode.list,
    this.progress = 0,
  });

  final List<LatLng> ring;
  final List<FenceSandboxDot> dots;
  final FenceSandboxMode mode;

  /// Master animation progress in [0,1]; the caller loops it over the
  /// common cycle [FenceSandboxGeometry.masterPeriodSeconds] (22.8s),
  /// from which the scan derives 6 cycles.
  final double progress;
}

class FenceSandboxPainter extends CustomPainter {
  const FenceSandboxPainter({
    required this.data,
    required this.ringColor,
    this.drawGrid = false,
  });

  final FenceSandboxData data;
  final Color ringColor;
  final bool drawGrid;

  static const Color _vertexDot = Color(0xFF8FD694);
  static const Color _gridLine = Color(0x0F8FD694);

  @override
  void paint(Canvas canvas, Size size) {
    if (drawGrid) {
      _paintGrid(canvas, size);
    }
    // Fewer than 3 points cannot form a fence; the container draws the
    // gray placeholder outline instead (Spec §3.2).
    if (data.ring.length < 3) {
      return;
    }
    final map = FenceSandboxGeometry.mapperFor(
      ring: data.ring,
      dots: data.dots,
      size: size,
    );
    if (map == null) {
      return;
    }

    final isDetail = data.mode == FenceSandboxMode.detail;
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = ringColor.withValues(alpha: isDetail ? 0.30 : 0.16);
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDetail ? 2.0 : 1.5
      ..color = ringColor;

    final points = data.ring.map(map).toList();
    final path = Path();
    if (points.isNotEmpty) {
      path.addPolygon(points, data.ring.length > 2);
    }
    canvas.drawPath(path, fillPaint);
    final dashed = FenceSandboxGeometry.dashedRingPath(
      points,
      isDetail ? 6.0 : 4.0,
      isDetail ? 4.0 : 3.0,
    );
    canvas.drawPath(dashed, strokePaint);

    if (isDetail) {
      final vertexPaint = Paint()..color = _vertexDot;
      for (final p in data.ring) {
        canvas.drawCircle(map(p), 2.2, vertexPaint);
      }
    }

    for (final dot in data.dots) {
      final pulse = FenceSandboxGeometry.pulseOpacity(dot.status, data.progress);
      final base = isDetail ? 2.2 : 2.0;
      final radius =
          dot.status == FenceDotStatus.alert ? (isDetail ? 2.6 : 2.4) : base;
      canvas.drawCircle(
        map(dot.position),
        radius,
        Paint()..color = _dotColor(dot.status).withValues(alpha: pulse),
      );
    }
  }

  Color _dotColor(FenceDotStatus status) {
    switch (status) {
      case FenceDotStatus.watch:
        return AppColors.warning;
      case FenceDotStatus.alert:
        return AppColors.danger;
      case FenceDotStatus.safe:
        return AppColors.success;
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _gridLine;
    const step = 16.0;
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant FenceSandboxPainter oldDelegate) {
    return oldDelegate.data.progress != data.progress ||
        oldDelegate.data.ring != data.ring ||
        oldDelegate.data.dots != data.dots ||
        oldDelegate.data.mode != data.mode ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.drawGrid != drawGrid;
  }
}
