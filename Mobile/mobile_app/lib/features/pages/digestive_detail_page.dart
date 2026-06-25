import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/digestive/presentation/digestive_controller.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/device_info_line.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_controller.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/widgets/locked_overlay.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class DigestiveDetailPage extends ConsumerWidget {
  const DigestiveDetailPage({super.key, required this.livestockId});
  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncDetail = ref.watch(digestiveDetailControllerProvider(livestockId));
    final subAsync = ref.watch(subscriptionControllerProvider);
    final tier = subAsync.value?.tier ?? SubscriptionTier.basic;
    final hasHealthScore = checkTierAccess(tier, FeatureFlags.healthScore);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.digestiveDetailTitle), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.commonLoadFailed}: $e')),
        data: (detail) => RefreshIndicator(
          onRefresh: () => ref.read(digestiveDetailControllerProvider(livestockId).notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatusCards(detail, l10n),
              const SizedBox(height: 16),
              DeviceInfoLine(deviceId: livestockId),
              const SizedBox(height: 8),
              _buildChart(detail, l10n),
              const SizedBox(height: 16),
              // Subscription-gated: intensity heatmap (Standard+)
              if (hasHealthScore)
                _buildHeatmapSection(ref, l10n)
              else
                _buildLockedChart(context, l10n, l10n.digestiveHeatmapTitle, 'Standard'),
              if (detail.advice != null) ...[
                const SizedBox(height: 16),
                Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('📋 ${detail.advice}'))),
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

  Widget _buildLockedChart(BuildContext context, AppLocalizations l10n, String chartTitle, String minTier) {
    return Card(
      child: LockedOverlay(
        locked: true,
        upgradeTier: minTier.toLowerCase(),
        onUpgrade: () => context.go(AppRoute.subscription.path),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(chartTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const SizedBox(height: 120, child: Center(child: Icon(Icons.grid_on, size: 48, color: AppColors.border))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmapSection(WidgetRef ref, AppLocalizations l10n) {
    final asyncHeatmap = ref.watch(digestiveHeatmapProvider(livestockId));
    return asyncHeatmap.when(
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()))),
      error: (e, _) => const SizedBox.shrink(),
      data: (cells) {
        if (cells.isEmpty) return const SizedBox.shrink();
        return _buildHeatmapChart(cells, l10n);
      },
    );
  }

  Widget _buildHeatmapChart(List<IntensityCell> cells, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🔥 ${l10n.digestiveHeatmapTitle}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Standard+', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark))),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: Row(
                children: [
                  Expanded(
                    child: GridView.builder(
                      scrollDirection: Axis.horizontal,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 1,
                        mainAxisSpacing: 1,
                        childAspectRatio: 0.3,
                      ),
                      itemCount: cells.length,
                      itemBuilder: (ctx, i) {
                        final cell = cells[i];
                        final intensity = cell.intensity;
                        final isAbnormal = cell.abnormal;
                        return Tooltip(
                          message: '${cell.hour}:00 · ${intensity.toStringAsFixed(1)}',
                          child: Container(
                            decoration: BoxDecoration(
                              color: isAbnormal
                                  ? AppColors.danger.withOpacity(0.3 + (intensity / 100).clamp(0, 0.7))
                                  : AppColors.success.withOpacity(0.3 + (intensity / 100).clamp(0, 0.7)),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('00:00', style: TextStyle(fontSize: 8, color: AppColors.textSecondary)),
                Text('06:00', style: TextStyle(fontSize: 8, color: AppColors.textSecondary)),
                Text('12:00', style: TextStyle(fontSize: 8, color: AppColors.textSecondary)),
                Text('18:00', style: TextStyle(fontSize: 8, color: AppColors.textSecondary)),
                Text('24:00', style: TextStyle(fontSize: 8, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 4),
            Text(l10n.digestiveHeatmapSubtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
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
              l10n.digestiveCapabilityNote,
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

  Widget _buildStatusCards(DigestiveDetailData detail, AppLocalizations l10n) {
    final unit = l10n.digestiveFreqUnit;
    return Row(children: [
      _statCard(l10n.digestiveCurrentFreq, '${detail.recent24h.isEmpty ? detail.motilityBaseline.toStringAsFixed(1) : detail.recent24h.last.frequency.toStringAsFixed(1)}$unit', AppColors.danger),
      const SizedBox(width: 8),
      _statCard(l10n.digestiveBaselineFreq, '${detail.motilityBaseline.toStringAsFixed(1)}$unit', AppColors.textSecondary),
      const SizedBox(width: 8),
      _statCard(l10n.digestiveStatus, detail.status, detail.status == 'ABNORMAL' ? AppColors.danger : AppColors.warning),
    ]);
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
    ]))));
  }

  Widget _buildChart(DigestiveDetailData detail, AppLocalizations l10n) {
    final readings = detail.recent24h;
    if (readings.isEmpty) return const SizedBox.shrink();
    final spots = readings.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.frequency)).toList();

    return Card(
      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.digestiveDetailChartTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(height: 180, child: LineChart(LineChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 10)))),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(spots: spots, isCurved: true, color: AppColors.danger, barWidth: 2, dotData: const FlDotData(show: false)),
          ],
        ))),
      ])),
    );
  }
}
