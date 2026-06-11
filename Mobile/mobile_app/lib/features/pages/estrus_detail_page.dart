import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/models/health_models.dart';
import 'package:smart_livestock_demo/features/estrus/presentation/estrus_controller.dart';
import 'package:smart_livestock_demo/features/ranch/presentation/widgets/device_info_line.dart';
import 'package:smart_livestock_demo/l10n/gen/app_localizations.dart';

class EstrusDetailPage extends ConsumerWidget {
  const EstrusDetailPage({super.key, required this.livestockId});
  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncDetail = ref.watch(estrusDetailControllerProvider(livestockId));
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
              _buildMetricCards(detail),
              const SizedBox(height: 16),
              // Device info (subtle)
              DeviceInfoLine(deviceId: livestockId),
              const SizedBox(height: 8),
              _buildChart(detail, l10n),
              if (detail.advice != null) ...[
                const SizedBox(height: 16),
                Card(color: AppColors.primarySoft, child: Padding(padding: const EdgeInsets.all(12), child: Text('💡 ${detail.advice}'))),
              ],
              const SizedBox(height: 16),
              // Capability boundary note
              _buildCapabilityNote(context),
              const SizedBox(height: 16),
              _buildDismissButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapabilityNote(BuildContext context) {
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
              '系统能检测发情高分牲畜，建议人工确认',
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

  Widget _buildMetricCards(EstrusDetailData detail) {
    return Row(children: [
      _metricCard('评分', '${detail.score}', detail.score >= 70 ? AppColors.success : AppColors.warning),
      const SizedBox(width: 8),
      _metricCard('步数增幅', '${detail.stepIncreasePercent ?? 0}%', AppColors.info),
      const SizedBox(width: 8),
      _metricCard('温差', '${(detail.tempDelta ?? 0).toStringAsFixed(2)}°C', AppColors.textSecondary),
    ]);
  }

  Widget _metricCard(String label, String value, Color color) {
    return Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
      Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(spots: spots, isCurved: true, color: AppColors.accent, barWidth: 2, dotData: FlDotData(show: true)),
          ],
        ))),
      ])),
    );
  }
}
