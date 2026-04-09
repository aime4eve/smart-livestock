import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/dashboard/domain/dashboard_repository.dart';
import 'package:smart_livestock_demo/features/dashboard/presentation/dashboard_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_stat_tile.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardControllerProvider);
    return SingleChildScrollView(
      key: const Key('page-dashboard'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBody(
            context,
            data,
            onRetry: () {
              ref.read(dashboardControllerProvider.notifier).setViewState(
                    ViewState.normal,
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DashboardViewData data, {
    required VoidCallback onRetry,
  }) {
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
          title: '暂无看板数据',
          description: '演示空状态：可去地图或告警页查看围栏与告警动态。',
          icon: Icons.inbox_outlined,
        );
      case ViewState.error:
        return HighfiEmptyErrorState(
          title: '看板加载失败',
          description: data.message ?? '当前使用演示数据源，可稍后重试。',
          icon: Icons.wifi_tethering_error_rounded,
          actionLabel: '重试',
          onAction: onRetry,
        );
      case ViewState.forbidden:
        return HighfiEmptyErrorState(
          title: '暂无查看权限',
          description: data.message ?? '当前角色仅可查看授权范围内的看板信息。',
          icon: Icons.lock_outline_rounded,
        );
      case ViewState.offline:
        return HighfiEmptyErrorState(
          title: '当前为离线快照',
          description: data.message ?? '已展示最近一次同步的牧场概览数据。',
          icon: Icons.cloud_off_rounded,
        );
      case ViewState.normal:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DashboardFarmHeader(),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                const HighfiStatusChip(
                  label: 'Mock 数据已同步',
                  color: AppColors.info,
                  icon: Icons.cloud_done_outlined,
                ),
                HighfiStatusChip.fromViewState(
                  viewState: ViewState.normal,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final m in data.metrics)
                  SizedBox(
                    width: 160,
                    child: KeyedSubtree(
                      key: m.widgetKey == 'dashboard-metric-animal-total'
                          ? const Key('dashboard-metric-livestock')
                          : null,
                      child: HighfiStatTile(
                        key: Key(m.widgetKey),
                        title: m.title,
                        value: m.value,
                        caption: '今日牧场概览',
                        trend: '+1.8%',
                        onTap: () => context.go(
                          AppRoute.livestockDetail.path
                              .replaceFirst(':id', '001'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
    }
  }
}

class _DashboardFarmHeader extends StatelessWidget {
  const _DashboardFarmHeader();

  @override
  Widget build(BuildContext context) {
    return HighfiCard(
      key: const Key('dashboard-farm-header'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('阿尔卑斯北麓牧场', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '晴 18°C · 最近同步 2 分钟前',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
