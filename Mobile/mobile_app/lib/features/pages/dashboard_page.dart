import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/models/user_role.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/dashboard/domain/dashboard_repository.dart';
import 'package:smart_livestock_demo/features/dashboard/presentation/dashboard_controller.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_stat_tile.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmState = ref.watch(farmSwitcherControllerProvider);
    final session = ref.watch(sessionControllerProvider);

    // Show empty farm guide for owners who have no farms
    if (farmState.farms.isEmpty && session.role == UserRole.owner) {
      return const _EmptyFarmGuide();
    }

    final asyncData = ref.watch(dashboardControllerProvider);

    return SingleChildScrollView(
      key: const Key('page-dashboard'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          asyncData.when(
            data: (data) => _buildContent(context, data),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('加载失败: $e'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(dashboardControllerProvider.notifier)
                        .refresh(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, DashboardViewData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _DashboardFarmHeader(),
        const SizedBox(height: AppSpacing.lg),
        if (data.metrics.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('暂无看板数据'),
            ),
          )
        else
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

class _DashboardFarmHeader extends ConsumerWidget {
  const _DashboardFarmHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmName = ref.watch(farmSwitcherControllerProvider).activeFarmName;
    return HighfiCard(
      key: const Key('dashboard-farm-header'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(farmName.isNotEmpty ? farmName : '牧场概览', style: Theme.of(context).textTheme.titleLarge),
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

class _EmptyFarmGuide extends StatelessWidget {
  const _EmptyFarmGuide();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(AppSpacing.xl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_business_outlined,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '您还没有牧场',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '创建您的第一个牧场，开始管理牲畜',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                key: const Key('create-first-farm-btn'),
                onPressed: () => context.go(AppRoute.farmCreation.path),
                child: const Text('创建第一个牧场'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
