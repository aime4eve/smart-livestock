import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/b2b_admin/domain/b2b_repository.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_controller.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/widgets/confirm_dialog.dart';
import 'package:smart_livestock_demo/core/l10n/l10n.dart';
import 'package:smart_livestock_demo/l10n/gen/app_localizations.dart';

class B2bContractPage extends ConsumerWidget {
  const B2bContractPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(b2bContractControllerProvider);
    final theme = Theme.of(context);

    return asyncData.when(
      data: (data) => _buildContent(context, ref, data),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.commonLoadFailed, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, B2bContractData data) {
    return _ContractContent(data: data);
  }
}

// ---------------------------------------------------------------------------
// Main content
// ---------------------------------------------------------------------------

class _ContractContent extends StatelessWidget {
  const _ContractContent({required this.data});

  final B2bContractData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header
          _buildPageHeader(context),
          const SizedBox(height: AppSpacing.lg),

          // Main info card (gray-blue gradient)
          _buildMainInfoCard(context),
          const SizedBox(height: AppSpacing.lg),

          // Expiry reminder bar
          if (data.expiresAt != null)
            _ExpiryReminderBar(expiresAt: data.expiresAt!),
          if (data.expiresAt != null)
            const SizedBox(height: AppSpacing.lg),

          // Contract terms section
          _buildContractTermsSection(context),
          const SizedBox(height: AppSpacing.lg),

