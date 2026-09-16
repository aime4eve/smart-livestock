import 'package:flutter/material.dart';

import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';

/// 导入向导共享壳（NIX-213）：三步指示器 + 内容骨架。
///
/// 抽出来是为了避免 GPS 质量模块那三份复制粘贴向导继续繁殖；
/// 旧向导暂不迁移（见设计 §6.3），仅新向导使用本壳。
class ImportWizardShell extends StatelessWidget {
  const ImportWizardShell({
    super.key,
    required this.step,
    required this.stepCount,
    required this.stepLabels,
    required this.child,
  }) : assert(stepLabels.length == stepCount);

  /// 0-based 当前步。
  final int step;
  final int stepCount;
  final List<String> stepLabels;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          key: const Key('import-wizard-step-indicator'),
          children: [
            for (var i = 0; i < stepCount; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i <= step
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
              _StepDot(index: i, active: i <= step),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (var i = 0; i < stepCount; i++)
              Expanded(
                child: Text(
                  stepLabels[i],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight:
                            i == step ? FontWeight.w700 : FontWeight.w400,
                        color: i == step
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.index, required this.active});

  final int index;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('import-wizard-dot-$index'),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: active ? AppColors.primary : AppColors.textSecondary,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
