import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/features/mine/presentation/mine_controller.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/widgets/subscription_status_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:go_router/go_router.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(mineControllerProvider);

    return Scaffold(
      body: SingleChildScrollView(
        key: const Key('page-owner-admin'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '后台管理',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '管理控制台 - 业务数据与订阅概览',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                // 返回个人中心按钮
                IconButton.filled(
                  key: const Key('admin-back-to-mine'),
                  onPressed: () {
                    final router = GoRouter.of(context);
                    if (router.canPop()) {
                      router.pop();
                    }
                    router.push(AppRoute.mine.path);
                  },
                  icon: const Icon(Icons.person),
                  tooltip: '返回个人中心',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // 订阅状态概览
            const SubscriptionStatusCard(),
            const SizedBox(height: AppSpacing.lg),
            
            // 业务管理功能
            _buildBusinessManagement(context),
            const SizedBox(height: AppSpacing.lg),
            
            // 高级管理功能
            _buildAdvancedManagement(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessManagement(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '业务管理',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),

        // 对账看板
        HighfiCard(
          child: ListTile(
            key: const Key('admin-revenue'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('对账看板'),
            subtitle: const Text('查看各周期分润对账数据'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.platformRevenue.path),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 订阅服务管理
        HighfiCard(
          child: ListTile(
            key: const Key('admin-subscriptions'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('订阅服务管理'),
            subtitle: const Text('管理订阅套餐和业务服务'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.platformSubscriptions.path),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        HighfiCard(
          child: ListTile(
            key: const Key('admin-analytics'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('用量分析'),
            subtitle: const Text('API 调用量统计与趋势分析'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.platformAnalytics.path),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedManagement(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '高级管理',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),

        // API授权管理
        HighfiCard(
          child: ListTile(
            key: const Key('admin-api-auth'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.api_outlined),
            title: const Text('API授权管理'),
            subtitle: const Text('管理API Key和第三方访问授权'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.platformApiAuth.path),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        HighfiCard(
          child: ListTile(
            key: const Key('admin-feature-gates'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.tune),
            title: const Text('功能门控'),
            subtitle: const Text('管理各等级功能配额'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.platformFeatureGates.path),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        HighfiCard(
          child: ListTile(
            key: const Key('admin-audit-log'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history),
            title: const Text('审计日志'),
            subtitle: const Text('查看系统操作记录'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.platformAuditLog.path),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        HighfiCard(
          child: ListTile(
            key: const Key('admin-tile-admin'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.map_outlined),
            title: const Text('瓦片管理'),
            subtitle: const Text('管理离线瓦片区域和任务'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.platformTileAdmin.path),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 牧工管理（后台视角）
        HighfiCard(
          child: ListTile(
            key: const Key('admin-workers'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.groups_2_outlined),
            title: const Text('牧工管理'),
            subtitle: const Text('管理牧场牧工和权限分配'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.workerManagement.path),
          ),
        ),
      ],
    );
  }
}