          // Subscription service status (only for licensed billing)
          if (data.billingModel == 'licensed') ...[
            _buildSubscriptionStatusSection(context),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Quick actions
          _buildQuickActions(context),
        ],
      ),
    );
  }

  // --- Page header ---
  Widget _buildPageHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back, size: 18),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(l10n.b2bContractTitle,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- Main info card (gradient) ---
  Widget _buildMainInfoCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _statusColor(data.status);
    final statusText = _statusText(data.status);

    return Container(
      key: const Key('b2b-contract-main-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF37474F), Color(0xFF607D8B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4037474F),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Partner name + status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  data.partnerName ?? '-',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (data.status != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Divider
          Divider(color: Colors.white.withValues(alpha: 0.3), height: 1),
          const SizedBox(height: AppSpacing.md),

          // Bottom row: 3 items
          Row(
            children: [
              _HeroInfoItem(
                label: l10n.b2bContractNumber,
                value: data.contractId ?? '-',
              ),
              const SizedBox(width: AppSpacing.xl),
              _HeroInfoItem(
                label: l10n.b2bContractSigner,
                value: data.signedBy ?? '-',
              ),
              const SizedBox(width: AppSpacing.xl),
              _HeroInfoItem(
                label: l10n.b2bContractBillingMode,
                value: _billingModelText(data.billingModel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Contract terms section ---
  Widget _buildContractTermsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      key: const Key('b2b-contract-terms-section'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              const Icon(Icons.description_outlined,
                  size: 18, color: Color(0xFF607D8B)),
              const SizedBox(width: AppSpacing.sm),
              Text(l10n.b2bContractTerms,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 2x2 grid
          Row(
            children: [
              Expanded(
                child: _TermCard(
                  icon: Icons.workspace_premium_outlined,
                  label: l10n.b2bContractTierLevel,
                  value: _tierText(data.effectiveTier),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TermCard(
                  icon: Icons.percent,
                  label: l10n.b2bContractRevenueShare,
                  value: data.revenueShareRatio != null
                      ? '${(data.revenueShareRatio! * 100).toStringAsFixed(0)}%'
                      : '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _TermCard(
                  icon: Icons.play_arrow,
                  label: l10n.b2bContractEffectiveDate,
                  value: _formatDate(data.startedAt),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TermCard(
                  icon: Icons.schedule,
                  label: l10n.b2bContractExpiryDate,
                  value: _formatDate(data.expiresAt),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Subscription service status section ---
  Widget _buildSubscriptionStatusSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dotColor = _serviceStatusColor(data.serviceStatus);
    final statusLabel = _serviceStatusText(data.serviceStatus);

    return Container(
      key: const Key('b2b-contract-subscription-section'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              const Icon(Icons.vpn_key_outlined,
                  size: 18, color: Color(0xFF607D8B)),
              const SizedBox(width: AppSpacing.sm),
              Text(l10n.b2bContractServiceStatus,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Status indicator
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(statusLabel,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
              if (data.serviceTier != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    data.serviceTier!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 2x2 grid
          Row(
            children: [
              Expanded(
                child: _SubInfoItem(
                  icon: Icons.cloud_outlined,
                  label: l10n.b2bContractDeployMode,
                  value: _deploymentTypeText(data.deploymentType),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SubInfoItem(
                  icon: Icons.devices_outlined,
                  label: l10n.b2bContractDeviceQuota,
                  value: data.deviceQuota != null
                      ? '${data.deviceQuota}'
                      : '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _SubInfoItem(
                  icon: Icons.favorite_outline,
                  label: l10n.b2bContractHeartbeat,
                  value: _formatDate(data.lastHeartbeatAt),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SubInfoItem(
                  icon: Icons.timer_outlined,
                  label: l10n.b2bContractExpiryTime,
                  value: _formatDate(data.serviceExpiresAt),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Quick actions ---
  Widget _buildQuickActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            key: const Key('b2b-contract-action-contact'),
            icon: Icons.headset_mic_outlined,
            title: l10n.b2bContractContactPlatform,
            subtitle: l10n.b2bContractContactPlatformDesc,
            onTap: () {
              B2bConfirmDialog.show(
                context,
                title: l10n.b2bContractComingSoon,
                subtitle: l10n.b2bContractChatComingSoon,
                confirmLabel: l10n.b2bContractGotIt,
                cancelLabel: l10n.b2bContractClose,
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionCard(
            key: const Key('b2b-contract-action-download'),
            icon: Icons.download_outlined,
            title: l10n.b2bContractDownload,
            subtitle: l10n.b2bContractDownloadDesc,
            onTap: () {
              B2bConfirmDialog.show(
                context,
                title: l10n.b2bContractComingSoon,
                subtitle: l10n.b2bContractPdfComingSoon,
                confirmLabel: l10n.b2bContractGotIt,
                cancelLabel: l10n.b2bContractClose,
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Helpers ---
  static String _statusText(String? status) => switch (status) {
        'active' => L10n.instance.b2bContractStatusActive,
        'suspended' => L10n.instance.b2bContractStatusSuspended,
        'expired' => L10n.instance.b2bContractStatusExpired,
        _ => status ?? '-',
      };

  static Color _statusColor(String? status) => switch (status) {
        'active' => const Color(0xFF81C784),
        'suspended' => const Color(0xFFFFCC80),
        'expired' => const Color(0xFFEF9A9A),
        _ => const Color(0xFFBDBDBD),
      };

  static String _billingModelText(String? model) => switch (model) {
        'revenue_share' => L10n.instance.b2bContractModeRevenueShare,
        'licensed' => L10n.instance.b2bContractModeLicensed,
        _ => model ?? '-',
      };

  static String _tierText(String? tier) => switch (tier) {
        'standard' => L10n.instance.subscriptionTierStandard,
        'premium' => L10n.instance.subscriptionTierPremium,
        'enterprise' => L10n.instance.subscriptionTierEnterprise,
        _ => tier ?? '-',
      };

  static String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      return isoDate.substring(0, 10);
    } catch (_) {
      return '-';
    }
  }

  static String _deploymentTypeText(String? type) => switch (type) {
        'cloud' => L10n.instance.b2bContractDeployCloud,
        'on_premise' => L10n.instance.b2bContractDeployOnPremise,
        _ => type ?? '-',
      };

  static Color _serviceStatusColor(String? status) => switch (status) {
        'running' => const Color(0xFF4CAF50),
        'degraded' => const Color(0xFFFFC107),
        'down' => const Color(0xFFF44336),
        _ => const Color(0xFFBDBDBD),
      };

  static String _serviceStatusText(String? status) => switch (status) {
        'running' => L10n.instance.b2bContractHealthRunning,
        'degraded' => L10n.instance.b2bContractHealthDegraded,
        'down' => L10n.instance.b2bContractHealthDown,
        _ => status ?? L10n.instance.b2bContractUnknown,
      };
}

// ---------------------------------------------------------------------------
// Expiry reminder bar
// ---------------------------------------------------------------------------

class _ExpiryReminderBar extends StatelessWidget {
  const _ExpiryReminderBar({required this.expiresAt});

  final String expiresAt;

  int get _remainingDays {
    try {
      final expiry = DateTime.parse(expiresAt);
      final now = DateTime.now();
      return expiry.difference(now).inDays;
    } catch (_) {
      return 0;
    }
  }

  Color get _buttonColor {
    final days = _remainingDays;
    if (days <= 30) return const Color(0xFFE53935);
    if (days <= 90) return const Color(0xFFEF6C00);
    return const Color(0xFF1565C0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = _remainingDays;
    final dateStr =
        expiresAt.length >= 10 ? expiresAt.substring(0, 10) : expiresAt;

    return Container(
      key: const Key('b2b-contract-expiry-bar'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.event, size: 20, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),

          // Label + date + remaining
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.b2bContractExpiryLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF455A64),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  days > 0
                      ? l10n.b2bContractDaysLeft(dateStr, '$days')
                      : l10n.b2bContractExpiredOn(dateStr),
                  style: TextStyle(
                    fontSize: 14,
                    color: days > 0
                        ? const Color(0xFF1565C0)
                        : const Color(0xFFE53935),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Contact button
          SizedBox(
            height: 32,
            child: FilledButton(
              key: const Key('b2b-contract-renew-btn'),
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: _buttonColor,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.b2bContractRenew,
                  style: TextStyle(fontSize: 13, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _HeroInfoItem extends StatelessWidget {
  const _HeroInfoItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            )),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }
}

class _TermCard extends StatelessWidget {
  const _TermCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF607D8B)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).hintColor,
                    )),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF37474F),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubInfoItem extends StatelessWidget {
  const _SubInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF607D8B)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).hintColor,
                    )),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF455A64),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(icon, size: 28, color: const Color(0xFF607D8B)),
              const SizedBox(height: AppSpacing.sm),
              Text(title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF37474F),
                  )),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).hintColor,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
