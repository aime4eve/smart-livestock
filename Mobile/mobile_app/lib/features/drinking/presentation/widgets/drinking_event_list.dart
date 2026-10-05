import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_models.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/drinking_controller.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/widgets/drinking_manual_sheet.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Whether the current role may write drinking labels / manual events
/// (spec §15.2: OWNER / B2B_ADMIN / WORKER — same three-role convention as
/// PhysiologyEventController; the server re-validates).
bool canWriteDrinkingLabel(UserRole? role) {
  return role == UserRole.owner ||
      role == UserRole.b2bAdmin ||
      role == UserRole.worker;
}

/// Today's drinking event rows with the marking loop (NIX-256 4b, spec
/// §15.2): time + temp drop + confidence + label chip + confirm / reject
/// actions; low-confidence rows get the orange "needs verification" badge;
/// ALGORITHM_CANDIDATE rows group under the "to be marked" heading. Row
/// interactions are an addition beyond the frozen prototype — lightweight
/// styling, no extra screen.
class DrinkingEventList extends ConsumerWidget {
  const DrinkingEventList({
    super.key,
    required this.livestockId,
    required this.events,
    this.onActionFailed,
  });

  final String livestockId;
  final List<DrinkingEvent> events;

  /// Called when a PATCH / manual POST fails with a non-API error so the
  /// hosting section can show a generic SnackBar.
  final VoidCallback? onActionFailed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final role = ref.watch(sessionControllerProvider.select((s) => s.role));
    final canWrite = canWriteDrinkingLabel(role);

    final today = DateTime.now();
    final todayEvents = events
        .where((e) {
          final local = e.eventStartAt.toLocal();
          return local.year == today.year &&
              local.month == today.month &&
              local.day == today.day;
        })
        .toList()
      ..sort((a, b) => b.eventStartAt.compareTo(a.eventStartAt));
    final candidates = todayEvents.where((e) => e.isCandidate).toList();
    final counted = todayEvents.where((e) => !e.isCandidate).toList();

    if (todayEvents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          l10n.healthDrinkingNoEventsToday,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (candidates.isNotEmpty) ...[
          Text(
            l10n.healthDrinkingPendingGroupTitle(candidates.length),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          for (final (i, e) in candidates.indexed)
            _EventRow(
              event: e,
              canWrite: canWrite,
              isLast: i == candidates.length - 1,
              onMark: (label) => _mark(context, ref, e.id, label),
            ),
          const SizedBox(height: 8),
        ],
        if (counted.isNotEmpty) ...[
          Text(
            l10n.healthDrinkingEventListTitle(counted.length),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          for (final (i, e) in counted.indexed)
            _EventRow(
              event: e,
              canWrite: canWrite,
              isLast: i == counted.length - 1,
              onMark: (label) => _mark(context, ref, e.id, label),
            ),
        ],
        if (canWrite) ...[
          const SizedBox(height: 9),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              key: const Key('drinking-add-manual'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => showDrinkingManualSheet(context, livestockId),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Text(
                  l10n.healthDrinkingAddManual,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _mark(
    BuildContext context,
    WidgetRef ref,
    int eventId,
    DrinkingLabel label,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(drinkingEventsControllerProvider(livestockId).notifier)
          .markLabel(eventId: eventId, label: label);
      // markLabel refreshed rows + summaries; success is visible in the
      // updated chip, no extra toast needed (lightweight 4b style).
    } on ApiException catch (e) {
      // Server-side i18n message (role check / validation / conflict).
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } catch (_) {
      // Never leak raw technical strings (lesson #25).
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.healthDrinkingSaveFailed)),
      );
    }
  }
}

/// One event row: time (HH:mm) + temp drop + confidence + label chip +
/// confirm / reject mini buttons. Low-confidence rows add the orange
/// "needs verification" badge; manual rows add a small "back-filled" chip.
class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.canWrite,
    required this.isLast,
    required this.onMark,
  });

  final DrinkingEvent event;
  final bool canWrite;
  final bool isLast;
  final void Function(DrinkingLabel label) onMark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final local = event.eventStartAt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');

    // Two-line layout: time + drop + confidence + label chip on the first
    // row, badges + actions right-aligned on the second. The single-row
    // variant overflowed by ~14px once "待核实"/补录 chips joined the
    // confirm/reject buttons at 390px width.
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$hh:$mm',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              if (event.tempDrop != null)
                Text(
                  '−${event.tempDrop!.toStringAsFixed(1)}°C',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.drinkingEvent,
                  ),
                ),
              const SizedBox(width: 6),
              if (event.confidence != null)
                Text(
                  event.confidence!.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              const Spacer(),
              _labelChip(l10n),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              if (event.needsVerification) ...[
                _needsVerificationChip(l10n),
                const SizedBox(width: 4),
              ],
              if (event.isManual) ...[
                _sourceChip(l10n.healthDrinkingSourceManual),
                const SizedBox(width: 4),
              ],
              const Spacer(),
              if (canWrite) ...[
                _actionButton(
                  key: Key('drinking-confirm-${event.id}'),
                  label: l10n.healthDrinkingConfirm,
                  foreground: AppColors.success,
                  onTap: () => onMark(DrinkingLabel.confirmed),
                ),
                const SizedBox(width: 4),
                _actionButton(
                  key: Key('drinking-reject-${event.id}'),
                  label: l10n.healthDrinkingReject,
                  foreground: AppColors.danger,
                  onTap: () => onMark(DrinkingLabel.rejected),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Orange "待核实" badge for confidence < 0.5 (spec §15.2).
  Widget _needsVerificationChip(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.fever.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        l10n.healthDrinkingNeedsVerification,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: AppColors.fever,
        ),
      ),
    );
  }

  Widget _sourceChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _labelChip(AppLocalizations l10n) {
    final (text, color) = switch (event.label) {
      DrinkingLabel.confirmed => (
        l10n.healthDrinkingLabelConfirmed,
        AppColors.success,
      ),
      DrinkingLabel.rejected => (
        l10n.healthDrinkingLabelRejected,
        AppColors.textSecondary,
      ),
      DrinkingLabel.unlabeled => ('', AppColors.textSecondary),
    };
    if (event.label == DrinkingLabel.unlabeled) {
      return _sourceChip(l10n.healthDrinkingLabelUnlabeled);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _actionButton({
    required Key key,
    required String label,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: foreground.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
