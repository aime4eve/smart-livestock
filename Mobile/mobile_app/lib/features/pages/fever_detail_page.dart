import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/fever_warning/presentation/fever_controller.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/device_info_line.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_controller.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/widgets/locked_overlay.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class FeverDetailPage extends ConsumerWidget {
  const FeverDetailPage({super.key, required this.livestockId});
  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncDetail = ref.watch(feverDetailControllerProvider(livestockId));
    final subAsync = ref.watch(subscriptionControllerProvider);
    final tier = subAsync.value?.tier ?? SubscriptionTier.basic;
    final hasHealthScore = checkTierAccess(tier, FeatureFlags.healthScore);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.feverDetailTitle), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.commonLoadFailed}: $e')),
        data: (detail) => RefreshIndicator(
          onRefresh: () => ref.read(feverDetailControllerProvider(livestockId).notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatusCards(detail, l10n),
              const SizedBox(height: 16),
              DeviceInfoLine(deviceId: livestockId),
              const SizedBox(height: 8),
              _buildChart(detail.recent72h, detail.baselineTemp, l10n),
              const SizedBox(height: 16),
              // Subscription-gated: fever duration chart (Standard+)
              if (hasHealthScore)
                _buildFeverDurationSection(ref, l10n)
              else
                _buildLockedChart(context, l10n, l10n.feverDurationChartTitle, 'Standard'),
              if (detail.conclusion != null) ...[
                const SizedBox(height: 16),
                Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('📋 ${detail.conclusion}'))),
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
              SizedBox(height: 180, child: const Center(child: Icon(Icons.bar_chart, size: 48, color: AppColors.border))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeverDurationSection(WidgetRef ref, AppLocalizations l10n) {
    final asyncDuration = ref.watch(feverDurationProvider(livestockId));
    return asyncDuration.when(
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()))),
      error: (e, _) => const SizedBox.shrink(),
      data: (hours) {
        if (hours.isEmpty) return const SizedBox.shrink();
        return _buildDurationChart(hours, l10n);
      },
    );
  }

  Widget _buildDurationChart(List<DailyFeverHour> hours, AppLocalizations l10n) {
    final spots = hours.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.hours)).toList();
    final maxHours = hours.map((h) => h.hours).reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('📈 ${l10n.feverDurationChartTitle}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Standard+', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark))),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: BarChart(BarChartData(
                maxY: (maxHours > 0 ? maxHours : 1) * 1.2,
                barGroups: spots.map((s) => BarChartGroupData(x: s.x.toInt(), barRods: [
                  BarChartRodData(toY: s.y, color: s.y > 6 ? AppColors.danger : AppColors.warning, width: 20, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                ])).toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}h', style: const TextStyle(fontSize: 10)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= hours.length) return const Text('');
                    return Text(hours[idx].date.substring(5), style: const TextStyle(fontSize: 9));
                  })),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
              )),
            ),
            const SizedBox(height: 4),
            Text(l10n.feverDurationChartSubtitle, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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
          Icon(Icons.info_outline, size: 16, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.feverCapabilityNote,
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
      icon: Icon(Icons.check_circle_outline, size: 18, color: AppColors.textSecondary),
      label: Text(l10n.commonBack, style: TextStyle(color: AppColors.textSecondary)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.border),
      ),
    );
  }

  Widget _buildStatusCards(FeverDetailData detail, AppLocalizations l10n) {
   final currentTemp = detail.recent72h.isEmpty
       ? detail.baselineTemp
       : detail.recent72h.last.temperature;
   return Row(children: [
      _statCard(l10n.feverCurrentTemp, '${currentTemp.toStringAsFixed(1)}°C', AppColors.danger),
     const SizedBox(width: 8),
      _statCard(l10n.feverBaselineTemp, '${detail.baselineTemp.toStringAsFixed(1)}°C', AppColors.textSecondary),
     const SizedBox(width: 8),
      _statCard(l10n.feverStatus, detail.status, detail.status == 'CRITICAL' ? AppColors.danger : AppColors.warning),
    ]);
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
      Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    ]))));
  }

  Widget _buildChart(List<TemperatureRecord> readings, double baseline, AppLocalizations l10n) {
    if (readings.isEmpty) return const SizedBox.shrink();
    final spots = readings.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.temperature)).toList();
    final minTemp = readings.map((r) => r.temperature).reduce((a, b) => a < b ? a : b) - 0.5;
    final maxTemp = readings.map((r) => r.temperature).reduce((a, b) => a > b ? a : b) + 0.5;

    return Card(
      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.feverDetailChartTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(height: 180, child: LineChart(LineChartData(
          minY: minTemp,
          maxY: maxTemp,
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}°', style: const TextStyle(fontSize: 10)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(spots: spots, isCurved: true, color: AppColors.danger, barWidth: 2, dotData: FlDotData(show: false)),
            LineChartBarData(spots: [FlSpot(0, baseline), FlSpot((readings.length - 1).toDouble(), baseline)], color: AppColors.textSecondary.withOpacity(0.4), dashArray: [4, 4], barWidth: 1, dotData: FlDotData(show: false)),
          ],
        ))),
      ])),
    );
  }
}
