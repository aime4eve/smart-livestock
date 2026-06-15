import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/features/mine/presentation/mine_controller.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/widgets/subscription_status_card.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
                      l10n.adminTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.adminSubtitle,
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.mineBusinessManagement,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),

        // Revenue Board
        HighfiCard(
          child: ListTile(
            key: const Key('admin-revenue'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: Text(l10n.mineRevenueBoardTitle),
            subtitle: Text(l10n.mineRevenueBoardDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.platformRevenue.path),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Subscription Service Management
        HighfiCard(
          child: ListTile(
            key: const Key('admin-subscriptions'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.workspace_premium_outlined),
            title: Text(l10n.mineSubscriptionServiceTitle),
            subtitle: Text(l10n.mineSubscriptionServiceDesc),
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
            title: Text(l10n.adminAnalytics),
            subtitle: Text(l10n.adminAnalyticsDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.platformAnalytics.path),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedManagement(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.mineAdvancedManagement,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),

        // API Authorization
        HighfiCard(
          child: ListTile(
            key: const Key('admin-api-auth'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.api_outlined),
            title: Text(l10n.mineApiAuthTitle),
            subtitle: Text(l10n.mineApiAuthManagementDesc),
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
            title: Text(l10n.adminFeatureGates),
            subtitle: Text(l10n.adminFeatureGatesDesc),
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
            title: Text(l10n.adminAuditLog),
            subtitle: Text(l10n.adminAuditLogDesc),
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
            title: Text(l10n.adminTileManagement),
            subtitle: Text(l10n.adminTileManagementDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.platformTileAdmin.path),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Worker Management (admin view)
        HighfiCard(
          child: ListTile(
            key: const Key('admin-workers'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.groups_2_outlined),
            title: Text(l10n.mineWorkerTitle),
            subtitle: Text(l10n.mineWorkerManagementDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.workerManagement.path),
          ),
        ),
      ],
    );
  }
}
