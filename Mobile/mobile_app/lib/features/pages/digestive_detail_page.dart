import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/models/health_models.dart';
import 'package:smart_livestock_demo/features/digestive/presentation/digestive_controller.dart';
import 'package:smart_livestock_demo/features/ranch/presentation/widgets/device_info_line.dart';
import 'package:smart_livestock_demo/l10n/gen/app_localizations.dart';

class DigestiveDetailPage extends ConsumerWidget {
  const DigestiveDetailPage({super.key, required this.livestockId});
  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncDetail = ref.watch(digestiveDetailControllerProvider(livestockId));
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
              _buildStatusCards(detail),
              const SizedBox(height: 16),
              // Device info (subtle)
              DeviceInfoLine(deviceId: livestockId),
              const SizedBox(height: 8),
              _buildChart(detail, l10n),
              if (detail.advice != null) ...[
                const SizedBox(height: 16),
                Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('📋 ${detail.advice}'))),
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
              '系统能通知你消化异常，需线下排查确认原因',
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

  Widget _buildStatusCards(DigestiveDetailData detail) {
    return Row(children: [
      _statCard('当前频率', '${detail.recent24h.isEmpty ? detail.motilityBaseline.toStringAsFixed(1) : detail.recent24h.last.frequency.toStringAsFixed(1)}次/分', AppColors.danger),
      const SizedBox(width: 8),
      _statCard('基线频率', '${detail.motilityBaseline.toStringAsFixed(1)}次/分', AppColors.textSecondary),
      const SizedBox(width: 8),
      _statCard('状态', detail.status, detail.status == 'ABNORMAL' ? AppColors.danger : AppColors.warning),
    ]);
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
      Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35, getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}', style: const TextStyle(fontSize: 10)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(spots: spots, isCurved: true, color: AppColors.warning, barWidth: 2, dotData: FlDotData(show: false)),
            LineChartBarData(spots: [FlSpot(0, detail.motilityBaseline), FlSpot((readings.length - 1).toDouble(), detail.motilityBaseline)], color: AppColors.textSecondary.withOpacity(0.4), dashArray: [4, 4], barWidth: 1, dotData: FlDotData(show: false)),
          ],
        ))),
      ])),
    );
  }
}
