import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/subscription_controller.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/widgets/usage_progress_bar.dart';
import 'package:smart_livestock_demo/l10n/gen/app_localizations.dart';

class SubscriptionStatusCard extends ConsumerWidget {
  const SubscriptionStatusCard({super.key});

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'trial':
        return l10n.subscriptionStatusTrial;
      case 'active':
        return l10n.subscriptionStatusActive;
      case 'cancelled':
        return l10n.subscriptionStatusCancelled;
      case 'expired':
        return l10n.subscriptionStatusExpired;
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'trial':
        return AppColors.info;
      case 'active':
        return AppColors.success;
      case 'cancelled':
        return AppColors.textSecondary;
      case 'expired':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  String _tierName(SubscriptionTier tier) {
    final info = SubscriptionTierInfo.all[tier];
    return info?.name ?? tier.name;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncStatus = ref.watch(subscriptionControllerProvider);

    return asyncStatus.when(
      data: (status) => _buildCard(context, ref, status),
      loading: () => const Card(
        key: Key('subscription-status-card'),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        key: const Key('subscription-status-card'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text('${l10n.commonLoadFailed}: $e'),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, SubscriptionStatus status) {
    final l10n = AppLocalizations.of(context)!;
    final tierInfo = SubscriptionTierInfo.all[status.tier];
    final isEnterprise = status.tier == SubscriptionTier.enterprise;
    final hasTrialEnd = status.trialEndsAt != null;
    final hasPeriodEnd = status.currentPeriodEnd != null;
    final isActive = status.status == 'active' || status.status == 'trial';
    final theme = Theme.of(context);

    return Card(
      key: const Key('subscription-status-card'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _tierName(status.tier),
                  style: theme.textTheme.titleMedium,
                ),
                Container(
                  key: const Key('status-badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                  ),
                  child: Text(
                    _statusLabel(status.status, l10n),
                    style: TextStyle(
                      color: _statusColor(status.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            if (hasTrialEnd && status.status == 'trial') ...[
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.info),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '试用期至 ${_formatDate(status.trialEndsAt!)}（剩余${_daysRemaining(status.trialEndsAt!)}天）',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (hasPeriodEnd && status.status == 'active') ...[
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.success),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '有效期至 ${_formatDate(status.currentPeriodEnd!)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (status.status == 'cancelled') ...[
              Row(
                children: [
                  const Icon(Icons.cancel_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    hasPeriodEnd
                        ? '订阅将于 ${_formatDate(status.currentPeriodEnd!)} 到期'
                        : '订阅已取消',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            UsageProgressBar(
              current: status.livestockCount,
              limit: isEnterprise ? -1 : (tierInfo?.livestockLimit ?? 50),
              label: '牲畜数量',
            ),
            const SizedBox(height: AppSpacing.md),

            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            _priceRow(context, '套餐费', status.calculatedTierFee),
            const SizedBox(height: AppSpacing.xs),
            _priceRow(
              context,
              '设备费（${status.livestockCount}头 × ¥${tierInfo?.perUnitPrice.toStringAsFixed(0) ?? '0'}/头）',
              status.calculatedDeviceFee,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Divider(),
            const SizedBox(height: AppSpacing.xs),
            _priceRow(context, '合计', status.calculatedTotal, bold: true),
            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                if (status.tier != SubscriptionTier.enterprise)
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('upgrade-plan-button'),
                      onPressed: () {
                        _navigateToPlans(context);
                      },
                      icon: const Icon(Icons.upgrade, size: 18),
                      label: Text(l10n.subscriptionUpgradeTier),
                    ),
                  ),
                if (status.tier != SubscriptionTier.enterprise)
                  const SizedBox(width: AppSpacing.sm),
                if (isActive)
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('renew-button'),
                      onPressed: () {
                        ref
                            .read(subscriptionControllerProvider.notifier)
                            .checkout(
                              tier: status.tier.name,
                              livestockCount: status.livestockCount,
                            );
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(l10n.subscriptionRenew),
                    ),
                  ),
              ],
            ),
            if (isActive && status.status != 'trial') ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                key: const Key('cancel-subscription-button'),
                onPressed: () => _confirmCancel(context, ref),
                icon: const Icon(
                  Icons.cancel_outlined,
                  size: 18,
                  color: AppColors.danger,
                ),
                label: const Text(
                  '取消订阅',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _priceRow(
    BuildContext context,
    String label,
    double amount, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          '¥${amount.toStringAsFixed(2)} 元',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  int _daysRemaining(DateTime end) {
    return end.difference(DateTime.now()).inDays.clamp(0, 999);
  }

  void _navigateToPlans(BuildContext context) {
    context.push(AppRoute.subscriptionPlan.path);
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.subscriptionConfirmCancel),
        content: Text(l10n.subscriptionCancelWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.subscriptionKeepSubscription),
          ),
          TextButton(
            onPressed: () {
              ref.read(subscriptionControllerProvider.notifier).cancel();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.subscriptionCancelled)),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.subscriptionConfirmCancel),
          ),
        ],
      ),
    );
  }
}
