import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';

class TwinSceneCard extends StatelessWidget {
  const TwinSceneCard({
    super.key,
    required this.icon,
    required this.title,
    required this.summary,
    this.alertLevel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String summary;
  final String? alertLevel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HighfiCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _AlertIndicator(level: alertLevel),
                const SizedBox(width: AppSpacing.md),
                Icon(icon, size: 24, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertIndicator extends StatelessWidget {
  const _AlertIndicator({this.level});

  final String? level;

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (level) {
      case 'critical':
        c = AppColors.danger;
        break;
      case 'warning':
        c = AppColors.warning;
        break;
      default:
        c = AppColors.primarySoft;
    }
    return Container(
      width: 4,
      constraints: const BoxConstraints(minHeight: 40),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
