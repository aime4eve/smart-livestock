import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Premium locked-overlay for the drinking peer comparison (NIX-256,
/// prototype screen 5 / spec-cards drinking-states-and-extras.md §三):
/// dimmed blurred content (opacity .28 + blur 1px) + centered lock message
/// with upgrade button + "Premium+" tier badge.
class UpgradeOverlay extends StatelessWidget {
  const UpgradeOverlay({
    super.key,
    required this.child,
    this.onUpgrade,
  });

  /// The dimmed placeholder content behind the lock message.
  final Widget child;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        // .dim: opacity .28 + filter blur(1px)
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
          child: Opacity(opacity: 0.28, child: child),
        ),
        // .tier-badge: absolute top 8 right 8
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              l10n.healthDrinkingTierBadge,
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        // .lock-msg: absolute inset 0, column center, gap 6
        Positioned.fill(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔒', style: TextStyle(fontSize: 22)),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.healthDrinkingLockedMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    key: const Key('drinking-upgrade-btn'),
                    borderRadius: BorderRadius.circular(6),
                    onTap: onUpgrade,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      child: Text(
                        l10n.healthDrinkingUpgrade,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
