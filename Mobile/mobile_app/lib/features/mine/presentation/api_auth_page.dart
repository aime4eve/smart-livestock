import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/api_authorization/domain/api_authorization_repository.dart';
import 'package:smart_livestock_demo/features/api_authorization/presentation/api_authorization_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';

class MineApiAuthPage extends ConsumerWidget {
  const MineApiAuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(apiAuthorizationControllerProvider);

    return asyncData.when(
      data: (data) => SingleChildScrollView(
        key: const Key('page-mine-api-auth'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('API 授权管理', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text('管理我的 API Key 和授权', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            if (data.isEmpty)
              const SizedBox(height: 200, child: Center(child: Text('暂无 API Key')))
            else
              ...data.items.map((key) => _MineApiKeyCard(keyItem: key)),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }
}

class _MineApiKeyCard extends StatelessWidget {
  const _MineApiKeyCard({required this.keyItem});

  final ApiKeyItem keyItem;

  @override
  Widget build(BuildContext context) {
    final statusColor = keyItem.status == 'active' ? AppColors.success : AppColors.danger;
    final statusLabel = keyItem.status == 'active' ? '生效中' : (keyItem.status ?? '未知');

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
                      : Icons.pending_outlined,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (keyItem.prefix != null) Text('前缀: ${keyItem.prefix}'),
            if (keyItem.tenantId != null) Text('租户: ${keyItem.tenantId}'),
          ],
        ),
      ),
    );
  }
}
