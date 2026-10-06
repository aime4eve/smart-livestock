import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_models.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/drinking_controller.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/widgets/drinking_event_list.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/widgets/drinking_states.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/widgets/drinking_time_distribution_chart.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/widgets/upgrade_overlay.dart';
import 'package:hkt_livestock_agentic/features/fever_warning/presentation/fever_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Drinking behavior detail section (NIX-256, spec-cards
/// drinking-detail-section.md, prototype screen 2): the fourth trend
/// section on the livestock detail page, mounted after the estrus trend
/// chart.
///
/// Layout: time-of-day distribution chart (hand-drawn, plan-pinned) →
/// 48h temperature × drinking overlay (fl_chart LineChart) with self/peer
/// segmented control → honesty note-box (always visible) → today's event
/// rows with the marking loop (4b).
///
/// Fever shadow regions (NIX-259 m-q, user ruling 2026-10-06 = implement):
/// buffered fever windows (6h defervescence included) arrive with the
/// drinking-events response and render as time-span color bands
/// (--fever @ 12% alpha) behind the 48h chart, with a "fever period + 6h
/// buffer" legend item. The prototype's in-band "发热期·已排除" caption is
/// carried by that legend item instead — fl_chart range annotations have
/// no label affordance, so the band + legend is the shipped form.
///
/// Other recorded deviation from the frozen prototype: the baseline is the
/// fever detail's per-cow baselineTemp (same convention as the existing
/// _FeverTrendSection baseline line), not a fixed 38.5.
class DrinkingDetailSection extends ConsumerStatefulWidget {
  const DrinkingDetailSection({super.key, required this.livestockId});

  final String livestockId;

  @override
  ConsumerState<DrinkingDetailSection> createState() =>
      _DrinkingDetailSectionState();
}

class _DrinkingDetailSectionState extends ConsumerState<DrinkingDetailSection> {
  bool _showPeer = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(
      drinkingSummaryControllerProvider(widget.livestockId),
    );
    final eventsAsync = ref.watch(
      drinkingEventsControllerProvider(widget.livestockId),
    );
    final state = resolveDrinkingCardUiState(
      hasCapsule: true,
      summary: summaryAsync,
    );

    // The card on the same page already renders noData/building; the
    // section mirrors the five-state convention but keeps its own header
    // so the section identity survives mid-load and on failure.
    Widget body;
    switch (state) {
      case DrinkingCardUiState.loading:
        body = const DrinkingSkeletonBlock();
      case DrinkingCardUiState.error:
        body = DrinkingErrorBlock(livestockId: widget.livestockId);
      case DrinkingCardUiState.noData:
      case DrinkingCardUiState.building:
        body = DrinkingStateCard(
          variant: state == DrinkingCardUiState.noData
              ? DrinkingStateVariant.noData
              : DrinkingStateVariant.building,
          sampleDays: summaryAsync.value?.baselineSampleDays ?? 0,
          baselineMinDays:
              summaryAsync.value?.baselineMinDays ?? kDrinkingBaselineMinDays,
        );
      case DrinkingCardUiState.ready:
        body = _ReadySection(
          livestockId: widget.livestockId,
          daily: summaryAsync.value!.summary7.daily,
          weeklyAvgPerDay: summaryAsync.value!.summary7.weekly?.avgPerDay,
          eventsAsync: eventsAsync,
          showPeer: _showPeer,
          onTogglePeer: (v) => setState(() => _showPeer = v),
        );
    }

    return Column(
      key: const Key('drinking-detail-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header: 8×8 --drinking dot + title (fs12 fw700).
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.drinking,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '💧 ${l10n.healthDrinkingDetailTitle}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        body,
      ],
    );
  }
}

class _ReadySection extends ConsumerWidget {
  const _ReadySection({
    required this.livestockId,
    required this.daily,
    required this.weeklyAvgPerDay,
    required this.eventsAsync,
    required this.showPeer,
    required this.onTogglePeer,
  });

