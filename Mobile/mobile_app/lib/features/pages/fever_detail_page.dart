import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/health_models.dart';
import 'package:smart_livestock_demo/features/fever_warning/presentation/fever_controller.dart';
import 'package:smart_livestock_demo/features/ranch/presentation/widgets/device_info_line.dart';

class FeverDetailPage extends ConsumerWidget {
  const FeverDetailPage({super.key, required this.livestockId});
  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(feverDetailControllerProvider(livestockId));
    return Scaffold(
      appBar: AppBar(title: const Text('体温详情'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (detail) => RefreshIndicator(
          onRefresh: () => ref.read(feverDetailControllerProvider(livestockId).notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatusCards(detail),
              const SizedBox(height: 16),
              // Device info (subtle)
              DeviceInfoLine(deviceId: livestockId),
              const SizedBox(height: 8),
              _buildChart(detail.recent72h, detail.baselineTemp),
              if (detail.conclusion != null) ...[
                const SizedBox(height: 16),
                Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('📋 ${detail.conclusion}'))),
              ],
              const SizedBox(height: 16),
              // Capability boundary note
              _buildCapabilityNote(context),
              const SizedBox(height: 16),
              // Dismiss alert button (owner/b2b_admin only — visibility controlled by parent)
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
              '系统能通知你体温异常，需线下排查确认原因',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.of(context).pop(),
      icon: Icon(Icons.check_circle_outline, size: 18, color: AppColors.textSecondary),
      label: Text('返回', style: TextStyle(color: AppColors.textSecondary)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.border),
      ),
    );
  }

  Widget _buildStatusCards(FeverDetailData detail) {
    final currentTemp = detail.recent72h.isEmpty
        ? detail.baselineTemp
        : detail.recent72h.last.temperature;
    return Row(children: [
      _statCard('当前温度', '${currentTemp.toStringAsFixed(1)}°C', AppColors.danger),
      const SizedBox(width: 8),
      _statCard('基线温度', '${detail.baselineTemp.toStringAsFixed(1)}°C', AppColors.textSecondary),
      const SizedBox(width: 8),
      _statCard('状态', detail.status, detail.status == 'CRITICAL' ? AppColors.danger : AppColors.warning),
    ]);
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
      Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    ]))));
  }

  Widget _buildChart(List<TemperatureRecord> readings, double baseline) {
    if (readings.isEmpty) return const SizedBox.shrink();
    final spots = readings.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.temperature)).toList();
    final minTemp = readings.map((r) => r.temperature).reduce((a, b) => a < b ? a : b) - 0.5;
    final maxTemp = readings.map((r) => r.temperature).reduce((a, b) => a > b ? a : b) + 0.5;

    return Card(
      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📈 72小时温度曲线', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
