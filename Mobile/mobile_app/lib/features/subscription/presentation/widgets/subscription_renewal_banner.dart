import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/subscription_controller.dart';

class SubscriptionRenewalBanner extends ConsumerWidget {
  const SubscriptionRenewalBanner({super.key});

  bool _isExpiringSoon(DateTime? endDate) {
    if (endDate == null) return false;
    return endDate.difference(DateTime.now()).inDays <= 7;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(subscriptionControllerProvider);
    final isActiveTrial = status.status == 'active' || status.status == 'trial';

    final endDate = status.status == 'trial' ? status.trialEndsAt : status.currentPeriodEnd;

    if (!isActiveTrial || !_isExpiringSoon(endDate)) {
      return const SizedBox.shrink();
    }

    final daysLeft = endDate!.difference(DateTime.now()).inDays.clamp(0, 999);
    final isUrgent = daysLeft <= 3;

    return Container(
      key: const Key('renewal-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isUrgent
            ? AppColors.danger.withValues(alpha: 0.12)
            : AppColors.warning.withValues(alpha: 0.12),
        border: Border.all(
          color: isUrgent ? AppColors.danger : AppColors.warning,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Row(
        children: [
          Icon(
            isUrgent ? Icons.warning_rounded : Icons.info_outline,
            color: isUrgent ? AppColors.danger : AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrgent ? '您的订阅即将到期' : '您的订阅即将到期',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isUrgent ? AppColors.danger : AppColors.warning,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  status.status == 'trial'
                      ? '试用期还有$daysLeft天到期，立即续费保留所有数据'
                      : '订阅还有$daysLeft天到期',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton(
            key: const Key('renew-now-button'),
            onPressed: () {
              ref.read(subscriptionControllerProvider.notifier).renew(
                    status.livestockCount,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isUrgent ? AppColors.danger : AppColors.warning,
              foregroundColor: AppColors.surfaceAlt,
            ),
            child: const Text('立即续费'),
          ),
        ],
      ),
    );
  }
}