  final String livestockId;
  final DrinkingDaily daily;
  final double? weeklyAvgPerDay;
  final AsyncValue<DrinkingEventsPage> eventsAsync;
  final bool showPeer;
  final ValueChanged<bool> onTogglePeer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Chart card A: today's drinking time distribution ──
        _ChartCard(
          title: '📊 ${l10n.healthDrinkingTimeDistribution}',
          right: l10n.healthDrinkingTotalToday(daily.count),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: eventsAsync.when(
                  loading: () => const SizedBox(
                    height: 96,
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (e, _) => SizedBox(
                    height: 96,
                    child: Center(
                      child: Text(
                        l10n.healthDrinkingStateError,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  data: (events) => DrinkingTimeDistributionChart(
                    eventHours: _todayCounted(events.events)
                        .map((e) => _localHourOfDay(e.eventStartAt))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              const DrinkingDistributionLegend(),
              const SizedBox(height: 7),
              Text(
                l10n.healthDrinkingConcentration(
                  drinkingInZonePercent(
                    eventsAsync.maybeWhen(
                      data: (page) => _todayCounted(page.events)
                          .map((e) => _localHourOfDay(e.eventStartAt)),
                      orElse: () => const <double>[],
                    ),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // ── Chart card B: 48h temperature × drinking ──
        _ChartCard(
          title: '🌡️ ${l10n.healthDrinkingTempOverlay}',
          right: null,
          trailing: _SegControl(showPeer: showPeer, onChanged: onTogglePeer),
          child: showPeer
              ? _PeerCompareView(
                  livestockId: livestockId,
                  weeklyAvgPerDay: weeklyAvgPerDay,
                )
              : _TempOverlayChart(
                  livestockId: livestockId,
                  eventsAsync: eventsAsync,
                ),
        ),
        const SizedBox(height: 10),
        // ── Honesty note-box (always visible) ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.drinking.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Text('ℹ️', style: TextStyle(fontSize: 13, height: 1.2)),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  l10n.healthDrinkingHonestyNote,
                  style: const TextStyle(
                    fontSize: 9.5,
                    height: 1.5,
                    color: AppColors.drinking,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // ── Event rows with the marking loop (4b) ──
        eventsAsync.when(
          loading: () => const SizedBox(
            height: 40,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (e, _) => Text(
            l10n.healthDrinkingStateError,
            style: const TextStyle(
              fontSize: 10,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          data: (page) =>
              DrinkingEventList(livestockId: livestockId, events: page.events),
        ),
      ],
    );
  }

  /// §15.3 counting rule: label != REJECTED && (not a candidate, or a
  /// confirmed candidate).
  static bool _isCounted(DrinkingEvent e) {
    return e.label != DrinkingLabel.rejected &&
        (!e.isCandidate || e.label == DrinkingLabel.confirmed);
  }

  static List<DrinkingEvent> _todayCounted(List<DrinkingEvent> events) {
    final now = DateTime.now();
    return events.where((e) {
      if (!_isCounted(e)) return false;
      final local = e.eventStartAt.toLocal();
      return local.year == now.year && local.month == now.month && local.day == now.day;
    }).toList();
  }

  static double _localHourOfDay(DateTime utcInstant) {
    final local = utcInstant.toLocal();
    return local.hour + local.minute / 60.0;
  }
}

/// chart-card container: bg --surface-alt, r12, shadow-card, padding 12,
/// with an 11px fw700 title row (mb8) and optional right note / trailing
/// widget.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, this.right, this.trailing, required this.child});

  final String title;
  final String? right;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(color: Color(0x0F263126), offset: Offset(0, 1), blurRadius: 3),
          BoxShadow(color: Color(0x0A263126), offset: Offset(0, 1), blurRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
              if (trailing == null && right != null)
                Text(
                  right!,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// .seg segmented control: container r999 p2 bg --surface border --border;
/// options 9px fw600 p3×7 secondary; selected bg --drinking + #fff.
class _SegControl extends StatelessWidget {
  const _SegControl({required this.showPeer, required this.onChanged});

  final bool showPeer;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegOption(
            label: l10n.healthDrinkingSegSelf,
            selected: !showPeer,
            onTap: () => onChanged(false),
          ),
          _SegOption(
            label: l10n.healthDrinkingSegPeer,
            selected: showPeer,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _SegOption extends StatelessWidget {
  const _SegOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? AppColors.drinking : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// The "self" 48h chart: rumen temperature line (--fever 2px, fever
/// detail recent72h filtered to the last 48h) + per-cow baseline dashed
/// line (existing _FeverTrendSection convention) + drinking valley dots
/// (r4 fill --drinking-event, white stroke 1.5) with temp-drop labels, as
/// a second dot-only data series, all over the fever shadow bands
/// (NIX-259 m-q): buffered fever windows rendered as time-span color
/// bands (--fever @ 12% alpha) via fl_chart `rangeAnnotations`.
class _TempOverlayChart extends ConsumerWidget {
  const _TempOverlayChart({required this.livestockId, required this.eventsAsync});

  final String livestockId;
  final AsyncValue<DrinkingEventsPage> eventsAsync;

  /// Fever band color: prototype screen 2 `--fever` #D97B29 at opacity
  /// .12 (the prototype's rx4 rounding has no fl_chart equivalent —
  /// VerticalRangeAnnotation fills a plain rectangle).
  static Color get _feverBandColor => AppColors.fever.withValues(alpha: 0.12);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final feverAsync = ref.watch(feverDetailControllerProvider(livestockId));

    return feverAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => SizedBox(
        height: 120,
        child: Center(
          child: Text(
            l10n.healthDrinkingTempUnavailable,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ),
      ),
      data: (fever) {
        final now = DateTime.now();
        final windowStart = now.subtract(const Duration(hours: 48));
        final readings = fever.recent72h
            .where((r) => !r.timestamp.isBefore(windowStart))
            .toList();
        if (readings.isEmpty) {
          return SizedBox(
            height: 120,
            child: Center(
              child: Text(
                l10n.healthDrinkingTempUnavailable,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        // Time-based X axis (epoch ms) so valley dots align with the line
        // regardless of sampling gaps.
        final minX = readings.first.timestamp.millisecondsSinceEpoch.toDouble();
        final maxX = now.millisecondsSinceEpoch.toDouble();

        final spots = readings
            .map(
              (r) => FlSpot(
                r.timestamp.millisecondsSinceEpoch.toDouble(),
                r.temperature,
              ),
            )
            .toList();

        // Valley dots: counted events inside the window, y = minTemp.
        final valleys = eventsAsync.maybeWhen(
          data: (page) => page.events
              .where(
                (e) =>
                    _ReadySection._isCounted(e) &&
                    !e.eventStartAt.isBefore(windowStart) &&
                    !e.eventStartAt.isAfter(now) &&
                    e.minTemp != null,
              )
              .map((e) => (e.eventStartAt.millisecondsSinceEpoch.toDouble(), e))
              .toList(),
          orElse: () => const <(double, DrinkingEvent)>[],
        );

        // Fever shadow bands: server windows clipped to the visible chart
        // window (belt-and-braces on top of the server-side clip) and
        // drawn as vertical range annotations behind everything.
        final feverBands = _feverRangeAnnotations(
          eventsAsync.maybeWhen(
            data: (page) => page.feverWindows,
            orElse: () => const <FeverWindow>[],
          ),
          windowStart,
          now,
        );

        var minY = readings
            .map((r) => r.temperature)
            .reduce((a, b) => a < b ? a : b);
        var maxY = readings
            .map((r) => r.temperature)
            .reduce((a, b) => a > b ? a : b);
        for (final (_, e) in valleys) {
          minY = minY < e.minTemp! ? minY : e.minTemp!;
          maxY = maxY > e.minTemp! ? maxY : e.minTemp!;
        }
        minY -= 0.3;
        maxY += 0.3;

        return Column(
          children: [
            Container(
              height: 120,
              padding: const EdgeInsets.all(8),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  rangeAnnotations: RangeAnnotations(
                    verticalRangeAnnotations: feverBands,
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: AppColors.fever,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                    // Baseline dashed line — the fever detail's per-cow
                    // baseline, same convention as _FeverTrendSection.
                    LineChartBarData(
                      spots: [
                        FlSpot(minX, fever.baselineTemp),
                        FlSpot(maxX, fever.baselineTemp),
                      ],
                      color: AppColors.textSecondary.withValues(alpha: 0.35),
                      dashArray: const [4, 4],
                      barWidth: 1,
                      dotData: const FlDotData(show: false),
                    ),
                    // Drinking valley series: dot-only.
                    LineChartBarData(
                      spots: [
                        for (final (x, e) in valleys) FlSpot(x, e.minTemp!),
                      ],
                      color: AppColors.drinkingEvent,
                      barWidth: 0,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            _ValleyDotPainter(
                          dropLabel: valleys[index].$2.tempDrop == null
                              ? null
                              : '−${valleys[index].$2.tempDrop!.toStringAsFixed(1)}°C',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 7),
            // Legend: temperature line, valley dots, baseline, fever band
            // (NIX-259 m-q — the "发热期·已排除" caption rides this item).
            Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _legendSwatch(AppColors.fever, l10n.healthDrinkingLegendTemp, 3),
                _legendDot(AppColors.drinkingEvent, l10n.healthDrinkingLegendValley),
                _legendSwatch(
                  AppColors.textSecondary.withValues(alpha: 0.35),
                  l10n.healthDrinkingLegendBaseline,
                  3,
                ),
                _legendSwatch(
                  AppColors.fever.withValues(alpha: 0.2),
                  l10n.healthDrinkingLegendFever,
                  2,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Build the fever shadow bands clipped to the visible chart window:
  /// x1/x2 clamped to [windowStart, now] in epoch-ms chart units; windows
  /// that do not intersect the window are dropped. The server already
  /// clips to the queried cow-day range — this guards the chart's own
  /// 48h sub-window (which starts mid-day) and any legacy payload.
  static List<VerticalRangeAnnotation> _feverRangeAnnotations(
    List<FeverWindow> windows,
    DateTime windowStart,
    DateTime now,
  ) {
    final minX = windowStart.millisecondsSinceEpoch.toDouble();
    final maxX = now.millisecondsSinceEpoch.toDouble();
    return windows
        .map((w) {
          final x1 = w.start.millisecondsSinceEpoch.toDouble();
          final x2 = w.end.millisecondsSinceEpoch.toDouble();
          final start = x1 < minX ? minX : x1;
          final end = x2 > maxX ? maxX : x2;
          if (start >= end) return null;
          return VerticalRangeAnnotation(
            x1: start,
            x2: end,
            color: _feverBandColor,
          );
        })
        .whereType<VerticalRangeAnnotation>()
        .toList();
  }

  static Widget _legendSwatch(Color color, String label, double radius) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 8.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  static Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 8.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Valley dot painter: r4 circle fill --drinking-event with a 1.5px white
/// stroke + the temp-drop label (fs7.5 fw700 --drinking-event) below the
/// dot, replicating the prototype's circle + "−1.7°C" annotation.
class _ValleyDotPainter extends FlDotPainter {
  _ValleyDotPainter({this.dropLabel});

  final String? dropLabel;

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    canvas.drawCircle(
      offsetInCanvas,
      4 + 0.75,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      offsetInCanvas,
      4,
      Paint()
        ..color = AppColors.drinkingEvent
        ..style = PaintingStyle.fill,
    );
    final label = dropLabel;
    if (label != null) {
      TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 7.5,
            fontWeight: FontWeight.w700,
            color: AppColors.drinkingEvent,
          ),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(canvas, offsetInCanvas + const Offset(5, 5));
    }
  }

  @override
  Size getSize(FlSpot spot) => const Size(8, 8);

  @override
  Color get mainColor => AppColors.drinkingEvent;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) => this;

  @override
  List<Object?> get props => [dropLabel];
}

/// The "peer" side of the segmented control (Premium, prototype screen 5):
/// 403 → full UpgradeOverlay over dimmed grey-green bars;
/// INSUFFICIENT_PEERS → degraded copy; otherwise a compact two-bar
/// comparison of the own 7-day average vs the peer group average.
class _PeerCompareView extends ConsumerWidget {
  const _PeerCompareView({required this.livestockId, required this.weeklyAvgPerDay});

  final String livestockId;
  final double? weeklyAvgPerDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final peerAsync = ref.watch(drinkingPeerControllerProvider(livestockId));

    return peerAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) {
        if (e is ForbiddenException) {
          // Premium locked state (screen 5): dim + blur + lock message +
          // upgrade button + tier badge over the grey-green placeholder.
          return SizedBox(
            height: 140,
            child: UpgradeOverlay(
              onUpgrade: () => context.go(AppRoute.subscription.path),
              child: _PeerDimBars(title: l10n.healthDrinkingPeerCompareTitle),
            ),
          );
        }
        return SizedBox(
          height: 120,
          child: Center(
            child: Text(
              l10n.healthDrinkingStateError,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ),
        );
      },
      data: (peer) {
        if (peer.insufficientPeers || peer.peerAvgPerDay == null) {
          return SizedBox(
            height: 96,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.healthDrinkingPeerInsufficient(peer.minSampleDays),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }
        return _PeerBars(
          selfAvg: weeklyAvgPerDay,
          peerAvg: peer.peerAvgPerDay!,
        );
      },
    );
  }
}

/// Dimmed content behind the Premium lock: chart-title + grey-green
/// placeholder bars (--accent).
class _PeerDimBars extends StatelessWidget {
  const _PeerDimBars({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '📊 $title',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final h in const [36, 38, 42, 34, 36, 40, 36])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Container(
                      height: h.toDouble(),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact two-row comparison (self 7-day avg vs peer group avg): label +
/// proportional bar + value, both scaled to the larger average.
class _PeerBars extends StatelessWidget {
  const _PeerBars({required this.selfAvg, required this.peerAvg});

  final double? selfAvg;
  final double peerAvg;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final self = selfAvg;
    final maxAvg = self != null && self > peerAvg ? self : peerAvg;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _PeerBarRow(
            label: l10n.healthDrinkingPeerCompareSelf,
            value: self,
            color: AppColors.drinking,
            maxAvg: maxAvg,
          ),
          const SizedBox(height: 8),
          _PeerBarRow(
            label: l10n.healthDrinkingPeerComparePeer,
            value: peerAvg,
            color: AppColors.accent,
            maxAvg: maxAvg,
          ),
        ],
      ),
    );
  }
}

class _PeerBarRow extends StatelessWidget {
  const _PeerBarRow({
    required this.label,
    required this.value,
    required this.color,
    required this.maxAvg,
  });

  final String label;
  final double? value;
  final Color color;
  final double maxAvg;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = value;
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: v == null || maxAvg <= 0 ? 0 : (v / maxAvg).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 64,
          child: Text(
            v == null ? '--' : l10n.healthDrinkingPerDay(v.toStringAsFixed(1)),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
