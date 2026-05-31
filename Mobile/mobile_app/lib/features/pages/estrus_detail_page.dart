import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/models/health_models.dart';
import 'package:smart_livestock_demo/features/estrus/presentation/estrus_controller.dart';

class EstrusDetailPage extends ConsumerWidget {
  const EstrusDetailPage({super.key, required this.livestockId});
  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(estrusDetailControllerProvider(livestockId));
    return Scaffold(
      appBar: AppBar(title: const Text('发情详情'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (detail) => RefreshIndicator(
          onRefresh: () => ref.read(estrusDetailControllerProvider(livestockId).notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildMetricCards(detail),
              const SizedBox(height: 16),
              _buildChart(detail),
              if (detail.advice != null) ...[
                const SizedBox(height: 16),
                Card(color: AppColors.primarySoft, child: Padding(padding: const EdgeInsets.all(12), child: Text('💡 ${detail.advice}'))),
              ],
            ],
          ),
        ),
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

  Widget _buildChart(EstrusDetailData detail) {
    final trend = detail.trend7d;
    if (trend.isEmpty) return const SizedBox.shrink();
    final spots = trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.score)).toList();

    return Card(
      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📈 7天评分趋势', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
