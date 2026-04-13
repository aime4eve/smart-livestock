import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_stat_tile.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';
import 'package:smart_livestock_demo/features/pages/widgets/twin_scene_card.dart';
import 'package:smart_livestock_demo/features/twin_overview/presentation/twin_overview_controller.dart';

class TwinOverviewPage extends ConsumerWidget {
  const TwinOverviewPage({super.key});

  static String _commaInt(int n) {
    final s = n.abs().toString();
    final buf = StringBuffer();
    final len = s.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return n < 0 ? '-$buf' : buf.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(twinOverviewControllerProvider);
    final notifier = ref.read(twinOverviewControllerProvider.notifier);

    return SingleChildScrollView(
      key: const Key('page-twin'),
      padding: const EdgeInsets.all(16),
      child: _buildBody(context, data, notifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TwinOverviewViewData data,
    TwinOverviewController notifier,
  ) {
    switch (data.viewState) {
      case ViewState.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        );
      case ViewState.empty:
        return const HighfiEmptyErrorState(
          title: '暂无孪生数据',
          description: '演示空状态：可去地图或告警页查看。',
          icon: Icons.inbox_outlined,
        );
      case ViewState.error:
        return HighfiEmptyErrorState(
          title: '孪生数据加载失败',
          description: data.message ?? '当前使用演示数据源，可稍后重试。',
          icon: Icons.wifi_tethering_error_rounded,
          actionLabel: '重试',
          onAction: () => notifier.setViewState(ViewState.normal),
        );
      case ViewState.forbidden:
        return HighfiEmptyErrorState(
          title: '暂无查看权限',
          description: data.message ?? '当前角色仅可查看授权范围内的孪生信息。',
          icon: Icons.lock_outline_rounded,
        );
      case ViewState.offline:
        return HighfiEmptyErrorState(
          title: '当前为离线快照',
          description: data.message ?? '已展示最近一次同步的牧场概览数据。',
          icon: Icons.cloud_off_rounded,
        );
      case ViewState.normal:
        final stats = data.stats!;
        final scene = data.sceneSummary!;
        final alertColor = stats.criticalCount > 0
            ? AppColors.danger
            : (stats.alertCount > 0 ? AppColors.warning : null);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HighfiCard(
              key: const Key('twin-farm-header'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '阿尔卑斯北麓牧场',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '晴 18°C · 最近同步 2 分钟前',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      const HighfiStatusChip(
                        label: '数智孪生已同步',
                        color: AppColors.info,
                        icon: Icons.cloud_done,
                      ),
                      HighfiStatusChip.fromViewState(viewState: ViewState.normal),
                    ],
                  ),
                ],
              ),
            ),
            if (data.pastureHeadline != null && data.pastureDetail != null) ...[
              const SizedBox(height: AppSpacing.md),
              HighfiCard(
                key: const Key('twin-pasture-context'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.pastureHeadline!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      data.pastureDetail!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (data.pendingTasks.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              HighfiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '待处理事件',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (var i = 0; i < data.pendingTasks.length; i++) ...[
                      ListTile(
                        key: Key('twin-pending-task-${i + 1}'),
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          data.pendingTasks[i].severity == 'critical'
                              ? Icons.priority_high
                              : Icons.info_outline,
                          color: data.pendingTasks[i].severity == 'critical'
                              ? AppColors.danger
                              : AppColors.warning,
                        ),
                        title: Text(data.pendingTasks[i].title),
                        subtitle: Text(data.pendingTasks[i].subtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go(data.pendingTasks[i].routePath),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                HighfiStatTile(
                  key: const Key('twin-stat-livestock'),
                  title: '牲畜总数',
                  value: _commaInt(stats.totalLivestock),
                  trend: stats.livestockTrend,
                  caption: stats.livestockCaption,
                  onTap: () => context.go(AppRoute.twinEpidemic.path),
                ),
                HighfiStatTile(
                  title: '健康率',
                  value: '${stats.healthyRate.toStringAsFixed(1)}%',
                  trend: stats.healthTrend,
                  caption: stats.healthCaption,
                ),
                HighfiStatTile(
                  key: const Key('twin-metric-alert-pending'),
                  title: '预警数量',
                  value: '${stats.alertCount}',
                  caption: stats.alertCaption,
                  valueColor: alertColor,
                  onTap: () => context.go(AppRoute.alerts.path),
                ),
                HighfiStatTile(
                  title: '设备在线',
                  value: '${stats.deviceOnlineRate.toStringAsFixed(1)}%',
                  caption: stats.deviceCaption,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TwinSceneCard(
              key: const Key('twin-scene-fever'),
              icon: Icons.thermostat_outlined,
              title: '发热预警',
              summary:
                  '${scene.fever.abnormalCount} 头异常 · ${scene.fever.criticalCount} 紧急',
              alertLevel: scene.fever.criticalCount > 0
                  ? 'critical'
                  : (scene.fever.abnormalCount > 0 ? 'warning' : null),
              onTap: () => context.go(AppRoute.twinFever.path),
            ),
            const SizedBox(height: AppSpacing.md),
            TwinSceneCard(
              key: const Key('twin-scene-digestive'),
              icon: Icons.monitor_heart_outlined,
              title: '消化管理',
              summary:
                  '${scene.digestive.abnormalCount} 头蠕动异常 · ${scene.digestive.watchCount} 关注',
              alertLevel: scene.digestive.abnormalCount > 0
                  ? 'critical'
                  : null,
              onTap: () => context.go(AppRoute.twinDigestive.path),
            ),
            const SizedBox(height: AppSpacing.md),
            TwinSceneCard(
              key: const Key('twin-scene-estrus'),
              icon: Icons.favorite_outline,
              title: '发情识别',
              summary:
                  '${scene.estrus.highScoreCount} 头高分 · ${scene.estrus.breedingAdvice ? '建议配种' : '暂无需配种'}',
              alertLevel:
                  scene.estrus.highScoreCount > 0 ? 'warning' : null,
              onTap: () => context.go(AppRoute.twinEstrus.path),
            ),
            const SizedBox(height: AppSpacing.md),
            TwinSceneCard(
              key: const Key('twin-scene-epidemic'),
              icon: Icons.shield_outlined,
              title: '疫病防控',
              summary:
                  '${scene.epidemic.status == 'normal' ? '群体正常' : '需关注'} · 异常率 ${scene.epidemic.abnormalRate}%',
              alertLevel: null,
              onTap: () => context.go(AppRoute.twinEpidemic.path),
            ),
          ],
        );
    }
  }
}
