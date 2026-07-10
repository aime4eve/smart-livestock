import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/domain/admin_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/presentation/admin_controller.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';

class TenantListPage extends ConsumerWidget {
  const TenantListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTenants = ref.watch(tenantListControllerProvider);

    return asyncTenants.when(
      data: (data) => _TenantListContent(items: data.items, total: data.total),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('加载失败: $e'),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () =>
                  ref.read(tenantListControllerProvider.notifier).refresh(),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TenantListContent extends ConsumerWidget {
  const _TenantListContent({required this.items, required this.total});
  final List<TenantSummary> items;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      key: const Key('page-tenant-list'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('租户列表 ($total)', style: theme.textTheme.titleLarge),
              IconButton(
                key: const Key('tenant-list-refresh'),
                onPressed: () =>
                    ref.read(tenantListControllerProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (items.isEmpty)
            const SizedBox(
              height: 200,
              child: Center(child: Text('暂无租户')),
            )
          else
            ...items.map((tenant) => _TenantCard(tenant: tenant)),
        ],
      ),
    );
  }
}

class _TenantCard extends StatelessWidget {
  const _TenantCard({required this.tenant});
  final TenantSummary tenant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: HighfiCard(
        key: Key('tenant-${tenant.id}'),
        child: InkWell(
          key: Key('tenant-navigate-${tenant.id}'),
          onTap: () => context.go('/ops/admin/${tenant.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(tenant.name,
                                style: Theme.of(context).textTheme.titleSmall),
                          ),
                          Icon(
                            tenant.status == 'active'
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: tenant.status == 'active'
                                ? AppColors.success
                                : AppColors.danger,
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '牧场: ${tenant.farmCount} · 用户: ${tenant.userCount} · 设备: ${tenant.deviceCount}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (tenant.contactName != null)
                        Text(
                          '联系人: ${tenant.contactName}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
