import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_models.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/drinking_controller.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/widgets/drinking_states.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/widgets/upgrade_overlay.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Drinking behavior summary card for the livestock detail page (NIX-256,
/// spec-cards drinking-card.md, prototype screen 1 / v1.3).
///
/// Five states (shared with the detail section, spec §3.3):
/// loading skeleton / 5xx error card / noData (no bound capsule) /
/// building (< 3 baseline sample days) / ready. The backfill state is
/// skipped in P1 — its trigger (gateway-offline detection) does not exist
/// yet; see DrinkingStateCard doc and the TODO in drinking-states.
///
/// The app-wide [Card] theme does not match the frozen prototype card
/// values (r12 + shadow-card + padding 12), so the container is built
/// inline per the prototype CSS (same approach as PhysiologyRecordCard).
class DrinkingCard extends ConsumerWidget {
  const DrinkingCard({
    super.key,
    required this.livestockId,
    required this.hasCapsule,
    this.onTap,
  });

  final String livestockId;

  /// True when the livestock has a bound rumen capsule
  /// (detail.devices contains DeviceType.rumenCapsule) — drives the
  /// noData state (spec §3.3).
  final bool hasCapsule;

  /// Taps open the drinking detail section (mounted below on the same
  /// page); the page wires this to Scrollable.ensureVisible.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(drinkingSummaryControllerProvider(livestockId));
    final peerAsync = ref.watch(drinkingPeerControllerProvider(livestockId));
    final state = resolveDrinkingCardUiState(
      hasCapsule: hasCapsule,
      summary: summaryAsync,
    );

    return GestureDetector(
      key: const Key('drinking-card'),
      onTap: state == DrinkingCardUiState.ready ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.all(Radius.circular(12)),
          // --shadow-card: 0 1px 3px rgba(38,49,38,.06), 0 1px 2px rgba(38,49,38,.04)
          boxShadow: [
            BoxShadow(color: Color(0x0F263126), offset: Offset(0, 1), blurRadius: 3),
            BoxShadow(color: Color(0x0A263126), offset: Offset(0, 1), blurRadius: 2),
          ],
        ),
        child: switch (state) {
          DrinkingCardUiState.loading => const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardHeader(),
              SizedBox(height: 8),
              DrinkingSkeletonBlock(),
            ],
          ),
          DrinkingCardUiState.error => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CardHeader(),
              const SizedBox(height: 8),
              DrinkingErrorBlock(livestockId: livestockId),
            ],
          ),
          // The loading/error states keep the card header so the card
          // keeps its identity mid-load and on failure (same shape as the
          // PhysiologyRecordCard convention).
          DrinkingCardUiState.noData => const DrinkingStateCard(
            variant: DrinkingStateVariant.noData,
          ),
          DrinkingCardUiState.building => DrinkingStateCard(
            variant: DrinkingStateVariant.building,
            sampleDays: summaryAsync.value?.baselineSampleDays ?? 0,
            baselineMinDays:
                summaryAsync.value?.baselineMinDays ?? kDrinkingBaselineMinDays,
          ),
          DrinkingCardUiState.ready => _ReadyContent(
            bundle: summaryAsync.value!,
            peerAsync: peerAsync,
          ),
        },
      ),
    );
  }
}

/// Title row: 8×8 --drinking dot + "饮水行为" (fs12 fw700) + chip.drinking
/// "今日 N 次".
class _CardHeader extends StatelessWidget {
  const _CardHeader({this.todayCount});

  final int? todayCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
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
          l10n.healthDrinkingTitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (todayCount != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.drinkingSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              l10n.healthDrinkingTodayCount(todayCount!),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.drinking,
              ),
            ),
          ),
      ],
    );
  }
}

/// Ready-state content: header chip + big number row + 7-day mini bars +
/// dual-reference subtitle (peer avg + own baseline) + fever context note.
class _ReadyContent extends StatelessWidget {
  const _ReadyContent({
    required this.bundle,
    required this.peerAsync,
  });

