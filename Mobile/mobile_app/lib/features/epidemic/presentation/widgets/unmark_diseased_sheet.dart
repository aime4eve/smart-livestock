import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/epidemic/presentation/epidemic_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Second-step confirmation sheet for removing a disease mark (spec §5.1,
/// prototype P3): the copy must state that unfinished dispositions sourced
/// by this livestock are cancelled together (backend `cancelActiveBySource`).
///
/// Performs the DELETE itself and pops with `true` on success so the caller
/// can refresh the detail page; errors keep the sheet open for retry.
class UnmarkDiseasedSheet extends ConsumerStatefulWidget {
  const UnmarkDiseasedSheet({
    super.key,
    required this.livestockId,
    required this.livestockCode,
  });

  final String livestockId;
  final String livestockCode;

  static Future<bool> show(
    BuildContext context, {
    required String livestockId,
    required String livestockCode,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      // Prototype scrim: rgba(38,49,38,.45).
      barrierColor: const Color(0x73263126),
      backgroundColor: AppColors.surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => UnmarkDiseasedSheet(
        livestockId: livestockId,
        livestockCode: livestockCode,
      ),
    ).then((confirmed) => confirmed ?? false);
  }

  @override
  ConsumerState<UnmarkDiseasedSheet> createState() => _UnmarkDiseasedSheetState();
}

class _UnmarkDiseasedSheetState extends ConsumerState<UnmarkDiseasedSheet> {
  bool _busy = false;

  Future<void> _confirm() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    // Captured before awaiting: the sheet's context is stale after popping.
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(epidemicRepositoryProvider)
          .unmarkDiseased(widget.livestockId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      messenger.showSnackBar(SnackBar(content: Text(l10n.unmarkDone)));
    } catch (_) {
      // Keep the sheet open so the user can retry; never surface the raw
      // exception text to the user (AGENTS #25).
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.markDiseasedFailedTryAgain)),
      );
    } finally {
      // Busy guard MUST reset on every path — a leaked busy flag leaves
      // the confirm button disabled forever (Task 5 lesson).
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          // Title: 15 / w700, centered.
          Text(
            l10n.unmarkConfirmTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          // Body: 11 / secondary / 1.7, centered.
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Text(
              l10n.unmarkConfirmBody(widget.livestockCode),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                height: 1.7,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          // Buttons: keep-mark (neutral) / confirm-removal (danger), height 42.
          Row(
            children: [
              Expanded(
                child: _NeutralButton(
                  label: l10n.unmarkKeep,
                  onTap: _busy ? null : () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DangerButton(
                  label: l10n.unmarkConfirm,
                  busy: _busy,
                  onTap: _confirm,
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

/// Destructive confirm button (danger bg / white text) with an in-flight
/// spinner guard.
class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = !busy;
    return Opacity(
      opacity: active ? 1 : 0.45,
      child: Material(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: active ? onTap : null,
          child: SizedBox(
            height: 42,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
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
      ),
    );
  }
}
