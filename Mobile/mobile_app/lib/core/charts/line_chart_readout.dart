import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:hkt_livestock_agentic/core/utils/app_time.dart';

/// High-contrast hover/touch readout for a single-series line chart.
///
/// The chart keeps ownership of its dynamic value domain. This layer only
/// adds an overlay; it never changes chart bounds, position, or zoom.
class LineChartReadout extends StatefulWidget {
  const LineChartReadout({
    super.key,
    required this.timestamps,
    required this.formatValue,
    required this.chartDataBuilder,
    this.readoutTitle,
  });

  final List<DateTime?> timestamps;
  final String Function(double value) formatValue;
  final LineChartData Function(LineTouchData touchData) chartDataBuilder;
  final String? Function(int index)? readoutTitle;

  @override
  State<LineChartReadout> createState() => _LineChartReadoutState();
}

class _LineChartReadoutState extends State<LineChartReadout> {
  ChartReadoutData? _readout;

  void _handleTouchEvent(FlTouchEvent event, LineTouchResponse? response) {
    if (event is FlPointerExitEvent) {
      setState(() => _readout = null);
      return;
    }
    if (!event.isInterestedForInteractions) return;

    final spots = response?.lineBarSpots;
    final spot = spots == null || spots.isEmpty ? null : spots.first;
    final position = event.localPosition;
    if (spot == null || position == null) {
      if (_readout != null) setState(() => _readout = null);
      return;
    }

    final timestamps = widget.timestamps;
    final index = timestamps.isEmpty
        ? spot.spotIndex
        : spot.spotIndex.clamp(0, timestamps.length - 1);
    final timestamp = timestamps.isEmpty ? null : timestamps[index];
    final title =
        widget.readoutTitle?.call(index) ??
        (timestamp == null ? '' : formatMdhm(timestamp.toLocal()));

    final next = ChartReadoutData(
      position: position,
      title: title,
      value: widget.formatValue(spot.y),
    );
    if (next != _readout) setState(() => _readout = next);
  }

  @override
  Widget build(BuildContext context) {
    final chartData = widget.chartDataBuilder(
      LineTouchData(
        enabled: true,
        handleBuiltInTouches: false,
        touchCallback: _handleTouchEvent,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final chart = LineChart(chartData);
        final readout = _readout;
        if (readout == null || constraints.maxWidth.isInfinite) return chart;

        return Stack(
          children: [
            Positioned.fill(child: chart),
            Positioned(
              left: _readoutLeft(
                pointerX: readout.position.dx,
                width: constraints.maxWidth,
              ),
              top: (readout.position.dy - 48).clamp(
                8.0,
                math.max(8.0, constraints.maxHeight - 104),
              ),
              child: _ReadoutCard(data: readout),
            ),
          ],
        );
      },
    );
  }

  double _readoutLeft({required double pointerX, required double width}) {
    const cardWidth = 168.0;
    const margin = 8.0;
    if (width < cardWidth + margin * 2) return margin;
    if (pointerX <= width * 0.55) {
      return (pointerX + 12).clamp(margin, width - cardWidth - margin);
    }
    // Near the right edge, anchor the card's right side beside the pointer.
    return (pointerX - cardWidth - 12).clamp(
      margin,
      width - cardWidth - margin,
    );
  }
}

/// High-contrast hover/touch readout for a grouped bar chart.
class BarChartReadout extends StatefulWidget {
  const BarChartReadout({
    super.key,
    required this.timestamps,
    required this.formatValue,
    required this.chartDataBuilder,
    this.readoutTitle,
  });

  final List<DateTime?> timestamps;
  final String Function(double value) formatValue;
  final BarChartData Function(BarTouchData touchData) chartDataBuilder;
  final String? Function(int index)? readoutTitle;

  @override
  State<BarChartReadout> createState() => _BarChartReadoutState();
}

class _BarChartReadoutState extends State<BarChartReadout> {
  ChartReadoutData? _readout;

  void _handleTouchEvent(FlTouchEvent event, BarTouchResponse? response) {
    if (event is FlPointerExitEvent) {
      setState(() => _readout = null);
      return;
    }
    if (!event.isInterestedForInteractions) return;

    final touchedSpot = response?.spot;
    final position = event.localPosition;
    if (touchedSpot == null || position == null) {
      if (_readout != null) setState(() => _readout = null);
      return;
    }

    final index = touchedSpot.touchedBarGroupIndex;
    final timestamp = index >= 0 && index < widget.timestamps.length
        ? widget.timestamps[index]
        : null;
    final title =
        widget.readoutTitle?.call(index) ??
        (timestamp == null ? '' : formatMdhm(timestamp.toLocal()));

    final next = ChartReadoutData(
      position: position,
      title: title,
      value: widget.formatValue(touchedSpot.spot.y),
    );
    if (next != _readout) setState(() => _readout = next);
  }

  @override
  Widget build(BuildContext context) {
    final chartData = widget.chartDataBuilder(
      BarTouchData(
        enabled: true,
        handleBuiltInTouches: false,
        touchCallback: _handleTouchEvent,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final chart = BarChart(chartData);
        final readout = _readout;
        if (readout == null || constraints.maxWidth.isInfinite) return chart;

        return Stack(
          children: [
            Positioned.fill(child: chart),
            Positioned(
              left: _readoutLeft(
                pointerX: readout.position.dx,
                width: constraints.maxWidth,
              ),
              top: (readout.position.dy - 48).clamp(
                8.0,
                math.max(8.0, constraints.maxHeight - 104),
              ),
              child: _ReadoutCard(data: readout),
            ),
          ],
        );
      },
    );
  }

  double _readoutLeft({required double pointerX, required double width}) {
    const cardWidth = 168.0;
    const margin = 8.0;
    if (width < cardWidth + margin * 2) return margin;
    if (pointerX <= width * 0.55) {
      return (pointerX + 12).clamp(margin, width - cardWidth - margin);
    }
    return (pointerX - cardWidth - 12).clamp(
      margin,
      width - cardWidth - margin,
    );
  }
}

class ChartReadoutData {
  const ChartReadoutData({
    required this.position,
    required this.title,
    required this.value,
  });

  final Offset position;
  final String title;
  final String value;
}

class _ReadoutCard extends StatelessWidget {
  const _ReadoutCard({required this.data});

  final ChartReadoutData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xF0121A12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.title.isNotEmpty)
            Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (data.title.isNotEmpty) const SizedBox(height: 2),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
