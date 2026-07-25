import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Status chip for a feature gate, matching the prototype's 5-state chip.
/// none=success, limit=primary, lock(off)=danger, lock(on)=success, filter=info.
class GateStatusChip extends StatelessWidget {
  const GateStatusChip({super.key, required this.gateType, required this.isEnabled});

  final String? gateType;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, color) = _resolve(l10n);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  (String, Color) _resolve(AppLocalizations l10n) {
    final type = gateType?.toUpperCase();
    if (type == 'LIMIT') return (l10n.gateTypeLimit, AppColors.primary);
    if (type == 'FILTER') return (l10n.gateTypeFilter, AppColors.info);
    if (type == 'LOCK') {
      return isEnabled
          ? (l10n.gateTypeLockOpen, AppColors.success)
          : (l10n.gateTypeLock, AppColors.danger);
    }
    // NONE or unknown
    return (l10n.gateTypeNone, AppColors.success);
  }
}
