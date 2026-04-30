import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_controller.dart';

class B2bDashboardPage extends ConsumerWidget {
  const B2bDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(b2bDashboardControllerProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('B端控制台', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),

          if (data.contractStatus != null)
            Card(
              child: ListTile(
                leading: Icon(
                  data.contractStatus == 'active'
                      ? Icons.verified
                      : Icons.warning,
                  color: data.contractStatus == 'active'
                      ? Colors.green
                      : Colors.orange,
                ),
                title: Text('合同状态: ${data.contractStatus}'),
                subtitle: data.contractExpiresAt != null
                    ? Text('到期: ${data.contractExpiresAt!.substring(0, 10)}')
                    : null,
              ),
            ),
          const SizedBox(height: AppSpacing.md),

          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _MetricCard(
                  title: '旗下牧场',
                  value: '${data.totalFarms}',
                  icon: Icons.agriculture),
              _MetricCard(
                  title: '总牲畜数',
                  value: '${data.totalLivestock}',
                  icon: Icons.pets),
              _MetricCard(
                  title: '总设备数',
                  value: '${data.totalDevices}',
                  icon: Icons.devices),
              _MetricCard(
                  title: '待处理告警',
                  value: '${data.pendingAlerts}',
                  icon: Icons.warning_amber),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('旗下牧场', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...data.farms.map((farm) => Card(
                child: ListTile(
                  key: Key('b2b-farm-${farm.id}'),
                  title: Text(farm.name),
                  subtitle:
                      Text('${farm.region} · 牲畜: ${farm.livestockCount}'),
                  trailing: Chip(
                    label: Text(farm.status),
                    backgroundColor: farm.status == 'active'
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
