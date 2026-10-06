import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/epidemic/presentation/widgets/epidemic_upsell_sheet.dart';
import 'package:hkt_livestock_agentic/features/epidemic/presentation/widgets/mark_diseased_sheet.dart';
import 'package:hkt_livestock_agentic/features/epidemic/presentation/widgets/unmark_diseased_sheet.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/livestock_controller.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Two-state mark-diseased entry for the livestock detail page (spec §5.2
/// entry ①, prototype P1/P3):
///
/// - unmarked: one full-width danger button "🦠 标记疑似患病";
/// - marked: a danger-soft info bar (disease · duration / contacts) plus a
///   "查看疫病防控" neutral button and a "取消染病标记" ghost button.
///
/// Gating (spec §5.4): manager roles only (OWNER / B2B_ADMIN — others render
/// nothing); free-tier managers still see the unmarked button but tapping it
/// opens the P6 upsell sheet instead of the real flow. Removing an existing
/// mark stays available to any manager regardless of tier — it is cleanup,
/// not a premium capability.
class MarkDiseasedEntryRow extends ConsumerWidget {
  const MarkDiseasedEntryRow({super.key, required this.detail});

  final LivestockDetail detail;

  bool _isManagerRole(UserRole? role) =>
      role == UserRole.owner || role == UserRole.b2bAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(sessionControllerProvider).role;
    final isManager = _isManagerRole(role);
    final marked = detail.markedSource;
    if (marked == null) {
      // Spec §5.4: manager-only action — non-manager roles get no button.
      return isManager ? _buildUnmarkedRow(context, ref) : const SizedBox.shrink();
    }
    // Marked state: the info bar is informational and stays visible to all
    // roles; only the action buttons are manager-gated.
    return _buildMarkedRow(context, ref, marked, isManager);
  }

  // ── Unmarked state (prototype P1) ──────────────────────────────

  Widget _buildUnmarkedRow(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      key: const Key('mark-diseased-entry-button'),
      color: AppColors.danger,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _onMarkTapped(context, ref),
        child: SizedBox(
          // Prototype: btn height 36, radius-sm, 12/w700 white, full width.
          height: 36,
          child: Center(
            child: Text(
              l10n.markDiseasedEntryButton,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onMarkTapped(BuildContext context, WidgetRef ref) {
    final tier = ref.read(subscriptionControllerProvider).value?.tier ??
        SubscriptionTier.basic;
    if (!checkTierAccess(tier, FeatureFlags.epidemicAlert)) {
      // Free tier: guide to Premium instead of running the flow (P6).
      EpidemicUpsellSheet.show(context);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    MarkDiseasedSheet.show(
      context,
      livestockId: detail.livestockId,
      livestockCode: detail.livestockCode,
      subtitle: _genderSubtitle(l10n),
    ).then((_) => _refreshDetail(ref));
  }

  // ── Marked state (prototype P3) ────────────────────────────────

  Widget _buildMarkedRow(
    BuildContext context,
    WidgetRef ref,
    MarkedSourceInfo marked,
    bool isManager,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info bar: danger-soft bg, radius-sm, two caption lines.
        Container(
          key: const Key('mark-diseased-source-bar'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.dangerSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🦠 ${marked.diseaseType} · '
                '${l10n.markedSourceDuration(_durationLabel(l10n, marked.markedAt))}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.markedSourceContacts(marked.contactCount),
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (isManager) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _NeutralActionButton(
                  key: const Key('mark-diseased-view-workbench'),
                  label: l10n.viewWorkbenchButton,
                  onTap: () => context.push(
                    '/twin/epidemic?sourceLivestockId=${detail.livestockId}',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GhostActionButton(
                  key: const Key('mark-diseased-unmark'),
                  label: l10n.unmarkDiseasedButton,
                  onTap: () => _onUnmarkTapped(context, ref),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _onUnmarkTapped(BuildContext context, WidgetRef ref) {
    UnmarkDiseasedSheet.show(
      context,
      livestockId: detail.livestockId,
      livestockCode: detail.livestockCode,
    ).then((confirmed) {
      if (confirmed) _refreshDetail(ref);
    });
  }

  // ── Helpers ────────────────────────────────────────────────────

  void _refreshDetail(WidgetRef ref) {
    ref
        .read(livestockDetailControllerProvider(detail.livestockId).notifier)
        .silentRefresh();
  }

  String? _genderSubtitle(AppLocalizations l10n) {
    final gender = detail.gender;
    if (gender == null) return null;
    return gender.toUpperCase() == 'FEMALE'
        ? l10n.livestockGenderValueFemale
        : l10n.livestockGenderValueMale;
  }

  /// Chinese-style shorthand duration ("2 小时") following the project's
  /// minutes/hours/days ladder convention (see alert_card `_formatTime`).
  String _durationLabel(AppLocalizations l10n, DateTime markedAt) {
    final diff = DateTime.now().difference(markedAt);
    final minutes = diff.isNegative ? 0 : diff.inMinutes;
    if (minutes < 60) return l10n.durationMinutesShort(minutes);
    if (minutes < 24 * 60) return l10n.durationHoursShort(diff.inHours);
    return l10n.durationDaysShort(diff.inDays);
  }
}

/// Neutral action button (surface-muted bg / secondary text), height 36.
class _NeutralActionButton extends StatelessWidget {
  const _NeutralActionButton({super.key, required this.label, this.onTap});

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
          height: 36,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
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

/// Ghost action button (transparent bg / danger text / danger border).
class _GhostActionButton extends StatelessWidget {
  const _GhostActionButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.danger, width: 1.5),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
