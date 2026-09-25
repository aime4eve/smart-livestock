import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/fence_sandbox_painter.dart';

void main() {
  group('FenceSandboxGeometry.mapperFor', () {
    test('maps a square ring with 12% margins', () {
      final ring = [
        const LatLng(0, 0),
        const LatLng(0, 1),
        const LatLng(1, 1),
        const LatLng(1, 0),
      ];
      final map = FenceSandboxGeometry.mapperFor(
        ring: ring,
        dots: const [],
        size: const Size(100, 100),
      )!;

      // usable area is 76x76 centered in 100x100.
      final mapped = ring.map(map).toList();
      expect(mapped[0], const Offset(12, 88));
      expect(mapped[1], const Offset(88, 88));
      expect(mapped[2], const Offset(88, 12));
      expect(mapped[3], const Offset(12, 12));
    });

    test('clamps extreme flat shapes to the 20% floor', () {
      final ring = [
        const LatLng(0, 0),
        const LatLng(0, 10),
        const LatLng(0.1, 10),
        const LatLng(0.1, 0),
      ];
      final map = FenceSandboxGeometry.mapperFor(
        ring: ring,
        dots: const [],
        size: const Size(100, 100),
      )!;

      final ys = ring.map((p) => map(p).dy).toList();
      final drawnHeight = ys.reduce((a, b) => a > b ? a : b) -
          ys.reduce((a, b) => a < b ? a : b);
      // uniform scale would draw 0.76px; the floor is 20% of usable height.
      expect(drawnHeight, closeTo(100 * 0.2 * 0.76, 0.01));
      // the wide axis keeps its uniform fit.
      final drawnWidth = ring.map((p) => map(p).dx).reduce((a, b) => a > b ? a : b) -
          ring.map((p) => map(p).dx).reduce((a, b) => a < b ? a : b);
      expect(drawnWidth, closeTo(76, 0.01));
      final sx = (map(ring[1]).dx - map(ring[0]).dx) / 10;
      final sy = drawnHeight / 0.1;
      // the floor wins over shape honesty for degenerate spans.
      expect(sy / sx, greaterThan(1));
    });

    test('includes out-of-ring dots in the bounds', () {
      final ring = [
        const LatLng(0, 0),
        const LatLng(0, 1),
        const LatLng(1, 1),
        const LatLng(1, 0),
      ];
      const dot = FenceSandboxDot(
        id: 'd1',
        position: LatLng(1.5, 1.5),
        status: FenceDotStatus.alert,
      );
      final map = FenceSandboxGeometry.mapperFor(
        ring: ring,
        dots: [dot],
        size: const Size(100, 100),
      )!;

      final mappedDot = map(dot.position);
      expect(mappedDot, const Offset(88, 12));
      // The ring shrinks to leave room for the outside dot.
      expect(map(ring[2]).dx, closeTo(62.667, 0.001));
      expect(map(ring[2]).dy, closeTo(37.333, 0.001));
    });

    test('returns null for empty rings', () {
      final map = FenceSandboxGeometry.mapperFor(
        ring: const [],
        dots: const [],
        size: const Size(100, 100),
      );
      expect(map, isNull);
    });
  });

  group('FenceSandboxGeometry.pulseOpacity', () {
    test('safe dots stay fully opaque', () {
      expect(FenceSandboxGeometry.pulseOpacity(FenceDotStatus.safe, 0.37), 1);
    });

    test('watch and alert dip to the 0.30 floor', () {
      final watch = FenceSandboxGeometry.pulseOpacity(
        FenceDotStatus.watch,
        0.5 / 12,
      );
      final alert = FenceSandboxGeometry.pulseOpacity(
        FenceDotStatus.alert,
        0.5 / 19,
      );
      expect(watch, closeTo(0.30, 0.001));
      expect(alert, closeTo(0.30, 0.001));
    });

    test('alert phase is continuous across the master wrap', () {
      // Master loop 22.8s = 19 alert cycles, so progress 1 and 0 land on
      // the exact same phase.
      final before = FenceSandboxGeometry.pulseOpacity(
        FenceDotStatus.alert,
        1,
      );
      final after = FenceSandboxGeometry.pulseOpacity(FenceDotStatus.alert, 0);
      expect(before, after);
    });
  });

  group('FenceSandboxGeometry.dashedRingPath', () {
    test('on-length totals perimeter * on/(on+off) for a closed square', () {
      final square = [
        const Offset(0, 0),
        const Offset(88, 0),
        const Offset(88, 88),
        const Offset(0, 88),
      ];
      final path = FenceSandboxGeometry.dashedRingPath(square, 4, 3);
      var total = 0.0;
      for (final metric in path.computeMetrics()) {
        total += metric.length;
      }
      const perimeter = 88.0 * 4;
      expect(total, closeTo(perimeter * 4 / 7, 8));
    });

    test('long dashes cross vertices as single contours', () {
      final square = [
        const Offset(0, 0),
        const Offset(88, 0),
        const Offset(88, 88),
        const Offset(0, 88),
      ];
      final path = FenceSandboxGeometry.dashedRingPath(square, 100, 3);
      expect(path.computeMetrics().length, 4);
    });

    test('returns empty path for fewer than two points', () {
      expect(
        FenceSandboxGeometry.dashedRingPath(const [Offset(1, 1)], 4, 3),
        isNotNull,
      );
      expect(
        FenceSandboxGeometry.dashedRingPath(const [Offset(1, 1)], 4, 3)
            .computeMetrics()
            .isEmpty,
        isTrue,
      );
    });

    test('rotated polygons keep vertex-crossing dashes connected', () {
      const theta = math.pi / 6;
      Offset rotate(Offset p) => Offset(
            p.dx * math.cos(theta) - p.dy * math.sin(theta),
            p.dx * math.sin(theta) + p.dy * math.cos(theta),
          );
      final square = [
        const Offset(0, 0),
        const Offset(88, 0),
        const Offset(88, 88),
        const Offset(0, 88),
      ].map(rotate).toList();
      final path = FenceSandboxGeometry.dashedRingPath(square, 100, 3);
      expect(path.computeMetrics().length, 4);
    });
  });

  group('FenceSandboxPainter.shouldRepaint', () {
    final ring = [
      const LatLng(0, 0),
      const LatLng(1, 1),
      const LatLng(1, 0),
    ];

    test('repaints on progress, mode, color or grid change', () {
      const data = FenceSandboxData(ring: [], progress: 0);
      const next = FenceSandboxData(ring: [], progress: 0.5);
      const a = FenceSandboxPainter(
        data: data,
        ringColor: Color(0xFF4C9A5F),
      );
      expect(
        a.shouldRepaint(
          const FenceSandboxPainter(
            data: next,
            ringColor: Color(0xFF4C9A5F),
          ),
        ),
        isTrue,
      );
      expect(
        a.shouldRepaint(
          const FenceSandboxPainter(
            data: data,
            ringColor: Color(0xFF4A7F9D),
          ),
        ),
        isTrue,
      );
      expect(
        a.shouldRepaint(
          const FenceSandboxPainter(
            data: data,
            ringColor: Color(0xFF4C9A5F),
            drawGrid: true,
          ),
        ),
        isTrue,
      );
      expect(
        a.shouldRepaint(
          FenceSandboxPainter(
            data: FenceSandboxData(
              ring: ring,
              mode: FenceSandboxMode.detail,
            ),
            ringColor: const Color(0xFF4C9A5F),
          ),
        ),
        isTrue,
      );
      expect(a.shouldRepaint(a), isFalse);
    });
  });
}
