import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Device identity subtitle line shown in report panel headers (NIX-55).
///
/// Renders device EUI (monospace) and device code side by side with a copy
/// button. When [deviceEui] is empty, only [deviceCode] is shown.
class DeviceIdentityLine extends StatelessWidget {
  const DeviceIdentityLine({
    super.key,
    required this.deviceEui,
    required this.deviceCode,
    required this.l10n,
  });

  final String deviceEui;
  final String deviceCode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final hasEui = deviceEui.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasEui) ...[
            Text(
              '${l10n.gpsQualityDeviceEui}:',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              deviceEui,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            _CopyButton(text: deviceEui, l10n: l10n),
          ],
          if (deviceCode.isNotEmpty) ...[
            if (hasEui)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Text('·',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${l10n.gpsQualityDeviceCode}:',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                deviceCode,
                style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.text, required this.l10n});

  final String text;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: text));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.gpsQualityEuiCopied),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Icon(Icons.copy, size: 14, color: AppColors.textSecondary),
      ),
    );
  }
}
