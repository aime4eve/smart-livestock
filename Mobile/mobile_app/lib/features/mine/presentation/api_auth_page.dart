import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/api_authorization/presentation/api_authorization_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';

class MineApiAuthPage extends ConsumerWidget {
  const MineApiAuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(apiKeyControllerProvider);

    return SingleChildScrollView(
      key: const Key('page-mine-api-auth'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'API 授权管理',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '管理我的 API Key 和授权',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (data.viewState == ViewState.normal)
            ...data.apiKeys.map((key) {
              final status = key['status'] as String? ?? '';
              final statusColor = switch (status) {
                'active' => AppColors.success,
                'pending' => AppColors.warning,
                'revoked' => AppColors.danger,
                _ => AppColors.info,
              };
              final statusLabel = switch (status) {
                'active' => '生效中',
                'pending' => '审核中',
                'revoked' => '已撤销',
                _ => status,
              };

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: HighfiCard(
                  key: Key('apikey-${key['id']}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            key['keyName'] as String? ?? '',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          HighfiStatusChip(
                            label: statusLabel,
                            color: statusColor,
                            icon: status == 'active'
                                ? Icons.check_circle_outline
                                : Icons.pending_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text('权限范围: ${key['scope'] ?? ''}'),
                      Text(
                        '频率限制: ${key['rateLimit'] ?? 0} 次/小时',
                      ),
                      if (key['expiresAt'] != null)
                        Text('过期时间: ${key['expiresAt']}'),
                    ],
                  ),
                ),
              );
            }),
          if (data.viewState == ViewState.empty)
            const SizedBox(
              height: 200,
              child: Center(child: Text('暂无 API Key')),
            ),
          if (data.viewState == ViewState.loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
