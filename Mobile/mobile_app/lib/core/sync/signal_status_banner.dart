import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_sync_controller.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class SignalSyncStatusBanner extends ConsumerWidget {
  const SignalSyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signalSyncControllerProvider);
    if (!state.stale) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    // A permission denial is not an outage: it neither recovers on its own
    // nor changes on retry, so the banner says so and offers no retry.
    if (state.forbidden) {
      return _banner(
        icon: Icons.lock_outline,
        message: l10n.signalSyncForbidden,
      );
    }

    return _banner(
      icon: Icons.sync_problem,
      message: l10n.signalSyncStale,
      action: TextButton(
        onPressed: () =>
            ref.read(signalSyncControllerProvider.notifier).refreshNow(),
        child: Text(l10n.signalSyncRetry),
      ),
    );
  }

  Widget _banner({
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    return Material(
      color: AppColors.warningSoft,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.warningStrong),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warningStrong,
                ),
              ),
            ),
            if (action != null) action,
          ],
        ),
      ),
    );
  }
}
