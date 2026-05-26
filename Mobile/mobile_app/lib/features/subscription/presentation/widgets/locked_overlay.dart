import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';

class LockedOverlay extends StatelessWidget {
  final bool locked;
  final String? upgradeTier;
  final bool deviceLocked;
  final String? deviceMessage;
  final Widget child;
  final VoidCallback? onUpgrade;

  const LockedOverlay({
    super.key,
    required this.locked,
    this.upgradeTier,
    this.deviceLocked = false,
    this.deviceMessage,
    required this.child,
    this.onUpgrade,
  });

  String get _upgradeTierLabel {
    switch (upgradeTier) {
      case 'standard':
        return '标准版';
      case 'premium':
        return '高级版';
      case 'enterprise':
        return '企业版';
      default:
        return upgradeTier ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;

    final message = deviceLocked
        ? (deviceMessage ?? '该功能需要安装相应设备')
        : '该功能需要升级到$_upgradeTierLabel';

    return Stack(
      children: [
        Opacity(opacity: 0.35, child: child),
        Positioned.fill(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    deviceLocked ? Icons.devices_rounded : Icons.lock_outline,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  if (onUpgrade != null && !deviceLocked) ...[
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: onUpgrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surfaceAlt,
                      ),
                      child: Text('升级到$_upgradeTierLabel'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
