import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/subscription_service_management/domain/subscription_service_repository.dart';
import 'package:hkt_livestock_agentic/features/subscription_service_management/presentation/subscription_service_controller.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_status_chip.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class SubscriptionsPage extends ConsumerWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(subscriptionServiceControllerProvider);
    final controller =
        ref.read(subscriptionServiceControllerProvider.notifier);

    return asyncData.when(
      data: (data) => SingleChildScrollView(
        key: const Key('page-subscriptions'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.subServiceManagement,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.subServiceManagementDesc,
              style: Theme.of(context).textTheme.bodySmall,
            ),
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
    );
  }

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