  final DrinkingSummaryBundle bundle;
  final AsyncValue<DrinkingPeerComparison> peerAsync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final daily = bundle.summary7.daily;
    final bars = bundle.weekBars;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CardHeader(todayCount: daily.count),
        // bignum-row: baseline-aligned, gap 6
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${daily.count}',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.drinking,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.healthDrinkingTodayUnit,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.healthDrinkingLastDrink,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _relativeLastDrink(context, daily.lastDrinkEndAt),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (bars.isNotEmpty) ...[
          const SizedBox(height: 10),
          _MiniBars(bars: bars),
        ],
        const SizedBox(height: 8),
        _PeerBaselineLine(
          peerAsync: peerAsync,
          baseline: bundle.rolling30dBaseline?.avgPerDay,
        ),
        if (bundle.lastFeverDay != null) ...[
          const SizedBox(height: 10),
          _FeverContextNote(feverDay: bundle.lastFeverDay!),
        ],
      ],
    );
  }

  /// "35 分钟前" — minutes under one hour, else the local wall clock
  /// (yesterday's events would read as a misleading 1,440+ minutes).
  static String _relativeLastDrink(BuildContext context, DateTime? endUtc) {
    if (endUtc == null) return '--';
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(endUtc.toLocal());
    if (diff.isNegative) return '--';
    final minutes = diff.inMinutes;
    if (minutes < 60) return l10n.healthDrinkingMinutesAgo(minutes);
    final local = endUtc.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    return sameDay ? '$hh:$mm' : l10n.healthDrinkingYesterdayAt('$hh:$mm');
  }
}

/// mini-bars (h44 visual band, 7 columns, gap 6): value label (fs8 fw700) +
/// bar (radius 4/4/2/2, --drinking @ .85; fever day --fever @ .55) + weekday
/// label (fs8). Bar height ≈ 4px per visit (prototype: 8→32, 3→12).
class _MiniBars extends StatelessWidget {
  const _MiniBars({required this.bars});

  final List<DrinkingDayCount> bars;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < bars.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${bars[i].count}',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    // ≈4px per visit, capped at the 9-visit prototype max.
                    height: (bars[i].count * 4).clamp(0, 38).toDouble(),
                    decoration: BoxDecoration(
                      color: bars[i].isFeverDay
                          ? AppColors.fever.withValues(alpha: 0.55)
                          : AppColors.drinking.withValues(alpha: 0.85),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                        bottom: Radius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _dayLabel(l10n, bars[i].date, now),
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static String _dayLabel(
    AppLocalizations l10n,
    String wireDate,
    DateTime now,
  ) {
    final today = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    if (wireDate == today) return l10n.healthDrinkingDayToday;
    final parsed = DateTime.tryParse(wireDate);
    if (parsed == null) return wireDate.substring(5);
    // Dart weekday: 1=Mon..7=Sun.
    return switch (parsed.weekday) {
      1 => l10n.healthDrinkingDayMon,
      2 => l10n.healthDrinkingDayTue,
      3 => l10n.healthDrinkingDayWed,
      4 => l10n.healthDrinkingDayThu,
      5 => l10n.healthDrinkingDayFri,
      6 => l10n.healthDrinkingDaySat,
      7 => l10n.healthDrinkingDaySun,
      _ => wireDate.substring(5),
    };
  }
}

/// Dual-reference subtitle (spec 3c: peer avg from drinking-peer-comparison
/// + own baseline from rolling30dBaseline.avgPerDay). Handles:
/// - Premium 403 → locked overlay (screen-5 mini shape);
/// - INSUFFICIENT_PEERS → degraded copy (no error);
/// - loading / other peer errors → own-baseline half only;
/// - baseline null (no sample day yet) → peer half only.
class _PeerBaselineLine extends StatelessWidget {
  const _PeerBaselineLine({required this.peerAsync, required this.baseline});

  final AsyncValue<DrinkingPeerComparison> peerAsync;
  final double? baseline;

