import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/fever_warning/presentation/fever_controller.dart';
import 'package:smart_livestock_demo/features/fever_warning/presentation/widgets/temperature_chart.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';

class FeverDetailPage extends ConsumerWidget {
  const FeverDetailPage({super.key, required this.livestockId});

  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(feverRepositoryProvider);
    final baseline = repo.loadDetail(livestockId);

    return Scaffold(
      appBar: AppBar(
        title: Text('牛#$livestockId 体温详情'),
      ),
      body: baseline == null
          ? const Center(child: Text('未找到个体数据'))
          : SingleChildScrollView(
              key: Key('page-twin-fever-detail-$livestockId'),
              padding: const EdgeInsets.all(16),
              child: _DetailBody(baseline: baseline),
            ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.baseline});

  final TemperatureBaseline baseline;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    switch (baseline.status) {
      case 'critical':
        statusColor = AppColors.danger;
        statusLabel = '紧急';
        break;
      case 'warning':
        statusColor = AppColors.warning;
        statusLabel = '异常';
        break;
      default:
        statusColor = AppColors.success;
        statusLabel = '正常';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HighfiCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前状态',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: statusColor,
                      ),
                    ),
                    Text(
                      baseline.conclusion ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '基线温度',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${baseline.baselineTemp.toStringAsFixed(1)}°C',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
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
                '72小时体温曲线',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              TemperatureChart(
                key: const Key('twin-fever-temperature-chart'),
                records: baseline.recent72h,
                baselineTemp: baseline.baselineTemp,
                threshold: baseline.threshold,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        HighfiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_outlined, color: AppColors.info),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'AI 判断',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                baseline.conclusion ?? '—',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
