import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/api_authorization/domain/api_authorization_repository.dart';
import 'package:smart_livestock_demo/features/api_authorization/presentation/api_authorization_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';

class ApiAuthPage extends ConsumerWidget {
  const ApiAuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(apiAuthorizationControllerProvider);
    final controller = ref.read(apiAuthorizationControllerProvider.notifier);

    return asyncData.when(
      data: (data) => SingleChildScrollView(
        key: const Key('page-api-auth'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('API 授权管理', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Text('管理 API Key 的创建、启用和撤销', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('apikey-refresh'),
                  onPressed: () => controller.refresh(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (data.isEmpty)
              const SizedBox(height: 200, child: Center(child: Text('暂无 API Key')))
            else
              ...data.items.map((key) => _ApiKeyCard(keyItem: key)),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }
}

class _ApiKeyCard extends ConsumerWidget {
  const _ApiKeyCard({required this.keyItem});

  final ApiKeyItem keyItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(apiAuthorizationControllerProvider.notifier);
    final statusColor = keyItem.status == 'active' ? AppColors.success : AppColors.danger;
    final statusLabel = keyItem.status == 'active' ? '启用' : (keyItem.status ?? '未知');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: HighfiCard(
        key: Key('apikey-${keyItem.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    keyItem.name ?? keyItem.prefix ?? 'API Key',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                HighfiStatusChip(
                  label: statusLabel,
                  color: statusColor,
                  icon: keyItem.status == 'active'
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (keyItem.prefix != null) Text('前缀: ${keyItem.prefix}'),
            if (keyItem.tenantId != null) Text('租户: ${keyItem.tenantId}'),
            if (keyItem.createdAt != null) Text('创建时间: ${keyItem.createdAt}'),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (keyItem.status == 'active') ...[
                  TextButton.icon(
                    key: Key('disable-${keyItem.id}'),
                    onPressed: () => controller.updateStatus(keyItem.id, 'disabled'),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('禁用'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton.icon(
                    key: Key('revoke-${keyItem.id}'),
                    onPressed: () => controller.revoke(keyItem.id),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('撤销'),
                  ),
                ],
                if (keyItem.status != 'active')
                  TextButton.icon(
                    key: Key('enable-${keyItem.id}'),
                    onPressed: () => controller.updateStatus(keyItem.id, 'active'),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('启用'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
