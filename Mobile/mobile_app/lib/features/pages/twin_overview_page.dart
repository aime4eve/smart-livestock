import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/dashboard/domain/dashboard_repository.dart';
import 'package:smart_livestock_demo/features/dashboard/presentation/dashboard_controller.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_controller.dart';

class TwinOverviewPage extends ConsumerWidget {
  const TwinOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmState = ref.watch(farmSwitcherControllerProvider);
    final asyncData = ref.watch(dashboardControllerProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      key: const Key('page-twin-overview'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('数智孪生', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            farmState.hasFarms
                ? '牧场实时概览'
                : '加载中...',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          asyncData.when(
            data: (data) => _buildStats(context, data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildError(context, ref, e.toString()),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('健康场景', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _buildSceneCards(context),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, DashboardViewData data) {
    if (data.metrics.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text('暂无看板数据'),
        ),
      );
    }
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final m in data.metrics)
          _StatCard(
            key: Key(m.widgetKey),
            title: m.title,
            value: m.value,
          ),
      ],
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => ref.read(dashboardControllerProvider.notifier).refresh(),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSceneCards(BuildContext context) {
    final scenes = [
      _SceneItem(
        icon: Icons.thermostat,
        title: '发热预警',
        subtitle: '体温异常监测',
        color: Colors.orange,
        route: AppRoute.twinFever.path,
      ),
      _SceneItem(
        icon: Icons.grain,
        title: '消化管理',
        subtitle: '瘤胃蠕动分析',
        color: Colors.brown,
        route: AppRoute.twinDigestive.path,
      ),
      _SceneItem(
        icon: Icons.favorite,
        title: '发情识别',
        subtitle: '行为评分与配种建议',
        color: Colors.pink,
        route: AppRoute.twinEstrus.path,
      ),
      _SceneItem(
        icon: Icons.shield,
        title: '疫病防控',
        subtitle: '群体健康监控',
        color: Colors.teal,
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
            Text(value, key: Key('${key}_value'), style: theme.textTheme.headlineMedium?.copyWith(
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
