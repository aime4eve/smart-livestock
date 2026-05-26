import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';

class HighfiStatusChip extends StatelessWidget {
  const HighfiStatusChip({
    super.key,
    required this.label,
    this.color = AppColors.accent,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  factory HighfiStatusChip.fromViewState({
    Key? key,
    required ViewState viewState,
  }) {
    switch (viewState) {
      case ViewState.normal:
        return HighfiStatusChip(
          key: key,
          label: '正常',
          color: AppColors.success,
          icon: Icons.check_circle_outline,
        );
      case ViewState.loading:
        return HighfiStatusChip(
          key: key,
          label: '加载中',
          color: AppColors.info,
          icon: Icons.sync,
        );
      case ViewState.empty:
        return HighfiStatusChip(
          key: key,
          label: '空状态',
          color: AppColors.accent,
          icon: Icons.inbox_outlined,
        );
      case ViewState.error:
        return HighfiStatusChip(
          key: key,
          label: '错误',
          color: AppColors.danger,
          icon: Icons.error_outline,
        );
      case ViewState.forbidden:
        return HighfiStatusChip(
          key: key,
          label: '无权限',
          color: AppColors.warning,
          icon: Icons.lock_outline_rounded,
        );
      case ViewState.offline:
        return HighfiStatusChip(
          key: key,
          label: '离线',
          color: AppColors.textSecondary,
          icon: Icons.cloud_off_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