  @override
  Widget build(BuildContext context) {
    // A 403 from this endpoint is always the peer-comparison subscription
    // guard (DrinkingPeerAccessGuard) — map it to the locked overlay,
    // never to an error state.
    final locked = peerAsync.hasError && peerAsync.error is ForbiddenException;

    final subtitle = _buildSubtitle(context);
    if (subtitle == null && !locked) return const SizedBox.shrink();

    if (locked) {
      return SizedBox(
        height: 84,
        child: UpgradeOverlay(
          onUpgrade: () => context.go(AppRoute.subscription.path),
          child: const _PeerLockDim(),
        ),
      );
    }
    return Text(
      subtitle!,
      style: const TextStyle(
        fontSize: 11,
        height: 1.45,
        color: AppColors.textSecondary,
      ),
    );
  }

  String? _buildSubtitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String? peerHalf;
    final peer = peerAsync.value;
    if (peer != null) {
      if (peer.insufficientPeers) {
        peerHalf = l10n.healthDrinkingPeerInsufficient(peer.minSampleDays);
      } else if (peer.peerAvgPerDay != null) {
        final group = switch (peer.groupStage) {
          'LACTATING' => l10n.healthDrinkingPeerGroupLactating,
          'DRY' => l10n.healthDrinkingPeerGroupDry,
          _ => '',
        };
        peerHalf = l10n.healthDrinkingPeerBaseline(
          group,
          peer.peerAvgPerDay!.toStringAsFixed(1),
        );
      }
    }
    String? baselineHalf;
    if (baseline != null) {
      baselineHalf = l10n.healthDrinkingOwnBaseline(baseline!.toStringAsFixed(1));
    }
    if (peerHalf == null && baselineHalf == null) return null;
    if (peerHalf == null) return baselineHalf;
    if (baselineHalf == null) return peerHalf;
    return '$peerHalf · $baselineHalf';
  }
}

/// Dimmed content behind the card-level peer lock: chart-title + a row of
/// grey-green placeholder bars (--accent #8BA95A, prototype screen 5).
class _PeerLockDim extends StatelessWidget {
  const _PeerLockDim();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(
          '📊 ${l10n.healthDrinkingPeerCompareTitle}',
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

/// Fever context note: bg rgba(217,123,41,.08), r8, padding 7×8; 🌡️ 11px +
/// 9.5px --fever text. Rendered only when a fever day exists in the last
/// 7 bars.
///
/// Deviation from the frozen prototype sentence: the wire format
/// (drinking-summary dayCounts) has no per-day fever time range or
/// 38.9→40.2°C extremes, so the precise "10:20–16:40 处于发热期" range is
/// replaced by the fever coverage percent the endpoint does provide.
class _FeverContextNote extends StatelessWidget {
  const _FeverContextNote({required this.feverDay});

  final DrinkingDayCount feverDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateLabel = _shortDateLabel(l10n, feverDay.date);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.fever.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Text('🌡️', style: TextStyle(fontSize: 11, height: 1.3)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n.healthDrinkingFeverContext(
                dateLabel,
                feverDay.count,
                (feverDay.feverCoveredPercent ?? 0).round(),
              ),
              style: const TextStyle(
                fontSize: 9.5,
                height: 1.45,
                color: AppColors.fever,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "周五"/"Fri"-style short label for the fever day.
  static String _shortDateLabel(AppLocalizations l10n, String wireDate) {
    final parsed = DateTime.tryParse(wireDate);
    if (parsed == null) return wireDate;
    final day = switch (parsed.weekday) {
      1 => l10n.healthDrinkingDayMon,
      2 => l10n.healthDrinkingDayTue,
      3 => l10n.healthDrinkingDayWed,
      4 => l10n.healthDrinkingDayThu,
      5 => l10n.healthDrinkingDayFri,
      6 => l10n.healthDrinkingDaySat,
      7 => l10n.healthDrinkingDaySun,
      _ => wireDate.substring(5),
    };
    return l10n.healthDrinkingWeekdayPrefix + day;
  }
}
