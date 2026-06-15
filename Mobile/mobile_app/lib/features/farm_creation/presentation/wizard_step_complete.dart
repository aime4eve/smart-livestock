import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class WizardStepComplete extends StatelessWidget {
  const WizardStepComplete({
    super.key,
    required this.farmName,
    required this.fenceCount,
    required this.onStart,
  });

  final String farmName;
  final int fenceCount;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      key: const Key('farm-creation-step3'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Icon(
            Icons.check_circle,
            size: 64,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '牧场创建成功！',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryRow(
                    label: '牧场名称',
                    value: farmName,
                  ),
                  if (fenceCount > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _SummaryRow(
                      label: '围栏数量',
                      value: '$fenceCount 个',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Spacer(),
          FilledButton(
            key: const Key('farm-creation-enter'),
            onPressed: onStart,
            child: Text(l10n.wizardEnterRanch),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}
