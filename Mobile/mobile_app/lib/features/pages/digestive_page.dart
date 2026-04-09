import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/digestive/presentation/digestive_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';

class DigestivePage extends ConsumerWidget {
  const DigestivePage({super.key});

  static bool _matchFilter(DigestiveHealth d, String? f) {
    if (f == null) return true;
    if (f == 'abnormal') return d.status != 'normal';
    if (f == 'watch') return d.status == 'warning';
    return true;
  }

  static String _motilityLabel(String status) {
    switch (status) {
      case 'critical':
        return '蠕动停止';
      case 'warning':
        return '蠕动下降';
      default:
        return '正常';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(digestiveControllerProvider);
    final notifier = ref.read(digestiveControllerProvider.notifier);
    final data = state.viewData;
    final filtered =
        data.items.where((e) => _matchFilter(e, state.filter)).toList();

    return SingleChildScrollView(
      key: const Key('page-twin-digestive'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HighfiCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '消化管理',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '瘤胃蠕动频率监测，消化系统健康预警。',
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
    DigestivePageState state,
    DigestiveController notifier,
    DigestiveViewData data,
    List<DigestiveHealth> filtered,
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
                  label: const Text('全部'),
                  selected: state.filter == null,
                  onSelected: (_) => notifier.setFilter(null),
                ),
                ChoiceChip(
                  label: const Text('异常'),
                  selected: state.filter == 'abnormal',
                  onSelected: (_) => notifier.setFilter('abnormal'),
                ),
                ChoiceChip(
                  label: const Text('关注'),
                  selected: state.filter == 'watch',
                  onSelected: (_) => notifier.setFilter('watch'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final item in filtered) ...[
              _DigestiveListItem(
                key: Key('digestive-item-${item.livestockId}'),
                item: item,
                motilityLabel: _motilityLabel(item.status),
                onTap: () => context.go(
                  AppRoute.twinDigestiveDetail.path.replaceFirst(
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

class _DigestiveListItem extends StatelessWidget {
  const _DigestiveListItem({
    super.key,
    required this.item,
    required this.motilityLabel,
    required this.onTap,
  });

  final DigestiveHealth item;
  final String motilityLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    switch (item.status) {
      case 'critical':
        dotColor = AppColors.danger;
        break;
      case 'warning':
        dotColor = AppColors.warning;
        break;
      default:
        dotColor = AppColors.success;
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
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
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
                            motilityLabel,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.advice ?? '—',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          Text(
                            '${item.currentFrequency.toStringAsFixed(1)}次/分',
                            style: Theme.of(context).textTheme.labelSmall,
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
