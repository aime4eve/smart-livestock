import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/admin/domain/admin_repository.dart';
import 'package:smart_livestock_demo/features/admin/presentation/admin_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(adminOverviewControllerProvider);
    final tenantsAsync = ref.watch(tenantListControllerProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: '概览'),
              Tab(text: '租户管理'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _OverviewTab(overviewAsync: overviewAsync),
                _TenantTab(tenantsAsync: tenantsAsync),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.overviewAsync});

  final AsyncValue<AdminOverviewData> overviewAsync;

  @override
  Widget build(BuildContext context) {
    return overviewAsync.when(
      data: (data) => SingleChildScrollView(
        key: const Key('admin-overview'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('管理后台概览', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: HighfiCard(
                    key: const Key('stat-tenants'),
                    child: Column(
                      children: [
                        Text('${data.tenantCount}', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: AppSpacing.xs),
                        const Text('租户'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: HighfiCard(
                    key: const Key('stat-users'),
                    child: Column(
                      children: [
                        Text('${data.userCount}', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: AppSpacing.xs),
                        const Text('用户'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: HighfiCard(
                    key: const Key('stat-farms'),
                    child: Column(
                      children: [
                        Text('${data.farmCount}', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: AppSpacing.xs),
                        const Text('牧场'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }
}

class _TenantTab extends ConsumerWidget {
  const _TenantTab({required this.tenantsAsync});

  final AsyncValue<AdminListResult<TenantSummary>> tenantsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return tenantsAsync.when(
      data: (data) => SingleChildScrollView(
        key: const Key('admin-tenants'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('租户列表 (${data.total})', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  key: const Key('tenant-refresh'),
                  onPressed: () => ref.read(tenantListControllerProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (data.isEmpty)
              const SizedBox(height: 200, child: Center(child: Text('暂无租户')))
            else
              ...data.items.map((tenant) => _TenantCard(tenant: tenant)),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }
}

class _TenantCard extends ConsumerWidget {
  const _TenantCard({required this.tenant});

  final TenantSummary tenant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: HighfiCard(
        key: Key('tenant-${tenant.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tenant.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(
                  tenant.status == 'active' ? Icons.check_circle : Icons.cancel,
                  color: tenant.status == 'active' ? AppColors.success : AppColors.danger,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (tenant.contactName != null)
              Text('联系人: ${tenant.contactName}'),
            if (tenant.phase != null)
              Text('阶段: ${tenant.phase}'),
            Text('牧场: ${tenant.farmCount} · 用户: ${tenant.userCount}'),
          ],
        ),
      ),
    );
  }
}
