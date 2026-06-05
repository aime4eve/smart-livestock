import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/stats/domain/stats_repository.dart';
import 'package:smart_livestock_demo/features/stats/presentation/stats_controller.dart';
import 'package:smart_livestock_demo/features/stats/presentation/widgets/trend_chart.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(statsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('统计分析')),
      body: asyncStats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text('加载失败', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('$e', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.read(statsControllerProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () => ref.read(statsControllerProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _SummaryCards(summary: stats.summary),
              const SizedBox(height: AppSpacing.lg),
              _HealthDistribution(distribution: stats.healthDistribution, total: stats.summary.totalLivestock),
              const SizedBox(height: AppSpacing.lg),
              TrendChart(
                title: '体温趋势 (7日)',
                trend: stats.temperatureTrend,
                color: Colors.orange,
                suffix: '°C',
              ),
              TrendChart(
                title: '健康率趋势 (7日)',
                trend: stats.healthRateTrend,
                color: AppColors.success,
                suffix: '%',
                minY: 0,
                maxY: 1.1,
              ),
              TrendChart(
                title: '告警趋势 (7日)',
                trend: stats.alertTrend,
                color: AppColors.danger,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary});
  final StatsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _StatChip(icon: Icons.pets, label: '牲畜', value: '${summary.totalLivestock}', color: AppColors.primary),
        _StatChip(icon: Icons.favorite, label: '健康率', value: '${(summary.healthyRate * 100).toStringAsFixed(1)}%', color: AppColors.success),
        _StatChip(icon: Icons.notifications_active, label: '告警', value: '${summary.alertCount}', color: AppColors.warning),
        _StatChip(icon: Icons.error, label: '严重', value: '${summary.criticalCount}', color: AppColors.danger),
        _StatChip(icon: Icons.thermostat, label: '均温', value: '${summary.avgTemperature.toStringAsFixed(1)}°C', color: Colors.orange),
        _StatChip(icon: Icons.speed, label: '蠕动', value: '${summary.avgMotility.toStringAsFixed(1)}', color: Colors.brown),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 4),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

class _HealthDistribution extends StatelessWidget {
  const _HealthDistribution({required this.distribution, required this.total});
  final Map<String, int> distribution;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('健康分布', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              _DistBar(label: '健康', count: distribution['healthy'] ?? 0, color: AppColors.success, total: total),
              const SizedBox(width: AppSpacing.sm),
              _DistBar(label: '关注', count: distribution['warning'] ?? 0, color: AppColors.warning, total: total),
              const SizedBox(width: AppSpacing.sm),
              _DistBar(label: '严重', count: distribution['critical'] ?? 0, color: AppColors.danger, total: total),
            ]),
          ],
        ),
      ),
    );
  }
}

class _DistBar extends StatelessWidget {
  const _DistBar({required this.label, required this.count, required this.color, required this.total});
  final String label;
  final int count;
  final Color color;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: total > 0 ? count / total : 0,
              child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text('$count ($pct%)', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
