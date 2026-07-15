import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/core/l10n/enum_labels.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class HighfiDeviceTile extends StatelessWidget {
  const HighfiDeviceTile({
   super.key,
   required this.device,
   this.onUnbind,
   this.onViewLocation,
   this.onActivate,
   this.onInstall,
 });

 final DeviceItem device;
 final VoidCallback? onUnbind;
 final VoidCallback? onViewLocation;
  final VoidCallback? onActivate;
 final VoidCallback? onInstall;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  _subtitle(l10n),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
               if (device.batteryPercent != null) ...[
                 const SizedBox(height: AppSpacing.xs),
                 _BatteryBar(percent: device.batteryPercent!),
               ],
               if (device.hasTamperAlert) ...[
                 const SizedBox(height: AppSpacing.xs),
                 Row(
                   children: [
                     Icon(Icons.warning, size: 14, color: AppColors.danger),
                     const SizedBox(width: 4),
                     Text('防拆卸告警',
                       style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.danger),
                     ),
                   ],
                 ),
               ],
               const SizedBox(height: AppSpacing.xs),
               Row(
                 children: [
                   Icon(
                     device.isPlatformRegistered ? Icons.cloud_done : Icons.cloud_off,
                     size: 14,
                     color: device.isPlatformRegistered ? AppColors.success : AppColors.textSecondary,
                   ),
                   const SizedBox(width: 4),
                   Text(
                     device.isPlatformRegistered ? '已注册平台' : '未注册平台',
                     style: Theme.of(context).textTheme.labelSmall?.copyWith(
                       color: device.isPlatformRegistered ? AppColors.success : AppColors.textSecondary,
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                 children: [
                   if (onActivate != null)
                     TextButton(
                       key: Key('device-activate-${device.id}'),
                       onPressed: onActivate,
                       child: Text(l10n.deviceActivate),
                     ),
                   if (onInstall != null)
                      TextButton(
                        key: Key('device-install-${device.id}'),
                        onPressed: onInstall,
                        child: Text(l10n.deviceInstallTo),
                      ),
                    if (onUnbind != null)
                      TextButton(
                        key: Key('device-unbind-${device.id}'),
                        onPressed: onUnbind,
                        child: Text(l10n.deviceUnbind),
                      ),
                    if (onViewLocation != null)
                      TextButton(
                        key: Key('device-locate-${device.id}'),
                        onPressed: onViewLocation,
                        child: Text(l10n.deviceViewLocation),
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
        DeviceType.earTag => Icons.tag,
      };

  Color get _statusColor => switch (device.status) {
        DeviceStatus.online => AppColors.success,
        DeviceStatus.offline => AppColors.textSecondary,
      };

 String _subtitle(AppLocalizations l10n) {
   final parts = <String>[
     device.boundLivestockCode,
     device.status.localizedLabel(l10n),
   ];
   if (device.rssi != null) parts.add('RSSI ${device.rssi}dBm');
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
