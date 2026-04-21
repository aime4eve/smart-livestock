import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_detail_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/widgets/license_adjust_dialog.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/widgets/tenant_delete_dialog.dart';

class TenantDetailPage extends ConsumerWidget {
  const TenantDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(tenantDetailControllerProvider(id));
    return Scaffold(
      key: Key('page-tenant-detail-$id'),
      appBar: AppBar(title: const Text('租户详情')),
      body: _buildBody(context, ref, data),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, TenantDetailViewData data) {
    if (data.viewState != ViewState.normal || data.tenant == null) {
      return HighfiEmptyErrorState(
        title: '无法加载',
        description: data.message ?? '租户不存在',
        icon: Icons.error_outline,
      );
    }
    final Tenant t = data.tenant!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HighfiCard(
            key: const Key('tenant-detail-card-basic'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(t.name,
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    HighfiStatusChip(
                      label: t.status == TenantStatus.active ? '启用中' : '已禁用',
                      color: t.status == TenantStatus.active
                          ? AppColors.success
                          : AppColors.danger,
                      icon: t.status == TenantStatus.active
                          ? Icons.check_circle_outline
                          : Icons.block_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('License ${t.licenseUsed} / ${t.licenseTotal}'),
                const SizedBox(height: AppSpacing.xs),
                LinearProgressIndicator(
                  value: t.licenseUsage.clamp(0.0, 1.0),
                  minHeight: 6,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          HighfiCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('tenant-detail-edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('编辑'),
                  onPressed: () => context.go('/ops/admin/${t.id}/edit'),
                ),
                OutlinedButton.icon(
                  key: const Key('tenant-detail-toggle'),
                  icon: Icon(t.status == TenantStatus.active
                      ? Icons.block_outlined
                      : Icons.play_circle_outline),
                  label: Text(t.status == TenantStatus.active ? '禁用' : '启用'),
                  onPressed: () => _toggleStatus(context, ref, t),
                ),
                OutlinedButton.icon(
                  key: const Key('tenant-detail-license'),
                  icon: const Icon(Icons.tune),
                  label: const Text('调整 License'),
                  onPressed: () => _adjustLicense(context, ref, t),
                ),
                OutlinedButton.icon(
                  key: const Key('tenant-detail-delete'),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _deleteTenant(context, ref, t),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(BuildContext context, WidgetRef ref, Tenant t) async {
    final next = t.status == TenantStatus.active
        ? TenantStatus.disabled
        : TenantStatus.active;
    if (ref.read(appModeProvider).isLive) {
      final role = ref.read(sessionControllerProvider).role?.name ?? 'ops';
      final r = await ApiCache.instance
          .toggleTenantStatusRemote(role, t.id, next.wireValue);
      if (!context.mounted) return;
      if (!r.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(r.message ?? '状态切换失败')));
        return;
      }
      await ApiCache.instance.refreshTenants(role);
    }
    ref.read(tenantListControllerProvider.notifier).refresh();
    ref.read(tenantDetailControllerProvider(t.id).notifier).refresh();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('已更新租户状态')));
  }

  Future<void> _adjustLicense(BuildContext context, WidgetRef ref, Tenant t) async {
    final next = await showDialog<int>(
      context: context,
      builder: (_) => LicenseAdjustDialog(tenant: t),
    );
    if (next == null) return;
    if (ref.read(appModeProvider).isLive) {
      final role = ref.read(sessionControllerProvider).role?.name ?? 'ops';
      final r = await ApiCache.instance.adjustTenantLicenseRemote(role, t.id, next);
      if (!context.mounted) return;
      if (!r.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(r.message ?? 'License 调整失败')));
        return;
      }
      await ApiCache.instance.refreshTenants(role);
    }
    ref.read(tenantListControllerProvider.notifier).refresh();
    ref.read(tenantDetailControllerProvider(t.id).notifier).refresh();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('License 已调整')));
  }

  Future<void> _deleteTenant(BuildContext context, WidgetRef ref, Tenant t) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => TenantDeleteDialog(tenantName: t.name),
    );
    if (reason == null) return;
    if (ref.read(appModeProvider).isLive) {
      final role = ref.read(sessionControllerProvider).role?.name ?? 'ops';
      final r = await ApiCache.instance.deleteTenantRemote(role, t.id);
      if (!context.mounted) return;
      if (!r.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(r.message ?? '删除失败')));
        return;
      }
      await ApiCache.instance.refreshTenants(role);
    }
    ref.read(tenantListControllerProvider.notifier).refresh();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('租户已删除')));
    context.go('/ops/admin');
  }
}
