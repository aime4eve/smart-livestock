import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/fever_warning/presentation/fever_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';

class FeverWarningPage extends ConsumerWidget {
  const FeverWarningPage({super.key});

  static bool _matchFilter(TemperatureBaseline b, String? f) {
    if (f == null) return true;
    if (f == 'abnormal') return b.status != 'normal';
    if (f == 'critical') return b.status == 'critical';
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feverControllerProvider);
    final notifier = ref.read(feverControllerProvider.notifier);
    final data = state.viewData;
    final filtered = data.items
        .where((e) => _matchFilter(e, state.filter))
        .toList();

    return SingleChildScrollView(
      key: const Key('page-twin-fever'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HighfiCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '发热预警',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '瘤胃温度基线偏离检测，实时监控个体体温异常。',
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
    FeverPageState state,
    FeverController notifier,
    FeverViewData data,
    List<TemperatureBaseline> filtered,
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
                  key: const Key('fever-filter-all'),
                  label: const Text('全部'),
                  selected: state.filter == null,
                  onSelected: (_) => notifier.setFilter(null),
                ),
                ChoiceChip(
                  key: const Key('fever-filter-abnormal'),
                  label: const Text('异常'),
                  selected: state.filter == 'abnormal',
                  onSelected: (_) => notifier.setFilter('abnormal'),
                ),
                ChoiceChip(
                  key: const Key('fever-filter-critical'),
                  label: const Text('紧急'),
                  selected: state.filter == 'critical',
                  onSelected: (_) => notifier.setFilter('critical'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final item in filtered) ...[
              _FeverListItem(
                key: Key('fever-item-${item.livestockId}'),
                item: item,
                onTap: () => context.go(
                  AppRoute.twinFeverDetail.path.replaceFirst(
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

class _FeverListItem extends StatelessWidget {
  const _FeverListItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  final TemperatureBaseline item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color tempColor;
    switch (item.status) {
      case 'critical':
        tempColor = AppColors.danger;
        break;
      case 'warning':
        tempColor = AppColors.warning;
        break;
      default:
        tempColor = AppColors.textPrimary;
    }
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
              crossAxisAlignment: CrossAxisAlignment.center,
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
                            '${item.currentTemp.toStringAsFixed(1)}°C',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: tempColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.conclusion ?? '—',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          Text(
                            '↑${item.delta.toStringAsFixed(1)}°C',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.warning),
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
