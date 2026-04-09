import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/permissions/role_permission.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/estrus/presentation/estrus_controller.dart';
import 'package:smart_livestock_demo/features/estrus/presentation/widgets/estrus_trend_chart.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';

class EstrusDetailPage extends ConsumerWidget {
  const EstrusDetailPage({super.key, required this.livestockId});

  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(estrusRepositoryProvider);
    final score = repo.loadDetail(livestockId);
    final role = ref.watch(sessionControllerProvider).role ?? DemoRole.worker;

    return Scaffold(
      appBar: AppBar(
        title: Text('牛#$livestockId 发情详情'),
      ),
      body: score == null
          ? const Center(child: Text('未找到个体数据'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HighfiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '当前评分 ${score.score}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(score.advice ?? ''),
                        const SizedBox(height: AppSpacing.md),
                        _MetricRow(
                          label: '步数增长',
                          value: '+${score.stepIncreasePercent}%',
                        ),
                        _MetricRow(
                          label: '体温变化',
                          value: '+${score.tempDelta}°C',
                        ),
                        _MetricRow(
                          label: '距离变化',
                          value: '+${score.distanceDelta}km',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  HighfiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '7天发情指数趋势',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        EstrusTrendChart(trend7d: score.trend7d),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  HighfiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '配种建议',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(score.advice ?? '—'),
                        const SizedBox(height: AppSpacing.md),
                        if (RolePermission.canTwinBreedingAction(role))
                          FilledButton(
                            key: const Key('estrus-mark-breeding'),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('已记录配种提醒（演示）')),
                              );
                            },
                            child: const Text('标记配种'),
                          )
                        else
                          const Tooltip(
                            message: '牧工账号仅可查看，配种操作需牧场主处理',
                            child: _EstrusBreedingDisabledButton(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _EstrusBreedingDisabledButton extends StatelessWidget {
  const _EstrusBreedingDisabledButton();

  @override
  Widget build(BuildContext context) {
    return const FilledButton(
      onPressed: null,
      child: Text('标记配种'),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
