import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/web_file_utils.dart';
import 'package:hkt_livestock_agentic/features/admin/license/domain/deployment_license_models.dart';
import 'package:hkt_livestock_agentic/features/admin/license/presentation/deployment_license_controller.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_status_chip.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// On-premise deployment license management page (NIX-184 T7a, design §12).
///
/// HOSTED mode renders a notice card only; ONPREM mode renders the tenant
/// dropdown, enrollment info, current license/runtime status, upload flow and
/// renewal guidance. Platform-global surface — not farm-scoped.
class DeploymentLicensePage extends ConsumerWidget {
  const DeploymentLicensePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncView = ref.watch(deploymentLicenseControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.deploymentLicenseTitle)),
      body: asyncView.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.md),
              Text('$e', textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(deploymentLicenseControllerProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
        data: (view) {
          final children = <Widget>[];
          if (view.isHosted) {
            children.add(const _HostedModeCard());
          } else {
            children.addAll([
              _TenantDropdown(view: view),
              if (view.enrollment != null)
                _EnrollmentCard(enrollment: view.enrollment!),
              if (view.current != null)
                _LicenseStatusCard(status: view.current!),
              if (view.current?.needsRenewal ?? false)
                const _RenewalGuidanceBanner(),
              if (view.lastImport != null)
                _ImportSuccessBanner(result: view.lastImport!),
              if (view.selectedTenantId != null) _UploadCard(view: view),
            ]);
          }
          return ListView(
            key: const Key('page-deployment-license'),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: children
                .map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: w,
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

// ── HOSTED mode ─────────────────────────────────────────────────────

class _HostedModeCard extends StatelessWidget {
  const _HostedModeCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HighfiCard(
      key: const Key('hosted-mode-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_done_outlined, color: AppColors.info),
              const SizedBox(width: AppSpacing.sm),
              Text(l10n.deploymentLicenseHostedTitle,
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.deploymentLicenseHostedNotice,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Tenant dropdown ─────────────────────────────────────────────────

class _TenantDropdown extends ConsumerWidget {
  const _TenantDropdown({required this.view});
  final DeploymentLicenseViewState view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (view.tenants.isEmpty) {
      return HighfiCard(
        child: Text(l10n.deploymentLicenseNoTenants,
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    return HighfiCard(
      child: Row(
        children: [
          Text(l10n.deploymentLicenseTenantLabel,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DropdownButton<int>(
              key: const Key('license-tenant-dropdown'),
              isExpanded: true,
              value: view.selectedTenantId,
              hint: Text(l10n.deploymentLicenseTenantLabel),
              items: view.tenants
                  .map((t) => DropdownMenuItem<int>(
                        value: t.id,
                        child: Text(t.name.isEmpty ? '#${t.id}' : t.name),
                      ))
                  .toList(),
              onChanged: (id) {
                if (id != null) {
                  ref
                      .read(deploymentLicenseControllerProvider.notifier)
                      .selectTenant(id);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Enrollment info ─────────────────────────────────────────────────

class _EnrollmentCard extends StatelessWidget {
  const _EnrollmentCard({required this.enrollment});
  final EnrollmentInfo enrollment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HighfiCard(
      key: const Key('enrollment-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deploymentLicenseEnrollmentTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.deploymentLicenseEnrollmentDesc,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          _CopyField(
            copyKey: 'copy-installation-id',
            label: l10n.deploymentLicenseInstallationId,
            value: enrollment.installationId,
          ),
          _CopyField(
            copyKey: 'copy-fingerprint-hash',
            label: l10n.deploymentLicenseFingerprintHash,
            value: enrollment.fingerprintHash,
          ),
          _CopyField(
            copyKey: 'copy-public-key-id',
            label: l10n.deploymentLicensePublicKeyId,
            value: enrollment.publicKeyId,
          ),
          if (enrollment.generatedAt != null)
            _PlainField(
                label: l10n.deploymentLicenseGeneratedAt,
                value: enrollment.generatedAt!),
        ],
      ),
    );
  }
}

/// Label + value row with a copy-to-clipboard affordance.
class _CopyField extends StatelessWidget {
  const _CopyField({
    required this.copyKey,
    required this.label,
    required this.value,
  });

  final String copyKey;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontFamily: 'monospace')),
          ),
          InkWell(
            key: Key(copyKey),
            borderRadius: BorderRadius.circular(4),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.deploymentLicenseCopied),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child:
                  Icon(Icons.copy, size: 14, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlainField extends StatelessWidget {
  const _PlainField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

// ── Current license status ──────────────────────────────────────────

class _LicenseStatusCard extends StatelessWidget {
  const _LicenseStatusCard({required this.status});
  final DeploymentLicenseStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chip = _statusChip(context, status.runtimeStatus);

    return HighfiCard(
      key: const Key('license-status-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.deploymentLicenseStatusTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              chip,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (status.expiresAt != null)
            _PlainField(
              label: l10n.deploymentLicenseExpiresAt,
              value: _expiryText(context, status.expiresAt!),
            ),
          if (status.licenseId != null)
            _PlainField(
                label: l10n.deploymentLicenseLicenseId, value: status.licenseId!),
          if (status.licenseType != null)
            _PlainField(
                label: l10n.deploymentLicenseLicenseType,
                value: status.licenseType!),
          if (status.effectiveTier != null)
            _PlainField(
                label: l10n.deploymentLicenseEffectiveTier,
                value: status.effectiveTier!),
          if (status.issuedAt != null)
            _PlainField(
                label: l10n.deploymentLicenseIssuedAt, value: status.issuedAt!),
          if (status.acceptedAt != null)
            _PlainField(
                label: l10n.deploymentLicenseAcceptedAt,
                value: status.acceptedAt!),
          if (status.lastValidatedAt != null)
            _PlainField(
                label: l10n.deploymentLicenseLastValidatedAt,
                value: status.lastValidatedAt!),
          if (status.lastResult != null)
            _PlainField(
                label: l10n.deploymentLicenseLastResult, value: status.lastResult!),
          if (status.lastErrorCode != null)
            _PlainField(
                label: l10n.deploymentLicenseLastErrorCode,
                value: status.lastErrorCode!),
          if (status.maxObservedAt != null)
            _PlainField(
                label: l10n.deploymentLicenseMaxObservedAt,
                value: status.maxObservedAt!),
          if (status.protectionReason != null &&
              status.protectionReason!.isNotEmpty)
            Container(
              key: const Key('protection-banner'),
              width: double.infinity,
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning),
              ),
              child: Text(
                '${l10n.deploymentLicenseProtectionReason}: ${status.protectionReason}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.warningStrong),
              ),
            ),
          const Divider(height: AppSpacing.lg),
          Text(l10n.deploymentLicenseSubscriptionMapping,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          if (status.subscriptionStatus != null)
            _PlainField(
                label: l10n.deploymentLicenseSubscriptionStatus,
                value: status.subscriptionStatus!),
          if (status.subscriptionTrialEndsAt != null)
            _PlainField(
                label: l10n.deploymentLicenseSubscriptionTrialEnds,
                value: status.subscriptionTrialEndsAt!),
        ],
      ),
    );
  }

  /// Four-state runtime chip (VALID / PENDING_ACTIVATION / EXPIRED /
  /// SUSPENDED, plus an unknown fallback), keyed for widget tests.
  HighfiStatusChip _statusChip(BuildContext context, LicenseRuntimeStatus s) {
    final l10n = AppLocalizations.of(context)!;
    return switch (s) {
      LicenseRuntimeStatus.valid => HighfiStatusChip(
          key: const Key('license-status-chip-valid'),
          label: l10n.deploymentLicenseStatusValid,
          color: AppColors.success,
          icon: Icons.check_circle_outline,
        ),
      LicenseRuntimeStatus.pendingActivation => HighfiStatusChip(
          key: const Key('license-status-chip-pendingActivation'),
          label: l10n.deploymentLicenseStatusPendingActivation,
          color: AppColors.info,
          icon: Icons.schedule,
        ),
      LicenseRuntimeStatus.expired => HighfiStatusChip(
          key: const Key('license-status-chip-expired'),
          label: l10n.deploymentLicenseStatusExpired,
          color: AppColors.danger,
          icon: Icons.error_outline,
        ),
      LicenseRuntimeStatus.suspended => HighfiStatusChip(
          key: const Key('license-status-chip-suspended'),
          label: l10n.deploymentLicenseStatusSuspended,
          color: AppColors.warning,
          icon: Icons.pause_circle_outline,
        ),
      LicenseRuntimeStatus.unknown => HighfiStatusChip(
          key: const Key('license-status-chip-unknown'),
          label: l10n.deploymentLicenseStatusUnknown,
          color: AppColors.textSecondary,
          icon: Icons.help_outline,
        ),
    };
  }

  /// `expiresAt` plus a remaining-days countdown (or overdue hint).
  String _expiryText(BuildContext context, String expiresAtRaw) {
    final l10n = AppLocalizations.of(context)!;
    final expiresAt = DateTime.tryParse(expiresAtRaw);
    if (expiresAt == null) return expiresAtRaw;
    final days = expiresAt.difference(DateTime.now()).inDays;
    if (days >= 0) return '$expiresAtRaw (${l10n.deploymentLicenseDaysRemaining(days)})';
    return '$expiresAtRaw (${l10n.deploymentLicenseDaysOverdue(-days)})';
  }
}

// ── Banners ─────────────────────────────────────────────────────────

class _RenewalGuidanceBanner extends StatelessWidget {
  const _RenewalGuidanceBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const Key('renewal-guidance'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.refresh_outlined, color: AppColors.danger),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              l10n.deploymentLicenseRenewalGuidance,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.dangerStrong),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportSuccessBanner extends StatelessWidget {
  const _ImportSuccessBanner({required this.result});
  final ImportLicenseResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const Key('import-success-banner'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_outlined, color: AppColors.success),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '${l10n.deploymentLicenseUploadSuccess}\n'
              '${l10n.deploymentLicenseLicenseId}: ${result.licenseId ?? '-'} · '
              '${l10n.deploymentLicenseExpiresAt}: ${result.expiresAt ?? '-'}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.successStrong),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upload flow ─────────────────────────────────────────────────────

class _UploadCard extends ConsumerWidget {
  const _UploadCard({required this.view});
  final DeploymentLicenseViewState view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return HighfiCard(
      key: const Key('upload-area'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deploymentLicenseUploadTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.deploymentLicenseUploadDesc,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('pick-license-file'),
            onPressed: () => _pickAndConfirm(context, ref),
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(l10n.deploymentLicensePickFile),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndConfirm(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await pickFileBytesWithName(['sllicense']);
    if (picked == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deploymentLicenseUploadConfirmTitle),
        content: Text(l10n.deploymentLicenseUploadConfirmMessage(picked.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('confirm-import-license'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(deploymentLicenseControllerProvider.notifier)
          .importLicense(picked.bytes, picked.name);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.deploymentLicenseUploadSuccess)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          key: const Key('import-error-snackbar'),
          content: Text('${l10n.deploymentLicenseUploadFailed}: $e'),
        ),
      );
    }
  }
}
