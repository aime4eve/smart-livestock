import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/domain/admin_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/presentation/admin_controller.dart';
import 'package:hkt_livestock_agentic/features/subscription_service_management/domain/subscription_service_repository.dart';
import 'package:hkt_livestock_agentic/features/subscription_service_management/presentation/subscription_service_controller.dart';
import 'package:hkt_livestock_agentic/features/admin/license/domain/deployment_license_models.dart';
import 'package:hkt_livestock_agentic/features/admin/license/presentation/deployment_license_controller.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_status_chip.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// UTC instant → tenant-local yyyy-MM-dd (offset from the tenant chain).
String _fmtDate(String? isoUtc, int? offsetMinutes) {
  final dt = DateTime.tryParse(isoUtc ?? '');
  if (dt == null) return '-';
  final off = offsetMinutes ?? DateTime.now().timeZoneOffset.inMinutes;
  final local = dt.toUtc().add(Duration(minutes: off));
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

class SubscriptionsPage extends ConsumerStatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  ConsumerState<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends ConsumerState<SubscriptionsPage> {
  /// Tenant picked in the pilot-license dropdown (null = first tenant).
  int? _pilotTenantId;
  List<TenantSubscription>? _tenantSubs;
  String? _tenantSubsError;

  Future<void> _loadTenantSubscriptions() async {
    try {
      final list =
          await ref.read(adminRepositoryProvider).loadSubscriptions();
      if (!mounted) return;
      setState(() => _tenantSubs = list);
    } catch (e) {
      if (mounted) setState(() => _tenantSubsError = e.toString());
    }
  }

  void _confirmCancelSubscription(TenantSubscription sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        key: Key('cancel-sub-dialog-${sub.id}'),
        title: const Text('取消订阅'),
        content: const Text('取消该租户的订阅?取消后该租户将回落免费档,即可在租户管理中删除。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            key: Key('cancel-sub-confirm-${sub.id}'),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () {
              Navigator.pop(ctx);
              _cancelSubscription(sub);
            },
            child: const Text('确认取消'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelSubscription(TenantSubscription sub) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminRepositoryProvider).cancelSubscription(sub.id);
      await _loadTenantSubscriptions();
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
          content: Text('订阅已取消'),
          backgroundColor: Color(0xFF2E7D32)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text('取消失败: $e'),
          backgroundColor: const Color(0xFFD32F2F)));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTenantSubscriptions();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(subscriptionServiceControllerProvider);
    final controller =
        ref.read(subscriptionServiceControllerProvider.notifier);
    // Mode awareness (NIX-184): the pilot entry only exists on a HOSTED
    // deployment with the pilot-license switch enabled.
    final licenseMode = ref.watch(licenseModeProvider);
    final LicenseModeInfo? mode = licenseMode.value;
    final pilotAvailable = mode != null &&
        mode.isHosted &&
        mode.pilotLicenseEnabled;

    return Scaffold(
      appBar: AppBar(title: Text(AppRoute.platformSubscriptions.label)),
      body: asyncData.when(
        data: (data) => SingleChildScrollView(
          key: const Key('page-subscriptions'),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('租户订阅',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text('各租户的订阅状态;删除租户前可在此取消其试点/正式订阅。',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              if (_tenantSubsError != null)
                Text('加载失败: $_tenantSubsError',
                    style: Theme.of(context).textTheme.bodySmall),
              if (_tenantSubs == null)
                const Center(child: CircularProgressIndicator())
              else if (_tenantSubs!.isEmpty)
                HighfiCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text('暂无租户订阅',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                )
              else
                ..._tenantSubs!.map((sub) => _TenantSubscriptionCard(
                      sub: sub,
                      onCancel: () => _confirmCancelSubscription(sub),
                    )),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.subServiceManagement,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.subServiceManagementDesc,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (pilotAvailable && data.services.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildPilotActionRow(context, controller, data.services),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (data.services.isNotEmpty)
                ...data.services.map((service) =>
                    _buildServiceCard(context, service, controller)),
              if (data.isEmpty)
                SizedBox(
                  height: 200,
                  child: Center(child: Text(l10n.adminSubscriptionsNoData)),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  // ── Pilot license action row (NIX-184 T7b) ────────────────────────

  Widget _buildPilotActionRow(
    BuildContext context,
    SubscriptionServiceController controller,
    List<SubscriptionServiceInfo> services,
  ) {
    final l10n = AppLocalizations.of(context)!;
    // One entry per tenant (a tenant may expose several services).
    final tenantIds = services
        .map((s) => s.tenantId)
        .whereType<int>()
        .toSet()
        .toList()
      ..sort();
    if (tenantIds.isEmpty) return const SizedBox.shrink();

    final selected = _pilotTenantId ?? tenantIds.first;
    String labelFor(int tenantId) {
      final service =
          services.firstWhere((s) => s.tenantId == tenantId);
      final name = service.serviceName;
      return (name == null || name.isEmpty) ? '#$tenantId' : name;
    }

    return HighfiCard(
      key: const Key('pilot-action-area'),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<int>(
              key: const Key('pilot-tenant-dropdown'),
              isExpanded: true,
              value: selected,
              items: tenantIds
                  .map((id) => DropdownMenuItem<int>(
                        value: id,
                        child: Text(labelFor(id), overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (id) => setState(() => _pilotTenantId = id),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          FilledButton.icon(
            key: const Key('grant-pilot-license'),
            onPressed: () => _confirmGrantPilot(context, controller, selected),
            icon: const Icon(Icons.workspace_premium_outlined, size: 18),
            label: Text(l10n.pilotLicenseGrantButton),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmGrantPilot(
    BuildContext context,
    SubscriptionServiceController controller,
    int tenantId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.pilotLicenseConfirmTitle),
        content: Text(l10n.pilotLicenseConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('confirm-grant-pilot'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final grant = await controller.grantPilotLicense(tenantId);
      messenger.showSnackBar(
        SnackBar(
          key: const Key('pilot-success-snackbar'),
          content: Text(
            l10n.pilotLicenseGrantSuccess(grant.trialEndsAt ?? '-'),
          ),
        ),
      );
    } on ConflictException catch (e) {
      // 409 STATE_CONFLICT: subscription exists in a state that cannot
      // receive the pilot trial (ACTIVE/FREE/SUSPENDED/CANCELLED/...).
      final conflict = e.code == 'STATE_CONFLICT' || e.statusCode == 409;
      messenger.showSnackBar(
        SnackBar(
          key: const Key('pilot-conflict-snackbar'),
          content: Text(
            conflict
                ? l10n.pilotLicenseStateConflict
                : '${l10n.pilotLicenseGrantFailed}: $e',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          key: const Key('pilot-error-snackbar'),
          content: Text('${l10n.pilotLicenseGrantFailed}: $e'),
        ),
      );
    }
  }

  // ── Service cards ─────────────────────────────────────────────────

  Widget _buildServiceCard(
    BuildContext context,
    SubscriptionServiceInfo service,
    SubscriptionServiceController controller,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = switch (service.status?.toUpperCase()) {
      'ACTIVE' => AppColors.success,
      'EXPIRED' => AppColors.danger,
      'REVOKED' => AppColors.danger,
      _ => AppColors.info,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: HighfiCard(
        key: Key('service-${service.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  service.serviceName ?? l10n.subUnknownService,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                HighfiStatusChip(
                  label: service.statusLabel,
                  color: statusColor,
                  icon: service.isActive
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('${l10n.adminSubscriptionsTierLabel}: ${service.effectiveTier ?? ''}'),
            if (service.startedAt != null || service.expiresAt != null)
              Text(
                  l10n.subServicePeriod(service.startedAt ?? '-', service.expiresAt ?? '-')),
            if (service.deviceQuota != null)
              Text('${l10n.adminSubscriptionsQuotaLabel}: ${service.deviceQuota}'),
            Align(
              alignment: Alignment.centerRight,
              child: service.isActive
                  ? TextButton.icon(
                      key: Key('revoke-${service.id}'),
                      onPressed: () => controller.revokeService(service.id),
                      icon: const Icon(Icons.block, size: 16),
                      label: Text(l10n.adminSubscriptionsRevoke),
                    )
                  : TextButton.icon(
                      key: Key('activate-${service.id}'),
                      onPressed: () =>
                          controller.activateService(service.id),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(l10n.adminSubscriptionsRenew),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TenantSubscriptionCard extends StatelessWidget {
  const _TenantSubscriptionCard({required this.sub, required this.onCancel});
  final TenantSubscription sub;
  final VoidCallback onCancel;

  String get _statusLabel {
    switch (sub.status.toUpperCase()) {
      case 'TRIAL':
        return '试点中';
      case 'ACTIVE':
        return '有效';
      case 'FREE':
        return '免费版';
      case 'CANCELLED':
        return '已取消';
      case 'SUSPENDED':
        return '已暂停';
      case 'EXPIRED':
        return '已过期';
      default:
        return sub.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canCancel = ['TRIAL', 'ACTIVE'].contains(sub.status.toUpperCase());
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: HighfiCard(
        key: Key('tenant-sub-${sub.tenantId}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                              (sub.tenantName != null && sub.tenantName!.isNotEmpty)
                                  ? sub.tenantName!
                                  : '#${sub.tenantId}',
                              style: theme.textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        HighfiStatusChip(label: _statusLabel, color: AppColors.textSecondary),
                      ],
                    ),
                    if (sub.trialEndsAt != null)
                      Text('试点至: ${_fmtDate(sub.trialEndsAt, sub.utcOffsetMinutes)}',
                          style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (canCancel)
                TextButton(
                  key: Key('cancel-sub-${sub.tenantId}'),
                  onPressed: onCancel,
                  child: const Text('取消订阅',
                      style: TextStyle(color: Color(0xFFD32F2F))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
