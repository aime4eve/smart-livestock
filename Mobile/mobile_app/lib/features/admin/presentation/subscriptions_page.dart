import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/subscription_service_management/presentation/subscription_service_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';

class SubscriptionsPage extends ConsumerWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(subscriptionServiceControllerProvider);
    final controller =
        ref.read(subscriptionServiceControllerProvider.notifier);

    return SingleChildScrollView(
      key: const Key('page-subscriptions'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '订阅服务管理',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '管理所有租户的订阅服务',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (data.viewState == ViewState.normal)
            ...data.services.map((service) {
              final status = service['status'] as String? ?? '';
              final statusColor = switch (status) {
                'active' => AppColors.success,
                'expired' => AppColors.danger,
                'revoked' => AppColors.danger,
                _ => AppColors.info,
              };
              final statusLabel = switch (status) {
                'active' => '生效中',
                'expired' => '已过期',
                'revoked' => '已撤销',
                _ => status,
              };

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: HighfiCard(
                  key: Key('service-${service['id']}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            service['tenantName'] as String? ?? '',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          HighfiStatusChip(
                            label: statusLabel,
                            color: statusColor,
                            icon: status == 'active'
                                ? Icons.check_circle_outline
                                : Icons.cancel_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '套餐: ${service['tier'] ?? ''}',
                      ),
                      Text('期限: ${service['startDate'] ?? ''} ~ ${service['endDate'] ?? ''}'),
                      Text(
                        '牲畜数量: ${service['livestockCount'] ?? 0}',
                      ),
                      if (status == 'active')
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            key: Key('revoke-${service['id']}'),
                            onPressed: () =>
                                controller.revokeService(service['id'] as String),
                            icon: const Icon(Icons.block, size: 16),
                            label: const Text('撤销'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          if (data.viewState == ViewState.empty)
            const SizedBox(
              height: 200,
              child: Center(child: Text('暂无订阅服务')),
            ),
          if (data.viewState == ViewState.loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
