import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/domain/admin_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/presentation/admin_controller.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class TenantListPage extends ConsumerWidget {
  const TenantListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTenants = ref.watch(tenantListControllerProvider);

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tenantListTitle)),
      body: asyncTenants.when(
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
    final l10n = AppLocalizations.of(context)!;

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
              Row(
                children: [
                  const _DeletedVisibilityToggle(),
                  FilledButton.icon(
                    key: const Key('tenant-list-create'),
                    onPressed: () => context.go('/ops/admin/create'),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.tenantListCreate),
                  ),
                  IconButton(
                    key: const Key('tenant-list-refresh'),
                    onPressed: () =>
                        ref.read(tenantListControllerProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
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
            ...items.map((tenant) => _TenantCard(tenant: tenant, ref: ref)),
        ],
      ),
    );
  }
}

/// 列表"显示已删除"开关(ruling 2026-10-14:软删租户默认隐藏)。
class _DeletedVisibilityToggle extends ConsumerWidget {
  const _DeletedVisibilityToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final includeDeleted = ref.watch(includeDeletedTenantsProvider);
    return FilterChip(
      label: const Text('显示已删除'),
      selected: includeDeleted,
      onSelected: (v) {
        ref.read(includeDeletedTenantsProvider.notifier).set(v);
        ref.invalidate(tenantListControllerProvider);
      },
    );
  }
}

class _TenantCard extends ConsumerWidget {
  const _TenantCard({required this.tenant, required this.ref});
  final TenantSummary tenant;
  final WidgetRef ref;

  Future<void> _lifecycle(BuildContext context, String action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (action == 'delete') {
        await repo.deleteTenant(tenant.id);
        messenger.showSnackBar(SnackBar(
            content: Text('租户「${tenant.name}」已删除'),
            backgroundColor: const Color(0xFF2E7D32)));
      } else if (action == 'restore') {
        await repo.restoreTenant(tenant.id);
        messenger.showSnackBar(SnackBar(
            content: Text('租户「${tenant.name}」已恢复(用户保持停用,请逐个启用)'),
            backgroundColor: const Color(0xFF2E7D32)));
      } else {
        final next = action == 'disable' ? 'disabled' : 'active';
        await repo.updateTenantStatus(tenant.id, next);
        messenger.showSnackBar(SnackBar(
            content: Text('租户「${tenant.name}」已${next == 'disabled' ? '停用' : '启用'}'),
            backgroundColor: const Color(0xFF2E7D32)));
      }
      ref.invalidate(tenantListControllerProvider);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text('操作失败: $e'),
          backgroundColor: const Color(0xFFD32F2F)));
    }
  }

  void _confirmDelete(BuildContext context) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('tenant-delete-dialog'),
        title: const Text('删除租户'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('将删除「${tenant.name}」:全部用户停用、订阅取消、牧场下线;业务数据保留且可恢复。'),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('tenant-delete-confirm-name'),
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: '输入租户名称以确认',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          FilledButton(
            key: const Key('tenant-delete-confirm'),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () {
              if (nameCtrl.text.trim() != tenant.name) return;
              Navigator.pop(context);
              _lifecycle(context, 'delete');
            },
            child: const Text('永久删除标记'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                PopupMenuButton<String>(
                  key: Key('tenant-menu-${tenant.id}'),
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (action) {
                    if (action == 'delete') {
                      _confirmDelete(context);
                    } else {
                      _lifecycle(context, action);
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (tenant.status == 'deleted') ...[
                      const PopupMenuItem(
                          value: 'restore', child: Text('恢复租户')),
                    ] else ...[
                      PopupMenuItem(
                          value: tenant.status == 'disabled'
                              ? 'enable'
                              : 'disable',
                          child: Text(tenant.status == 'disabled'
                              ? '启用租户'
                              : '停用租户')),
                      const PopupMenuItem(
                          value: 'delete',
                          child: Text('删除租户',
                              style: TextStyle(color: Color(0xFFD32F2F)))),
                    ],
                  ],
                ),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
