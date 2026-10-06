import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/utils/currency_formatter.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Premium upsell sheet for the mark-diseased entry (spec §5.4, prototype
/// P6). Free-tier users tapping a mark-diseased action see this instead of
/// the real flow — the buttons stay visible so the feature remains
/// discoverable. Shared by the detail-page entry and (Task 7) the
/// workbench empty state and the epidemic alert action.
class EpidemicUpsellSheet extends StatelessWidget {
  const EpidemicUpsellSheet({super.key});

  /// Premium per-head monthly price used by the epidemic upsell copy
  /// (prototype P6 pins $2.65 / head / month).
  static const int premiumPriceUsdCents = 265;

  /// Opens the sheet; returns when it is dismissed.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Prototype scrim: rgba(38,49,38,.45).
      barrierColor: const Color(0x73263126),
      backgroundColor: AppColors.surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const EpidemicUpsellSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Captured before the sheet pops: the sheet's own context is stale
    // afterwards but the subscription route push must still happen.
    final router = GoRouter.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Grab handle: 36x4, border color, radius 2.
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Centered lock icon, 34px.
          const Icon(Icons.lock_outline, size: 34, color: AppColors.primaryDark),
          const SizedBox(height: 10),
          // Title: 16 / w800 primary-dark, centered.
          Text(
            l10n.upsellTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          // Two-line description, 11 / secondary / 1.7.
          Text(
            l10n.upsellBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              height: 1.7,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          // Price line reuses the shared per-head-month pricing copy.
          Text(
            l10n.subPerHeadMonth(formatUsdCents(premiumPriceUsdCents)),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          // Buttons: neutral dismiss + primary-dark learn-more, height 42.
          Row(
            children: [
              Expanded(
                child: _NeutralButton(
                  label: l10n.upsellLater,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PrimaryDarkButton(
                  label: l10n.upsellLearnMore,
                  onTap: () {
                    Navigator.of(context).pop();
                    router.go(AppRoute.subscription.path);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Neutral action button (surface-muted bg / secondary text), height 42.
class _NeutralButton extends StatelessWidget {
  const _NeutralButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          height: 42,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary-dark action button (primary-dark bg / white text), height 42.
class _PrimaryDarkButton extends StatelessWidget {
  const _PrimaryDarkButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryDark,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          height: 42,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
