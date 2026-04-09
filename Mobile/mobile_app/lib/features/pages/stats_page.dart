import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_chart_placeholder.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';
import 'package:smart_livestock_demo/features/stats/domain/stats_repository.dart';
import 'package:smart_livestock_demo/features/stats/presentation/stats_controller.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(statsControllerProvider);
    final controller = ref.read(statsControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('数据统计')),
      body: SingleChildScrollView(
        key: const Key('page-stats'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (data.viewState == ViewState.normal)
              Row(
                children: [
                  const Text('时间范围'),
                  const SizedBox(width: AppSpacing.md),
                  SegmentedButton<StatsTimeRange>(
                    key: const Key('stats-time-range'),
                    segments: const [
                      ButtonSegment(
                          value: StatsTimeRange.d7, label: Text('7天')),
                      ButtonSegment(
                          value: StatsTimeRange.d30, label: Text('30天')),
                    ],
                    selected: {data.timeRange},
                    onSelectionChanged: (sel) =>
                        controller.setTimeRange(sel.first),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            _buildBody(context, data),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, StatsViewData data) {
    switch (data.viewState) {
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.empty:
        return const HighfiEmptyErrorState(
          title: '暂无统计数据',
          description: '当前牧场暂无足够的历史数据生成统计。',
          icon: Icons.bar_chart,
        );
      case ViewState.error:
        return HighfiEmptyErrorState(
          title: '统计数据加载失败',
          description: data.message ?? '',
          icon: Icons.error_outline,
        );
      case ViewState.forbidden:
        return HighfiEmptyErrorState(
          title: '无查看权限',
          description: data.message ?? '',
          icon: Icons.lock_outline_rounded,
        );
      case ViewState.offline:
        return HighfiEmptyErrorState(
          title: '离线统计快照',
          description: data.message ?? '',
          icon: Icons.cloud_off_rounded,
        );
      case ViewState.normal:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HealthCard(health: data.healthSummary!),
            const SizedBox(height: AppSpacing.md),
            _AlertStatsCard(alert: data.alertSummary!),
            const SizedBox(height: AppSpacing.md),
            _DeviceStatsCard(device: data.deviceSummary!),
          ],
        );
    }
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.health});

  final StatsHealthSummary health;

  @override
  Widget build(BuildContext context) {
    final total =
        health.healthyCount + health.watchCount + health.abnormalCount;
    return HighfiCard(
      key: const Key('stats-health-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('健康趋势', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '牲畜总数 $total 头',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _HealthBar(
                label: '健康',
                count: health.healthyCount,
                total: total,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.md),
              _HealthBar(
                label: '关注',
                count: health.watchCount,
                total: total,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.md),
              _HealthBar(
                label: '异常',
                count: health.abnormalCount,
                total: total,
                color: AppColors.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthBar extends StatelessWidget {
  const _HealthBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? count / total : 0.0;
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertStatsCard extends StatelessWidget {
  const _AlertStatsCard({required this.alert});

  final StatsAlertSummary alert;

  @override
  Widget build(BuildContext context) {
    return HighfiCard(
      key: const Key('stats-alert-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('告警统计', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          HighfiChartPlaceholder(
            title: '每日告警数量',
            data: alert.dailyTrend,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('告警类型分布', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _AlertTypeCount(
                label: '越界',
                count: alert.fenceBreachCount,
                color: AppColors.danger,
                icon: Icons.fence,
              ),
              _AlertTypeCount(
                label: '低电',
                count: alert.batteryLowCount,
                color: AppColors.warning,
                icon: Icons.battery_alert_outlined,
              ),
              _AlertTypeCount(
                label: '失联',
                count: alert.signalLostCount,
                color: AppColors.info,
                icon: Icons.signal_wifi_connected_no_internet_4_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertTypeCount extends StatelessWidget {
  const _AlertTypeCount({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$label $count',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _DeviceStatsCard extends StatelessWidget {
  const _DeviceStatsCard({required this.device});

  final StatsDeviceSummary device;

  @override
  Widget build(BuildContext context) {
    return HighfiCard(
      key: const Key('stats-device-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('设备在线率', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              HighfiStatusChip(
                label: '设备 ${device.totalDevices}',
                color: AppColors.primary,
                icon: Icons.devices,
              ),
              HighfiStatusChip(
                label: '在线 ${device.onlineCount}',
                color: AppColors.success,
                icon: Icons.wifi,
              ),
              HighfiStatusChip(
                label: '在线率 ${device.weeklyOnlineRate.toStringAsFixed(1)}%',
                color: AppColors.info,
                icon: Icons.trending_up,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          HighfiChartPlaceholder(
            title: '本周在线率趋势',
            data: device.weeklyTrend,
          ),
        ],
      ),
    );
  }
}
