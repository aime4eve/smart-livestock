import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/estrus/presentation/estrus_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';

class EstrusPage extends ConsumerWidget {
  const EstrusPage({super.key});

  static List<EstrusScore> _applyFilter(List<EstrusScore> items, String? f) {
    if (f == 'high') {
      return items.where((e) => e.score >= 70).toList();
    }
    final sorted = List<EstrusScore>.from(items);
    sorted.sort((a, b) => b.score.compareTo(a.score));
    return sorted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(estrusControllerProvider);
    final notifier = ref.read(estrusControllerProvider.notifier);
    final data = state.viewData;
    final filtered = _applyFilter(data.items, state.filter);

    return SingleChildScrollView(
      key: const Key('page-twin-estrus'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HighfiCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '发情识别',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '多传感器融合评分，精准配种时机提醒。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildContent(context, state, notifier, data, filtered),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    EstrusPageState state,
    EstrusController notifier,
    EstrusViewData data,
    List<EstrusScore> filtered,
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: const Text('高分优先'),
                  selected: state.filter == 'high',
                  onSelected: (_) => notifier.setFilter('high'),
                ),
                ChoiceChip(
                  label: const Text('全部'),
                  selected: state.filter == null,
                  onSelected: (_) => notifier.setFilter(null),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final item in filtered) ...[
              _EstrusListItem(
                key: Key('estrus-item-${item.livestockId}'),
                item: item,
                onTap: () => context.push(
                  AppRoute.twinEstrusDetail.path.replaceFirst(
                    ':livestockId',
                    item.livestockId,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
    }
  }
}

class _EstrusListItem extends StatelessWidget {
  const _EstrusListItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  final EstrusScore item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color scoreColor;
    if (item.score >= 80) {
      scoreColor = AppColors.danger;
    } else if (item.score >= 50) {
      scoreColor = AppColors.warning;
    } else {
      scoreColor = AppColors.textSecondary;
    }
    return HighfiCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (item.score >= 80 ? AppColors.danger : AppColors.warning)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      '${item.score}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scoreColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '牛#${item.livestockId}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const Spacer(),
                          Text(
                            '评分 ${item.score}/100',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '步数+${item.stepIncreasePercent}%',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              item.advice ?? '',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.warning),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
