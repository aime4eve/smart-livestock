import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_controller.dart';

class B2bContractPage extends ConsumerWidget {
  const B2bContractPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(b2bContractControllerProvider);
    final theme = Theme.of(context);

    if (data.id == null) {
      return const Center(child: Text('暂无合同信息'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('合同信息', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.lg),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _InfoRow(label: '合同编号', value: data.id!),
                  const Divider(),
                  _InfoRow(
                      label: '合同状态', value: _statusText(data.status)),
                  const Divider(),
                  _InfoRow(
                      label: '服务等级', value: _tierText(data.effectiveTier)),
                  const Divider(),
                  _InfoRow(
                    label: '分成比例',
                    value: data.revenueShareRatio != null
                        ? '${(data.revenueShareRatio! * 100).toStringAsFixed(0)}%'
                        : '-',
                  ),
                  const Divider(),
                  _InfoRow(
                      label: '签约人', value: data.signedBy ?? '-'),
                  const Divider(),
                  _InfoRow(
                    label: '生效日期',
                    value: data.startedAt != null
                        ? data.startedAt!.substring(0, 10)
                        : '-',
                  ),
                  const Divider(),
                  _InfoRow(
                    label: '到期日期',
                    value: data.expiresAt != null
                        ? data.expiresAt!.substring(0, 10)
                        : '-',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          Text(
            '合同为只读展示，如需变更请联系平台管理员。',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _statusText(String? status) => switch (status) {
        'active' => '生效中',
        'suspended' => '已暂停',
        'expired' => '已过期',
        _ => status ?? '-',
      };

  String _tierText(String? tier) => switch (tier) {
        'standard' => '标准版',
        'premium' => '高级版',
        'enterprise' => '企业版',
        _ => tier ?? '-',
      };
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
