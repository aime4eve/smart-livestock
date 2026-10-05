import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Demo feed/milking peak reference zones (prototype screen 2, spec-card
/// drinking-detail-section.md). Coordinates in the 340×96 viewBox are
/// mapped to clock hours via x = 10 + hour/24 * 320.
///
/// TODO(NIX-256 P2): farm-specific feeding/milking schedules ("牧场定制列
/// P2") — these demo windows are placeholder reference zones only.
class _PeakZone {
  const _PeakZone(this.startHour, this.endHour, this.labelKey);

  final double startHour;
  final double endHour;
  final _ZoneLabel labelKey;
}

enum _ZoneLabel { feed, milking, evening }

const List<_PeakZone> _kDrinkingPeakZones = [
  _PeakZone(1.5, 4.65, _ZoneLabel.feed),
  _PeakZone(10.5, 13.65, _ZoneLabel.milking),
  _PeakZone(18.0, 21.45, _ZoneLabel.evening),
];

/// Share of the given events (by local start hour) that fall inside one of
/// the peak reference zones — the "75% 饮水集中在饲喂/挤奶后" subtitle.
int drinkingInZonePercent(Iterable<double> hours) {
  final list = hours.toList();
  if (list.isEmpty) return 0;
  var inZone = 0;
  for (final hour in list) {
    for (final zone in _kDrinkingPeakZones) {
      if (hour >= zone.startHour && hour <= zone.endHour) {
        inZone++;
        break;
      }
    }
  }
  return (inZone * 100 / list.length).round();
}

/// Today's drinking time-of-day distribution chart (NIX-256, prototype
/// screen 2 chart A). Hand-drawn per the plan decision (时刻分布自绘,
/// aligned with the project's contact-tracing custom-paint convention):
/// 24h axis + diamond event markers + three peak reference zones + axis
/// labels, painted in the prototype's 340×96 logical space (X stretched to
/// the available width, Y fixed).
class DrinkingTimeDistributionChart extends StatelessWidget {
  const DrinkingTimeDistributionChart({super.key, required this.eventHours});

  /// Local-clock start hour (0..24, fractional) of each of today's
  /// counted drinking events.
  final List<double> eventHours;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CustomPaint(
      key: const Key('drinking-time-distribution'),
      foregroundPainter: _TimeDistributionPainter(
        zoneLabels: {
          _ZoneLabel.feed: l10n.healthDrinkingZoneFeed,
          _ZoneLabel.milking: l10n.healthDrinkingZoneMilking,
          _ZoneLabel.evening: l10n.healthDrinkingZoneEvening,
        },
        axisLabels: [
          l10n.healthDrinkingAxisHour(0),
          l10n.healthDrinkingAxisHour(8),
          l10n.healthDrinkingAxisHour(16),
          l10n.healthDrinkingAxisHour(24),
        ],
        eventHours: eventHours,
      ),
      child: const SizedBox(height: 96, width: double.infinity),
    );
  }
}

class _TimeDistributionPainter extends CustomPainter {
  _TimeDistributionPainter({
    required this.zoneLabels,
    required this.axisLabels,
    required this.eventHours,
  });

  final Map<_ZoneLabel, String> zoneLabels;
  final List<String> axisLabels;
  final List<double> eventHours;

  // Logical viewBox from the prototype SVG: width 340, height 96.
  static const double _w = 340;
  static const double _axisY = 78;
  static const double _zoneTop = 8;
  static const double _zoneHeight = 70;
  static const double _x0 = 10;
  static const double _x1 = 330;

  /// Zone/axis label size. Prototype v1.2 drew these at 7.5px — CJK strokes
  /// collapse at that size on device; 9.5 matches the prototype's own
  /// caption scale (readability fix 2026-10-06, user-approved deviation).
  static const double _labelFontSize = 9.5;

  double _hourToX(double hour) => _x0 + (hour / 24) * (_x1 - _x0);

  @override
  void paint(Canvas canvas, Size size) {
    // preserveAspectRatio="none": stretch X to the full width, keep Y 1:1
    // plus vertical centering in the 96px band.
    final sx = size.width / _w;
    canvas.save();
    canvas.scale(sx, 1.0);

    // ── Peak reference zones: fill --map-green (#DCE8D5) opacity .55, rx3.
    final zonePaint = Paint()..color = AppColors.mapGreen.withValues(alpha: 0.55);
    final bandLabelTexts = <({Offset pos, String text})>[];
    for (final zone in _kDrinkingPeakZones) {
      final left = _hourToX(zone.startHour);
      final right = _hourToX(zone.endHour);
      final rect = Rect.fromLTRB(left, _zoneTop, right, _zoneTop + _zoneHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        zonePaint,
      );
      bandLabelTexts.add((
        pos: Offset(left + 3, _zoneTop + 3),
        text: zoneLabels[zone.labelKey]!,
      ));
    }

    // ── Time axis: line y78 x10–330 stroke --border w1 + tick labels.
    final axisPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    canvas.drawLine(
      const Offset(_x0, _axisY),
      const Offset(_x1, _axisY),
      axisPaint,
    );

    // ── Drinking event diamonds: fill --drinking, 10×10 (path l5,6
    // -5,6 -5,-6), centered on the event hour at y70.
    final diamondPaint = Paint()..color = AppColors.drinking;
    const center = 70.0;
    for (final hour in eventHours) {
      final x = _hourToX(hour);
      final path = Path()
        ..moveTo(x, center - 6)
        ..lineTo(x + 5, center)
        ..lineTo(x, center + 6)
        ..lineTo(x - 5, center)
        ..close();
      canvas.drawPath(path, diamondPaint);
    }

    canvas.restore();

    // Text is drawn OUTSIDE the X-scaled canvas (x premultiplied by sx):
    // glyphs inside scale(sx, 1) stretch horizontally ~15% on wide phones,
    // smearing CJK strokes (readability fix 2026-10-06, prototype v1.3).
    for (final t in bandLabelTexts) {
      _drawText(
        canvas,
        t.text,
        Offset(t.pos.dx * sx, t.pos.dy),
        fontSize: _labelFontSize,
        color: const Color(0xFF3D6743),
      );
    }
    const axisHours = [0.0, 8.0, 16.0, 24.0];
    const axisLabelX = [6.0, 105.0, 205.0, 310.0];
    for (var i = 0; i < axisHours.length; i++) {
      _drawText(
        canvas,
        axisLabels[i],
        Offset(axisLabelX[i] * sx, _axisY + 6),
        fontSize: _labelFontSize,
        color: AppColors.textSecondary,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset topLeft, {
    required double fontSize,
    required Color color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, topLeft);
  }

  @override
  bool shouldRepaint(covariant _TimeDistributionPainter oldDelegate) {
    return oldDelegate.eventHours != eventHours ||
        oldDelegate.zoneLabels != zoneLabels ||
        oldDelegate.axisLabels != axisLabels;
  }
}

/// Legend row for the distribution chart: 8×8 rotated diamond swatch +
/// label / 10×10 r3 green swatch + label (fs8.5 secondary, gap 10).
class DrinkingDistributionLegend extends StatelessWidget {
  const DrinkingDistributionLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 8,
                height: 8,
                color: AppColors.drinking,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              l10n.healthDrinkingLegendEvent,
              style: const TextStyle(
                fontSize: 8.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.mapGreen,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              l10n.healthDrinkingLegendZone,
              style: const TextStyle(
                fontSize: 8.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
