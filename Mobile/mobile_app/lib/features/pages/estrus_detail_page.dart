import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/charts/chart_readout_layer.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/utils/app_time.dart';
import 'package:hkt_livestock_agentic/core/widgets/auto_refresh_listener.dart';
import 'package:hkt_livestock_agentic/core/widgets/data_freshness_indicator.dart';
import 'package:hkt_livestock_agentic/features/estrus/presentation/estrus_controller.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/device_info_line.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_controller.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/widgets/locked_overlay.dart';
import 'package:hkt_livestock_agentic/features/ai_anomaly/presentation/widgets/anomaly_score_card.dart';
import 'package:hkt_livestock_agentic/features/ai_anomaly/presentation/widgets/anomaly_history_chart.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Estrus score bands on the 0-50-70-100 scale (NIX-390 explanation card).
enum _EstrusBand { none, watch, act }

class EstrusDetailPage extends ConsumerWidget {
  const EstrusDetailPage({super.key, required this.livestockId});
  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncDetail = ref.watch(estrusDetailControllerProvider(livestockId));
    final subAsync = ref.watch(subscriptionControllerProvider);
    final tier = subAsync.value?.tier ?? SubscriptionTier.basic;
    final hasEstrusDetect = checkTierAccess(tier, FeatureFlags.estrusDetect);
    final hasHealthScore = checkTierAccess(tier, FeatureFlags.healthScore);
    final refreshedAt = ref.watch(dataRefreshedAtProvider(livestockId));
    return AutoRefreshListener(
      interval: const Duration(seconds: 30),
      onTick: () async {
        await ref
            .read(estrusDetailControllerProvider(livestockId).notifier)
            .silentRefresh();
        ref.read(dataRefreshedAtProvider(livestockId).notifier).mark();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.estrusDetailTitle),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          bottom: DataFreshnessIndicator(
            refreshedAt: refreshedAt,
            foregroundColor: Colors.white,
          ),
        ),
        body: asyncDetail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('${l10n.commonLoadFailed}: $e')),
          data: (detail) => RefreshIndicator(
            onRefresh: () => ref
                .read(estrusDetailControllerProvider(livestockId).notifier)
                .refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMetricCards(l10n, detail),
                const SizedBox(height: 16),
                DeviceInfoLine(deviceId: livestockId),
                const SizedBox(height: 8),
                // Subscription-gated: estrus charts (Premium+)
                if (hasEstrusDetect) ...[
                  _buildChart(detail, l10n),
                ] else
                  _buildLockedChart(context, l10n),
                // Score explanation (NIX-390 Task 3): every block below
                // degrades independently based on data availability; the
                // "how to read" help card is the only always-on part.
                ..._buildExplanationSection(detail, l10n),
                if (detail.advice != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: AppColors.primarySoft,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('💡 ${detail.advice}'),
                    ),
                  ),
                ],
                if (hasHealthScore) ...[
                  const SizedBox(height: 16),
                  AnomalyScoreCard(data: detail.aiAnomaly),
                  const SizedBox(height: 8),
                  AnomalyHistoryChart(livestockId: livestockId),
                ],
                const SizedBox(height: 16),
                _buildCapabilityNote(context, l10n),
                const SizedBox(height: 16),
                _buildDismissButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedChart(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: LockedOverlay(
        locked: true,
        upgradeTier: 'premium',
        onUpgrade: () => context.go(AppRoute.subscription.path),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💕 ${l10n.estrusLockedTitle}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(
                height: 200,
                child: Center(
                  child: Icon(
                    Icons.favorite_outline,
                    size: 48,
                    color: AppColors.border,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapabilityNote(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.estrusCapabilityNote,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(
        Icons.check_circle_outline,
        size: 18,
        color: AppColors.textSecondary,
      ),
      label: Text(
        l10n.commonBack,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }

  Widget _buildMetricCards(AppLocalizations l10n, EstrusDetailData detail) {
    return Row(
      children: [
        _metricCard(
          l10n.metricScore,
          '${detail.score}',
          detail.score >= 70 ? AppColors.success : AppColors.warning,
        ),
        const SizedBox(width: 8),
        _metricCard(
          l10n.metricStepIncrease,
          '${detail.stepIncreasePercent ?? 0}%',
          AppColors.info,
        ),
        const SizedBox(width: 8),
        _metricCard(
          l10n.metricTempDelta,
          '${(detail.tempDelta ?? 0).toStringAsFixed(2)}°C',
          AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(EstrusDetailData detail, AppLocalizations l10n) {
    final trend = detail.trend7d;
    if (trend.isEmpty) return const SizedBox.shrink();
    final spots = trend
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.score))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.estrusDetailChartTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.latestDataAt(formatMdhm(trend.last.timestamp)),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ChartReadoutLayer(
                timestamps: trend.map((point) => point.timestamp).toList(),
                formatValue: (value) => value.round().toString(),
                chartDataBuilder: (touchData) => LineChartData(
                  minY: 0,
                  maxY: 100,
                  lineTouchData: touchData,
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.estrus,
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Score explanation section (NIX-390 Task 3) ──────────────────────

  /// Whether the backend attached a component breakdown: only rows with a
  /// known featureVersion (LEGACY | NORMALIZED-V2) are explainable.
  bool _hasBreakdown(EstrusDetailData detail) =>
      detail.featureVersion != null &&
      (detail.weightActivity != null ||
          detail.weightTemperature != null ||
          detail.weightDistance != null);

  bool _hasBaseline(EstrusDetailData detail) =>
      detail.baselineUsed != null && detail.baselineSource != null;

  /// Data-driven explanation blocks + the always-on help card. Blocks that
  /// miss their data stay hidden; with no score row at all only the help
  /// card remains (spec h).
  List<Widget> _buildExplanationSection(
      EstrusDetailData detail, AppLocalizations l10n) {
    final hasBreakdown = _hasBreakdown(detail);
    final hasBaseline = _hasBaseline(detail);
    final hasRow = detail.timestamp != null;
    final hasCard = hasBreakdown || hasBaseline || hasRow;
    return [
      const SizedBox(height: 16),
      if (hasCard) ...[
        _buildExplanationCard(detail, l10n,
            hasBreakdown: hasBreakdown, hasBaseline: hasBaseline),
        const SizedBox(height: 16),
      ],
      _buildHelpCard(l10n),
      if (hasRow) ...[
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            l10n.estrusExplanationCalibration,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ];
  }

  Widget _buildExplanationCard(
    EstrusDetailData detail,
    AppLocalizations l10n, {
    required bool hasBreakdown,
    required bool hasBaseline,
  }) {
    final hasRow = detail.timestamp != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasBreakdown) ...[
              Text(
                l10n.estrusExplanationSectionTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _buildBreakdownRow(
                key: const Key('estrus-breakdown-activity'),
                label: l10n.estrusExplanationChannelActivity,
                score: detail.activityScore,
                weight: detail.weightActivity,
                // Activity is the primary channel: no participation flag,
                // only a zero weight can mute it.
                participated: null,
                color: AppColors.accent,
                l10n: l10n,
              ),
              _buildBreakdownRow(
                key: const Key('estrus-breakdown-temperature'),
                label: l10n.estrusExplanationChannelTemperature,
                score: detail.temperatureScore,
                weight: detail.weightTemperature,
                participated: detail.temperatureParticipated,
                color: AppColors.fever,
                l10n: l10n,
              ),
              _buildBreakdownRow(
                key: const Key('estrus-breakdown-distance'),
                label: l10n.estrusExplanationChannelDistance,
                score: detail.distanceScore,
                weight: detail.weightDistance,
                participated: detail.distanceParticipated,
                color: AppColors.info,
                l10n: l10n,
              ),
              if (detail.activityRatio != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.estrusExplanationActivityRatioSentence(
                      detail.activityRatio!.toStringAsFixed(1),
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
            if (hasBaseline) ...[
              if (hasBreakdown)
                const Divider(
                  height: 20,
                  thickness: 0.5,
                  color: AppColors.border,
                ),
              _buildBaselineLine(detail, l10n),
            ],
            if (hasRow) ...[
              if (hasBreakdown || hasBaseline)
                const Divider(
                  height: 20,
                  thickness: 0.5,
                  color: AppColors.border,
                ),
              _buildScoreScale(detail, l10n),
              const SizedBox(height: 8),
              Text(
                l10n.estrusExplanationLastAssessed(
                  formatYmdhm(detail.timestamp!),
                ),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// One channel row: name + component score (0-100) + actual weight in
  /// percent, above a contribution bar on a shared full-width scale (filled
  /// width = weight x score, so rows are mutually comparable). Channels
  /// that did not feed the weighted sum are grayed out with a badge instead
  /// of numbers.
  Widget _buildBreakdownRow({
    required Key key,
    required String label,
    required double? score,
    required double? weight,
    required bool? participated,
    required Color color,
    required AppLocalizations l10n,
  }) {
    final muted = participated == false || (weight ?? 0) == 0;
    final contribution = (!muted && score != null && weight != null)
        ? ((weight * score) / 100).clamp(0.0, 1.0)
        : 0.0;
    return Opacity(
      key: key,
      opacity: muted ? 0.45 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (muted) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l10n.estrusExplanationNotParticipated,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (!muted && score != null)
                  Text(
                    '${score.round()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                if (!muted && weight != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${(weight * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Container(
                height: 6,
                color: AppColors.surfaceMuted,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: contribution,
                  child: Container(color: color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Baseline provenance line: learned-per-animal (with compute date when
  /// available) or the default baseline.
  Widget _buildBaselineLine(EstrusDetailData detail, AppLocalizations l10n) {
    final value = detail.baselineUsed!.toStringAsFixed(1);
    final String text;
    if (detail.baselineSource == 'LEARNED') {
      final computedAt = detail.baselineComputedAt;
      text = computedAt != null
          ? l10n.estrusExplanationBaselineLearned(
              value, formatYmdhm(computedAt))
          : l10n.estrusExplanationBaselineLearnedNoDate(value);
    } else {
      text = l10n.estrusExplanationBaselineDefault(value);
    }
    return Row(
      children: [
        const Icon(
          Icons.device_thermostat,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  /// 0-50-70-100 band scale with a score badge pointer at the current score
  /// and the three band labels (no signs / keep watching / breed within 12h).
  /// The band the score currently falls in is highlighted as a pill so the
  /// reader never has to map pointer position to a band themselves
  /// (integration-test feedback 2026-11-10: the old thin strip with a tiny
  /// triangle pointer was illegible — the 0-50 segment used the near-white
  /// border color and read as blank space).
  Widget _buildScoreScale(EstrusDetailData detail, AppLocalizations l10n) {
    final score = detail.score.clamp(0, 100).toDouble();
    const badgeWidth = 32.0;
    final activeBand = score >= 70 ? _EstrusBand.act : score >= 50 ? _EstrusBand.watch : _EstrusBand.none;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.estrusExplanationScaleTitle,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            // Badge CENTER sits at the score fraction, clamped so the badge
            // never leaves the track (edge scores stay readable).
            final badgeLeft = ((score / 100) * trackWidth - badgeWidth / 2)
                .clamp(0.0, trackWidth - badgeWidth);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 34,
                  width: double.infinity,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 0,
                        left: badgeLeft,
                        width: badgeWidth,
                        child: Column(
                          children: [
                            Container(
                              key: const Key('estrus-scale-pointer'),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.textPrimary,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                score.round().toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 5,
                              color: AppColors.textPrimary,
                            ),
                          ],
                        ),
                      ),
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 12,
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                          child: SizedBox(
                            key: Key('estrus-scale-track'),
                            height: 12,
                            child: Row(
                              children: [
                                // SizedBox.expand is required: a childless
                                // ColoredBox is zero-sized, so the Row's
                                // cross extent collapses to 0 and NOTHING
                                // paints (the original 8px strip was invisible
                                // for exactly this reason, not just its pale
                                // color).
                                Expanded(
                                  flex: 50,
                                  child: ColoredBox(
                                    color: AppColors.scaleNone,
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                                Expanded(
                                  flex: 20,
                                  child: ColoredBox(
                                    color: AppColors.warning,
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                                Expanded(
                                  flex: 30,
                                  child: ColoredBox(
                                    color: AppColors.success,
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // Band tick numbers at their exact fractions (0/50/70/100).
                SizedBox(
                  width: double.infinity,
                  child: Stack(
                    children: [
                      _scaleTick('0', Alignment.centerLeft),
                      _scaleTick('50', Alignment.center),
                      _scaleTick('70', const Alignment(0.4, 0)),
                      _scaleTick('100', Alignment.centerRight),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 50,
                      child: _bandLabel(
                        l10n.estrusExplanationBandNone,
                        _EstrusBand.none,
                        activeBand,
                        Alignment.centerLeft,
                        const Key('estrus-scale-band-none'),
                      ),
                    ),
                    Expanded(
                      flex: 20,
                      child: _bandLabel(
                        l10n.estrusExplanationBandWatch,
                        _EstrusBand.watch,
                        activeBand,
                        Alignment.center,
                        const Key('estrus-scale-band-watch'),
                      ),
                    ),
                    Expanded(
                      flex: 30,
                      child: _bandLabel(
                        l10n.estrusExplanationBandAct,
                        _EstrusBand.act,
                        activeBand,
                        Alignment.centerRight,
                        const Key('estrus-scale-band-act'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// One band label: the ACTIVE band renders as a colored pill (soft
  /// background + strong bold text, plus the estrus-scale-band-active key);
  /// inactive bands stay as plain secondary small text.
  Widget _bandLabel(String text, _EstrusBand band, _EstrusBand active,
      Alignment alignment, Key key) {
    final textAlign = alignment == Alignment.centerRight
        ? TextAlign.right
        : alignment == Alignment.center
            ? TextAlign.center
            : TextAlign.left;
    if (band != active) {
      return Text(
        text,
        key: key,
        textAlign: textAlign,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      );
    }
    final (Color, Color) colors = switch (band) {
      _EstrusBand.none => (AppColors.textSecondary, AppColors.surfaceMuted),
      _EstrusBand.watch => (AppColors.warningStrong, AppColors.warningSoft),
      _EstrusBand.act => (AppColors.successStrong, AppColors.successSoft),
    };
    return Align(
      key: key,
      alignment: alignment,
      child: Container(
        key: const Key('estrus-scale-band-active'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: colors.$2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: colors.$1,
          ),
        ),
      ),
    );
  }

  Widget _scaleTick(String label, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ),
    );
  }

  /// Always-on collapsible "how to read" help: what each factor measures,
  /// the self-baseline comparison rule, and the band semantics.
  Widget _buildHelpCard(AppLocalizations l10n) {
    const bodyStyle = TextStyle(
      fontSize: 12,
      height: 1.5,
      color: AppColors.textPrimary,
    );
    return Card(
      child: ExpansionTile(
        key: const Key('estrus-explanation-help'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Text(
          l10n.estrusExplanationHelpTitle,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        children: [
          Text(l10n.estrusExplanationHelpFactors, style: bodyStyle),
          const SizedBox(height: 8),
          Text(l10n.estrusExplanationHelpBaseline, style: bodyStyle),
          const SizedBox(height: 8),
          Text(l10n.estrusExplanationHelpBands, style: bodyStyle),
        ],
      ),
    );
  }
}
