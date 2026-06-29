import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/estrus/presentation/estrus_controller.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/device_info_line.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_controller.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/widgets/locked_overlay.dart';
import 'package:hkt_livestock_agentic/features/ai_anomaly/presentation/widgets/anomaly_score_card.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

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
   return Scaffold(
      appBar: AppBar(title: Text(l10n.estrusDetailTitle), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.commonLoadFailed}: $e')),
        data: (detail) => RefreshIndicator(
          onRefresh: () => ref.read(estrusDetailControllerProvider(livestockId).notifier).refresh(),
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
              if (detail.advice != null) ...[
                const SizedBox(height: 16),
                Card(color: AppColors.primarySoft, child: Padding(padding: const EdgeInsets.all(12), child: Text('💡 ${detail.advice}'))),
              ],
              if (hasHealthScore) ...[
                const SizedBox(height: 16),
                AnomalyScoreCard(livestockId: livestockId),
              ],
              const SizedBox(height: 16),
              _buildCapabilityNote(context, l10n),
              const SizedBox(height: 16),
              _buildDismissButton(context),
            ],
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
              Text('💕 ${l10n.estrusLockedTitle}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const SizedBox(height: 200, child: Center(child: Icon(Icons.favorite_outline, size: 48, color: AppColors.border))),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.info),
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
      icon: const Icon(Icons.check_circle_outline, size: 18, color: AppColors.textSecondary),
      label: Text(l10n.commonBack, style: const TextStyle(color: AppColors.textSecondary)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }

  Widget _buildMetricCards(AppLocalizations l10n, EstrusDetailData detail) {
    return Row(children: [
      _metricCard(l10n.metricScore, '${detail.score}', detail.score >= 70 ? AppColors.success : AppColors.warning),
      const SizedBox(width: 8),
      _metricCard(l10n.metricStepIncrease, '${detail.stepIncreasePercent ?? 0}%', AppColors.info),
      const SizedBox(width: 8),
      _metricCard(l10n.metricTempDelta, '${(detail.tempDelta ?? 0).toStringAsFixed(2)}°C', AppColors.textSecondary),
    ]);
  }

  Widget _metricCard(String label, String value, Color color) {
    return Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
    ]))));
  }

  Widget _buildChart(EstrusDetailData detail, AppLocalizations l10n) {
    final trend = detail.trend7d;
    if (trend.isEmpty) return const SizedBox.shrink();
    final spots = trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.score)).toList();

    return Card(
      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.estrusDetailChartTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(height: 180, child: LineChart(LineChartData(
          minY: 0, maxY: 100,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)))),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(spots: spots, isCurved: true, color: AppColors.estrus, barWidth: 2, dotData: const FlDotData(show: true)),
          ],
        ))),
      ])),
    );
  }
}
