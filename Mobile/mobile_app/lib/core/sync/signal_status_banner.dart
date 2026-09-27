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

    return Material(
      color: AppColors.warningSoft,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.sync_problem,
              size: 14,
              color: AppColors.warningStrong,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.signalSyncStale,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warningStrong,
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(signalSyncControllerProvider.notifier).refreshNow(),
              child: Text(l10n.signalSyncRetry),
            ),
          ],
        ),
      ),
    );
  }
}
