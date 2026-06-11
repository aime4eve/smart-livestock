import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';

/// A compact, low-key line showing device info (battery, signal).
///
/// Designed to be visually subdued — it must not compete with
/// alert content for the user's attention.
///
/// MVP: battery/signal are placeholder values until backend provides
/// real device status via `AlertDto.deviceStatus`.
class DeviceInfoLine extends StatelessWidget {
  const DeviceInfoLine({
    super.key,
    this.batteryLevel,
    this.signalStrength,
    this.deviceId,
  });

  final int? batteryLevel;
  final int? signalStrength;
  final String? deviceId;

  @override
  Widget build(BuildContext context) {
    // Don't render if no data at all
    if (batteryLevel == null && signalStrength == null && deviceId == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.devices, size: 12, color: AppColors.textSecondary.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          if (deviceId != null)
            Text(
              deviceId!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          if (batteryLevel != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              batteryLevel! > 50 ? Icons.battery_std : Icons.battery_alert,
              size: 12,
              color: batteryLevel! > 50
                  ? AppColors.textSecondary.withValues(alpha: 0.6)
                  : AppColors.warning.withValues(alpha: 0.7),
            ),
            Text(
              '$batteryLevel%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
          if (signalStrength != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              signalStrength! > 2 ? Icons.signal_cellular_alt : Icons.signal_cellular_0_bar,
              size: 12,
              color: signalStrength! > 2
                  ? AppColors.textSecondary.withValues(alpha: 0.6)
                  : AppColors.warning.withValues(alpha: 0.7),
            ),
          ],
        ],
      ),
    );
  }
}
