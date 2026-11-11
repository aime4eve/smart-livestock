import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alerts_repository.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// NIX-286: confirm/reject estrus feedback actions for ESTRUS alerts.
///
/// Renders the "确认发情 / 不是发情" button pair, guards the submission
/// behind a confirmation dialog (mistouch protection), submits the verdict
/// through [onSubmit], and surfaces the outcome via SnackBar — with distinct
/// copy for confirmed / rejected / idempotent repeats.
///
/// Error surfacing follows the established pattern (physiology/drinking
/// sheets): [ApiException].toString() is the server-side i18n message and is
/// shown as-is; any other failure (network, timeout) shows a generic l10n
/// message so raw exception strings never leak to the user (lesson #25).
///
/// Button visibility is judged purely by alert type + actionable status at
/// the call site (same condition as dismiss): the backend has no
/// feedback-status query endpoint yet (NIX-286 T2 scope), so this widget
/// hides itself locally after a successful submission and the buttons reappear
/// on the next sheet open. NIX-156 (calibration) will add the read-back
/// endpoint, after which the recorded verdict can be rendered instead.
class EstrusFeedbackActions extends StatefulWidget {
  const EstrusFeedbackActions({
    super.key,
    required this.alertId,
    required this.onSubmit,
    this.enabled = true,
  });

  final String alertId;

  /// Mirrors each surface's dismiss permission handling: the workbench shows
  /// the dismiss button disabled without permission, the legacy ranch sheet
  /// hides it — call sites apply their own gate and pass it here.
  final bool enabled;

  /// Submits the verdict and resolves with the server result. Failures must
  /// be thrown (not returned) so the error branch can surface them; the
  /// caller resolves the farm id and refreshes its own data if needed.
  final Future<AlertFeedbackResult> Function(
    String alertId, {
    required bool confirmed,
  })
  onSubmit;

  @override
  State<EstrusFeedbackActions> createState() => _EstrusFeedbackActionsState();
}

class _EstrusFeedbackActionsState extends State<EstrusFeedbackActions> {
  bool _submitting = false;

  /// Local "already fed back" marker: after a successful submission the whole
  /// action row disappears (no read-back endpoint in this iteration — see the
  /// class doc for the NIX-156 follow-up).
  bool _submitted = false;

  Future<void> _submit(bool confirmed) async {
    if (_submitting || !widget.enabled) return;
    final l10n = AppLocalizations.of(context)!;
    final approved = await _showConfirmDialog(l10n, confirmed);
    if (!approved || !mounted) return;
    setState(() => _submitting = true);
    try {
      final result = await widget.onSubmit(
        widget.alertId,
        confirmed: confirmed,
      );
      if (!mounted) return;
      setState(() => _submitted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.idempotent
                ? l10n.alertEstrusFeedbackDoneDuplicate
                : result.verdict == 'REJECTED'
                ? l10n.alertEstrusFeedbackDoneRejected
                : l10n.alertEstrusFeedbackDoneConfirmed,
          ),
        ),
      );
    } on ApiException catch (e) {
      // Backend 400/403/404: toString() returns the server-side i18n message,
      // safe to show as-is.
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } catch (_) {
      // Network/timeout and other non-API failures must not leak raw
      // technical strings (lesson #25) — show a generic message instead.
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.alertEstrusFeedbackFailed)));
      }
    }
  }

  Future<bool> _showConfirmDialog(AppLocalizations l10n, bool confirmed) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          confirmed
              ? l10n.alertEstrusFeedbackConfirmTitle
              : l10n.alertEstrusFeedbackRejectTitle,
        ),
        content: Text(
          confirmed
              ? l10n.alertEstrusFeedbackConfirmBody
              : l10n.alertEstrusFeedbackRejectBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Buttons disappear once a verdict was accepted (local-only state until
    // NIX-156 adds the feedback read-back endpoint).
    if (_submitted) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            context,
            key: Key('estrus-confirm-${widget.alertId}'),
            label: l10n.alertEstrusFeedbackConfirmAction,
            color: AppColors.estrus,
            foreground: Colors.white,
            onTap: _submitting || !widget.enabled ? null : () => _submit(true),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _actionButton(
            context,
            key: Key('estrus-reject-${widget.alertId}'),
            label: l10n.alertEstrusFeedbackRejectAction,
            color: AppColors.surfaceAlt,
            foreground: AppColors.textPrimary,
            border: true,
            onTap: _submitting || !widget.enabled ? null : () => _submit(false),
          ),
        ),
      ],
    );
  }

  /// Buttons follow the workbench action bar style: height 32, radius 9,
  /// 10px/w900 label — a spinner replaces the label while submitting.
  Widget _actionButton(
    BuildContext context, {
    required Key key,
    required String label,
    required Color color,
    required Color foreground,
    required VoidCallback? onTap,
    bool border = false,
  }) {
    return SizedBox(
      key: key,
      height: 32,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
            side: border
                ? const BorderSide(color: AppColors.border)
                : BorderSide.none,
          ),
        ),
        child: _submitting
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            : Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: foreground,
                ),
              ),
      ),
    );
  }
}
