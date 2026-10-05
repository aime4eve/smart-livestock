import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_models.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/drinking_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Shared five-state widgets (NIX-256 spec §3.3, prototype screen 3) used
/// by both the DrinkingCard and the DrinkingDetailSection.

/// Which state-card variant to render.
enum DrinkingStateVariant { noData, building }

/// state-card: big emoji (fs26) + title (fs12 fw700) + description (fs10
/// secondary) + chip (muted for noData, drinking progress for building),
/// centered, padding 18×12, gap 8.
class DrinkingStateCard extends StatelessWidget {
  const DrinkingStateCard({
    super.key,
    required this.variant,
    this.sampleDays = 0,
  });

  final DrinkingStateVariant variant;

  /// Baseline sample days accumulated so far (drives the building chip
  /// "n / 3 天").
  final int sampleDays;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (emoji, title, desc, chipText, chipDrinking) = switch (variant) {
      DrinkingStateVariant.noData => (
        '📭',
        l10n.healthDrinkingStateNoData,
        l10n.healthDrinkingNoDataDesc,
        l10n.healthDrinkingNoDataChip,
        false,
      ),
      DrinkingStateVariant.building => (
        '🧮',
        l10n.healthDrinkingStateBuilding,
        l10n.healthDrinkingBuildingDesc(sampleDays, kDrinkingBaselineMinDays),
        l10n.healthDrinkingBuildingChip(sampleDays, kDrinkingBaselineMinDays),
        true,
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              // chip.drinking: bg --drinking-soft + --drinking text;
              // chip.muted: bg --surface + border --border.
              color: chipDrinking ? AppColors.drinkingSoft : AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: chipDrinking
                  ? null
                  : Border.all(color: AppColors.border, width: 1),
            ),
            child: Text(
              chipText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: chipDrinking ? AppColors.drinking : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading skeleton (prototype screen 3): bignum area 56×26 + unit 48×10 +
/// three shrinking lines (100% / 88% / 64%, h10 r5) with the 1.2s infinite
/// shimmer gradient.
class DrinkingSkeletonBlock extends StatefulWidget {
  const DrinkingSkeletonBlock({super.key});

  @override
  State<DrinkingSkeletonBlock> createState() => _DrinkingSkeletonBlockState();
}

class _DrinkingSkeletonBlockState extends State<DrinkingSkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _shimmer(width: 56, height: 26),
                  const SizedBox(width: 8),
                  _shimmer(width: 48, height: 10),
                ],
              ),
            ),
            for (final factor in const [1.0, 0.88, 0.64])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: FractionallySizedBox(
                  widthFactor: factor,
                  child: _shimmer(height: 10),
                ),
              ),
          ],
        );
      },
    );
  }

  /// skeleton-line: h10 r5, gradient surface → #ECE9E1 → surface with a
  /// 1.2s sweep (CSS background-position 200% → -200%).
  Widget _shimmer({double? width, double height = 10}) {
    final dx = 2.0 - 4.0 * _controller.value;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: LinearGradient(
          colors: const [
            AppColors.surface,
            Color(0xFFECE9E1),
            AppColors.surface,
          ],
          stops: const [0.25, 0.5, 0.75],
          transform: _GradientTranslation(dx),
        ),
      ),
    );
  }
}

/// Horizontal gradient translation in width fractions (the SDK only ships
/// [GradientRotation]; the skeleton sweep needs a linear slide, mirroring
/// the CSS `background-position` animation).
class _GradientTranslation extends GradientTransform {
  const _GradientTranslation(this.dx);

  final double dx;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx * bounds.width, 0, 0);
  }
}

/// Red error block (err-card): ⚠️ title fs12 fw700 --danger + description +
/// retry button (bg --danger, #fff, r6, padding 5×14). Only for interface
/// 5xx/timeout — distinct from the neutral yellow backfill state.
class DrinkingErrorBlock extends ConsumerWidget {
  const DrinkingErrorBlock({super.key, required this.livestockId});

  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚠️ ${l10n.healthDrinkingStateError}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.danger,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          l10n.healthDrinkingErrorDesc,
          style: const TextStyle(
            fontSize: 10,
            height: 1.55,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 7),
        Material(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            key: const Key('drinking-retry'),
            borderRadius: BorderRadius.circular(6),
            onTap: () => ref
                .read(drinkingSummaryControllerProvider(livestockId).notifier)
                .refresh(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              child: Text(
                l10n.healthDrinkingRetry,
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
    );
  }
}
