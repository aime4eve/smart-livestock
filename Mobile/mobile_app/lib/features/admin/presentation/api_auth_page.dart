import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/api_authorization/presentation/api_authorization_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';

class ApiAuthPage extends ConsumerWidget {
  const ApiAuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(apiAuthorizationControllerProvider);
    final controller =
        ref.read(apiAuthorizationControllerProvider.notifier);

    return SingleChildScrollView(
      key: const Key('page-api-auth'),
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
            '审核和管理第三方开发者的 API 访问授权',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '', label: Text('全部')),
                    ButtonSegment(value: 'pending', label: Text('待审核')),
                    ButtonSegment(value: 'approved', label: Text('已通过')),
                    ButtonSegment(value: 'revoked', label: Text('已撤销')),
                  ],
                  selected: const {''},
                  onSelectionChanged: (selected) {
                    final s = selected.first;
                    controller.filterByStatus(s.isEmpty ? null : s);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (data.viewState == ViewState.normal)
            ...data.authorizations.map((auth) {
              final status = auth['status'] as String? ?? '';
              final isPending = status == 'pending';
              final statusColor = switch (status) {
                'approved' => AppColors.success,
                'pending' => AppColors.warning,
                'revoked' => AppColors.danger,
                _ => AppColors.info,
              };
              final statusLabel = switch (status) {
                'approved' => '已通过',
                'pending' => '待审核',
                'revoked' => '已撤销',
                _ => status,
              };

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: HighfiCard(
                  key: Key('auth-${auth['id']}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              auth['tenantName'] as String? ?? '',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          HighfiStatusChip(
                            label: statusLabel,
                            color: statusColor,
                            icon: isPending
                                ? Icons.pending_outlined
                                : status == 'approved'
                                    ? Icons.check_circle_outline
                                    : Icons.cancel_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '请求权限: ${auth['requestedScope'] ?? ''}',
                      ),
                      if (auth['requestedAt'] != null)
                        Text('申请时间: ${auth['requestedAt']}'),
                      if (isPending)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              key: Key('approve-${auth['id']}'),
                              onPressed: () =>
                                  controller.approveAuthorization(
                                      auth['id'] as String),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('通过'),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            TextButton.icon(
                              key: Key('revoke-${auth['id']}'),
                              onPressed: () =>
                                  controller.revokeAuthorization(
                                      auth['id'] as String),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('拒绝'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            }),
          if (data.viewState == ViewState.empty)
            const SizedBox(
              height: 200,
              child: Center(child: Text('暂无授权申请')),
            ),
          if (data.viewState == ViewState.loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
