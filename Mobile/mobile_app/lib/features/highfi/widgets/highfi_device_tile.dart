import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';

class HighfiDeviceTile extends StatelessWidget {
  const HighfiDeviceTile({
    super.key,
    required this.device,
    this.onUnbind,
    this.onViewLocation,
  });

  final DeviceItem device;
  final VoidCallback? onUnbind;
  final VoidCallback? onViewLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('device-tile-${device.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _typeIcon,
            size: 28,
            color: _statusColor,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (device.batteryPercent != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _BatteryBar(percent: device.batteryPercent!),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (onUnbind != null)
                      TextButton(
                        key: Key('device-unbind-${device.id}'),
                        onPressed: onUnbind,
                        child: const Text('解绑'),
                      ),
                    if (onViewLocation != null)
                      TextButton(
                        key: Key('device-locate-${device.id}'),
                        onPressed: onViewLocation,
                        child: const Text('查看位置'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData get _typeIcon => switch (device.type) {
        DeviceType.gps => Icons.gps_fixed,
        DeviceType.rumenCapsule => Icons.medication,
        DeviceType.accelerometer => Icons.speed,
      };

  Color get _statusColor => switch (device.status) {
        DeviceStatus.online => AppColors.success,
        DeviceStatus.offline => AppColors.textSecondary,
        DeviceStatus.lowBattery => AppColors.warning,
      };

  String get _subtitle {
    final parts = <String>[
      device.boundEarTag,
      switch (device.status) {
        DeviceStatus.online => '在线',
        DeviceStatus.offline => '离线',
        DeviceStatus.lowBattery => '低电',
      },
    ];
    if (device.signalStrength != null) parts.add('信号${device.signalStrength}');
    if (device.lastSync != null) parts.add('同步 ${device.lastSync}');
    return parts.join(' · ');
  }
}

class _BatteryBar extends StatelessWidget {
  const _BatteryBar({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final color = percent > 50
        ? AppColors.success
        : percent > 20
            ? AppColors.warning
            : AppColors.danger;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$percent%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
        const SizedBox(width: AppSpacing.xs),
        Container(
          width: 60,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percent / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
