import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/twin_overview/presentation/twin_overview_controller.dart';
import 'package:hkt_livestock_agentic/core/widgets/auto_refresh_listener.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class TwinOverviewPage extends ConsumerWidget {
  const TwinOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(twinOverviewControllerProvider);
    final theme = Theme.of(context);

    return AutoRefreshListener(
      interval: const Duration(seconds: 180),
      onTick: () => ref.read(twinOverviewControllerProvider.notifier).silentRefresh(),
      child: SingleChildScrollView(
      key: const Key('page-twin-overview'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.navTwin, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.twinRealtimeOverview, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          asyncData.when(
            data: (data) => _buildContent(context, ref, data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildError(context, ref, e.toString()),
         ),
       ],
     ),
   ),
   );
 }

 Widget _buildContent(
      BuildContext context, WidgetRef ref, HealthOverviewResponse data) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.stats != null) _buildStats(context, data.stats!),
        const SizedBox(height: AppSpacing.xl),
        if (data.sceneSummary != null) ...[
          Text(l10n.twinHealthScenarios, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
         _buildSceneCards(context, data.sceneSummary!),
       ],
       if (data.stats != null &&
           data.stats!.aiAnomalyCount > 0) ...[
         const SizedBox(height: AppSpacing.xl),
         _buildAiOverviewCard(context, l10n, data.stats!),
       ],
       if (data.pendingTasks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.twinPendingTasks, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _buildPendingTasks(context, data.pendingTasks),
        ],
      ],
    );
  }

  Widget _buildAiOverviewCard(
    BuildContext context,
    AppLocalizations l10n,
    TwinOverviewStats stats,
  ) {
    final avgColor = stats.avgAiAnomalyScore >= 0.7
        ? AppColors.danger
        : stats.avgAiAnomalyScore > 0.001
            ? AppColors.warning
            : AppColors.success;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, size: 20, color: AppColors.info),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.aiAnomalyOverview,
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.aiAnomalyAnomalyCount,
                          style: Theme.of(context).textTheme.bodySmall),
                      Text('${stats.aiAnomalyCount}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: avgColor)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.aiAnomalyAvgScore,
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(
                          '${(stats.avgAiAnomalyScore * 100).toStringAsFixed(1)}%',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: avgColor)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, TwinOverviewStats stats) {
    final items = [
      _StatItem(title: '牲畜总数', value: '${stats.totalLivestock}'),
      _StatItem(
          title: '健康率',
          value: '${(stats.healthyRate * 100).toStringAsFixed(1)}%'),
      _StatItem(title: '活跃告警', value: '${stats.alertCount}'),
      _StatItem(title: '严重异常', value: '${stats.criticalCount}'),
      _StatItem(
          title: '设备在线率',
          value: '${(stats.deviceOnlineRate * 100).toStringAsFixed(1)}%'),
    ];
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final m in items)
          _StatCard(key: Key('twin-stat-${m.title}'), title: m.title, value: m.value),
      ],
    );
  }

  Widget _buildSceneCards(BuildContext context, TwinSceneSummary summary) {
    final scenes = [
      _SceneItem(
        icon: Icons.thermostat,
        title: '发热预警',
        subtitle: '异常 ${summary.fever.abnormalCount} · 严重 ${summary.fever.criticalCount}',
        color: summary.fever.criticalCount > 0
            ? AppColors.danger
            : summary.fever.abnormalCount > 0
                ? AppColors.warning
                : Colors.orange,
        route: AppRoute.twinFever.path,
      ),
      _SceneItem(
        icon: Icons.grain,
        title: '消化管理',
        subtitle: '异常 ${summary.digestive.abnormalCount} · 观察 ${summary.digestive.watchCount}',
        color: summary.digestive.abnormalCount > 0
            ? AppColors.warning
            : Colors.brown,
        route: AppRoute.twinDigestive.path,
      ),
      _SceneItem(
        icon: Icons.favorite,
        title: '发情识别',
        subtitle: '高分 ${summary.estrus.highScoreCount}',
        color: summary.estrus.highScoreCount > 0 ? AppColors.warning : Colors.pink,
        route: AppRoute.twinEstrus.path,
      ),
      _SceneItem(
        icon: Icons.shield,
        title: '疫病防控',
        subtitle: '异常率 ${(summary.epidemic.abnormalRate * 100).toStringAsFixed(1)}%',
        color: summary.epidemic.abnormalRate > 0.1
            ? AppColors.danger
            : Colors.teal,
        route: AppRoute.twinEpidemic.path,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.4,
      children: [
        for (final s in scenes)
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.go(s.route),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(s.icon, color: s.color, size: 28),
                    const SizedBox(height: AppSpacing.sm),
                    Text(s.title, style: Theme.of(context).textTheme.titleSmall),
                    Text(s.subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPendingTasks(BuildContext context, List<TwinPendingTask> tasks) {
    return Column(
      children: [
        for (final task in tasks)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                task.severity == 'CRITICAL'
                    ? Icons.error
                    : task.severity == 'WARNING'
                        ? Icons.warning
                        : Icons.info,
                color: task.severity == 'CRITICAL'
                    ? AppColors.danger
                    : task.severity == 'WARNING'
                        ? AppColors.warning
                        : AppColors.info,
              ),
              title: Text(task.title),
              subtitle: Text(task.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: task.routePath.isNotEmpty
                  ? () => context.go(task.routePath)
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.commonLoadFailed, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () =>
                  ref.read(twinOverviewControllerProvider.notifier).refresh(),
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({super.key, required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                key: Key('${key}_value'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 4),
            Text(title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  const _StatItem({required this.title, required this.value});
  final String title;
  final String value;
}

class _SceneItem {
  const _SceneItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;
}
