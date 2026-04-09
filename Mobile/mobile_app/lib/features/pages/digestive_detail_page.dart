import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/digestive/presentation/digestive_controller.dart';
import 'package:smart_livestock_demo/features/digestive/presentation/widgets/motility_chart.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';

class DigestiveDetailPage extends ConsumerWidget {
  const DigestiveDetailPage({super.key, required this.livestockId});

  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(digestiveRepositoryProvider);
    final health = repo.loadDetail(livestockId);

    return Scaffold(
      appBar: AppBar(
        title: Text('牛#$livestockId 消化详情'),
      ),
      body: health == null
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
                          '当前状态',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          health.status == 'critical'
                              ? '蠕动停止'
                              : (health.status == 'warning' ? '蠕动下降' : '正常'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '蠕动基线 ${health.motilityBaseline.toStringAsFixed(1)} 次/分',
                          style: Theme.of(context).textTheme.bodySmall,
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
                          '24小时蠕动趋势',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        MotilityChart(
                          key: const Key('twin-digestive-motility-chart'),
                          records: health.recent24h,
                          baseline: health.motilityBaseline,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  HighfiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '建议操作',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(health.advice ?? '—'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
