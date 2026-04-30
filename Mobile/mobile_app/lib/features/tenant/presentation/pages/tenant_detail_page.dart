import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_detail_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_devices_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_logs_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_stats_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_trends_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/widgets/license_adjust_dialog.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/widgets/tenant_delete_dialog.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/widgets/tenant_skeleton.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/widgets/tenant_trend_chart.dart';

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

  Widget _buildBody(
      BuildContext context, WidgetRef ref, TenantDetailViewData data) {
    if (data.viewState == ViewState.loading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: TenantSkeleton(),
      );
    }
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
          _buildBasicInfoCard(context, t),
          const SizedBox(height: AppSpacing.md),
          _buildActionsCard(context, ref, t),
          const SizedBox(height: AppSpacing.md),
          _buildStatsCard(context, ref),
          const SizedBox(height: AppSpacing.md),
          _buildTrendCard(context, ref),
          const SizedBox(height: AppSpacing.md),
          _buildDevicesCard(context, ref),
          const SizedBox(height: AppSpacing.md),
          _buildLogsCard(context, ref),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(BuildContext context, Tenant t) {
    return HighfiCard(
      key: const Key('tenant-detail-card-basic'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child:
                    Text(t.name, style: Theme.of(context).textTheme.titleLarge),
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
          if (t.contactName != null || t.region != null) ...[
            const Divider(height: AppSpacing.xl),
            if (t.contactName != null)
              _infoRow(Icons.person_outline, '联系人', t.contactName!),
            if (t.contactPhone != null)
              _infoRow(Icons.phone_outlined, '电话', t.contactPhone!),
            if (t.contactEmail != null)
              _infoRow(Icons.email_outlined, '邮箱', t.contactEmail!),
            if (t.region != null)
              _infoRow(Icons.location_on_outlined, '地区', t.region!),
          ],
          if (t.remarks != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              t.remarks!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          if (t.createdAt != null || t.updatedAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            if (t.createdAt != null)
              Text(
                '创建于 ${t.createdAt!.substring(0, 10)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            if (t.updatedAt != null)
              Text(
                '最近更新 ${t.updatedAt!.substring(0, 10)}  ·  ${t.lastUpdatedBy ?? ""}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label：',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, WidgetRef ref, Tenant t) {
    return HighfiCard(
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
    );
  }

  Widget _buildStatsCard(BuildContext context, WidgetRef ref) {
    final data = ref.watch(tenantStatsControllerProvider(id));
    if (data.viewState == ViewState.loading) {
      return const SizedBox.shrink();
    }
    if (data.viewState != ViewState.normal) {
      return const TenantEmptyCard(
        title: '暂无统计数据',
        icon: Icons.bar_chart_outlined,
      );
    }
    return HighfiCard(
      key: const Key('tenant-detail-card-stats'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('统计概览', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _statMiniTile('牲畜总数', '${data.livestockTotal}', '头'),
              _statMiniTile('在线设备', '${data.deviceOnline}/${data.deviceTotal}',
                  '在线率 ${data.deviceOnlineRate}%'),
              _statMiniTile('健康率', '${data.healthRate}%', null),
              _statMiniTile('今日告警', '${data.alertCount}',
                  data.lastSync != null ? '同步 $data.lastSync' : null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statMiniTile(String label, String value, String? caption) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        if (caption != null)
          Text(
            caption,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
      ],
    );
  }

  Widget _buildDevicesCard(BuildContext context, WidgetRef ref) {
    final data = ref.watch(tenantDevicesControllerProvider(id));
    if (data.viewState == ViewState.loading) {
      return const SizedBox.shrink();
    }
    if (data.viewState != ViewState.normal) {
      return const TenantEmptyCard(
        title: '暂无设备数据',
        icon: Icons.devices_outlined,
        description: '该租户下暂未绑定设备',
      );
    }
    final shown = data.devices.take(5).toList();
    final more = data.devices.length - shown.length;
    return HighfiCard(
      key: const Key('tenant-detail-card-devices'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '设备列表（${data.total} 台）',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...shown.map((d) => _deviceRow(d)),
          if (more > 0)
            Text(
              '...还有 $more 台设备',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
        ],
      ),
    );
  }

  Widget _deviceRow(DeviceItem d) {
    String typeLabel;
    IconData typeIcon;
    switch (d.type) {
      case DeviceType.gps:
        typeLabel = 'GPS';
        typeIcon = Icons.gps_fixed;
      case DeviceType.rumenCapsule:
        typeLabel = '胶囊';
        typeIcon = Icons.medical_services_outlined;
      case DeviceType.accelerometer:
        typeLabel = '加速度计';
        typeIcon = Icons.sensors;
    }

    String statusLabel;
    Color statusColor;
    switch (d.status) {
      case DeviceStatus.online:
        statusLabel = '在线';
        statusColor = AppColors.success;
      case DeviceStatus.offline:
        statusLabel = '离线';
        statusColor = AppColors.danger;
      case DeviceStatus.lowBattery:
        statusLabel = '低电量';
        statusColor = AppColors.warning;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(typeIcon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${d.name}  ·  $typeLabel  ·  ${d.boundEarTag}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(fontSize: 11, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsCard(BuildContext context, WidgetRef ref) {
    final data = ref.watch(tenantLogsControllerProvider(id));
    if (data.viewState == ViewState.loading) {
      return const SizedBox.shrink();
    }
    if (data.viewState != ViewState.normal) {
      return const TenantEmptyCard(
        title: '暂无操作日志',
        icon: Icons.history_outlined,
      );
    }
    return HighfiCard(
      key: const Key('tenant-detail-card-logs'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('操作日志', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          ...data.logs.map((log) => _logRow(context, log)),
        ],
      ),
    );
  }

  Widget _logRow(BuildContext context, TenantLogEntry log) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5, right: AppSpacing.sm),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.info,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.action,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text(log.detail,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                Text(
                  '${log.operator}  ·  ${log.createdAt.substring(0, 10)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(BuildContext context, WidgetRef ref) {
    final data = ref.watch(tenantTrendsControllerProvider(id));
    if (data.viewState == ViewState.loading) {
      return const SizedBox.shrink();
    }
    if (data.viewState != ViewState.normal || data.dailyStats.isEmpty) {
      return const SizedBox.shrink();
    }
    return HighfiCard(
      key: const Key('tenant-detail-card-trends'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('30 天告警趋势', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          TenantTrendChart(dailyStats: data.dailyStats),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(
      BuildContext context, WidgetRef ref, Tenant t) async {
    final next = t.status == TenantStatus.active
        ? TenantStatus.disabled
        : TenantStatus.active;
    if (ref.read(appModeProvider).isLive) {
      final role = ref.read(sessionControllerProvider).role?.wireName ??
          'platform_admin';
      final r = await ApiCache.instance
          .toggleTenantStatusRemote(role, t.id, next.wireValue);
      if (!context.mounted) return;
      if (!r.ok) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(r.message ?? '状态切换失败')));
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

  Future<void> _adjustLicense(
      BuildContext context, WidgetRef ref, Tenant t) async {
    final next = await showDialog<int>(
      context: context,
      builder: (_) => LicenseAdjustDialog(tenant: t),
    );
    if (next == null) return;
    if (ref.read(appModeProvider).isLive) {
      final role = ref.read(sessionControllerProvider).role?.wireName ??
          'platform_admin';
      final r =
          await ApiCache.instance.adjustTenantLicenseRemote(role, t.id, next);
      if (!context.mounted) return;
      if (!r.ok) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(r.message ?? 'License 调整失败')));
        return;
      }
      await ApiCache.instance.refreshTenants(role);
    }
    ref.read(tenantListControllerProvider.notifier).refresh();
    ref.read(tenantDetailControllerProvider(t.id).notifier).refresh();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('License 已调整')));
  }

  Future<void> _deleteTenant(
      BuildContext context, WidgetRef ref, Tenant t) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => TenantDeleteDialog(tenantName: t.name),
    );
    if (reason == null) return;
    if (ref.read(appModeProvider).isLive) {
      final role = ref.read(sessionControllerProvider).role?.wireName ??
          'platform_admin';
      final r = await ApiCache.instance.deleteTenantRemote(role, t.id);
      if (!context.mounted) return;
      if (!r.ok) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(r.message ?? '删除失败')));
        return;
      }
      await ApiCache.instance.refreshTenants(role);
    }
    ref.read(tenantListControllerProvider.notifier).refresh();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('租户已删除')));
    context.go('/ops/admin');
  }
}
