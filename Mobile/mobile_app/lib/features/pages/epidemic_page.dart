import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/epidemic/presentation/epidemic_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/subscription_controller.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/widgets/locked_overlay.dart';

class EpidemicPage extends ConsumerWidget {
  const EpidemicPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(epidemicControllerProvider);
    final notifier = ref.read(epidemicControllerProvider.notifier);
    final subStatus = ref.watch(subscriptionControllerProvider);

    return LockedOverlay(
      locked: !checkTierAccess(subStatus.tier, FeatureFlags.epidemicAlert),
      upgradeTier: '高级版',
      child: SingleChildScrollView(
      key: const Key('page-twin-epidemic'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HighfiCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '疫病防控',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '群体健康趋势监控，接触链路追踪。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildBody(context, data, notifier),
        ],
      ),
    ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    EpidemicViewData data,
    EpidemicController notifier,
  ) {
    switch (data.viewState) {
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.empty:
        return const HighfiEmptyErrorState(
          title: '暂无数据',
          description: '演示空状态',
          icon: Icons.inbox_outlined,
        );
      case ViewState.error:
        return HighfiEmptyErrorState(
          title: '加载失败',
          description: data.message ?? '',
          icon: Icons.wifi_tethering_error_rounded,
          actionLabel: '重试',
          onAction: () => notifier.setViewState(ViewState.normal),
        );
      case ViewState.forbidden:
        return HighfiEmptyErrorState(
          title: '无权限',
          description: data.message ?? '',
          icon: Icons.lock_outline_rounded,
        );
      case ViewState.offline:
        return HighfiEmptyErrorState(
          title: '离线',
          description: data.message ?? '',
          icon: Icons.cloud_off_rounded,
        );
      case ViewState.normal:
        final m = data.metrics!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: HighfiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '平均体温',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${m.avgTemperature.toStringAsFixed(1)}°C',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: HighfiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '异常率',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${m.abnormalRate}%',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: m.abnormalRate > 2
                                ? AppColors.danger
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: HighfiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '异常个体',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${m.abnormalCount}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: HighfiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '活动量指数',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          m.avgActivity.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            HighfiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.share_outlined, color: AppColors.info),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '接触链路追踪',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final c in data.contacts) _ContactTraceItem(trace: c),
                ],
              ),
            ),
          ],
        );
    }
  }
}

class _ContactTraceItem extends StatelessWidget {
  const _ContactTraceItem({required this.trace});

  final ContactTrace trace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.agriculture, size: 20, color: AppColors.danger),
          const SizedBox(width: 4),
          Text(
            '牛#${trace.fromId}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '牛#${trace.toId}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.warning,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${trace.proximity}m',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _formatTime(trace.lastContact),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime t) {
    return '${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} ${t.hour}:${t.minute.toString().padLeft(2, '0')}';
  }
}
