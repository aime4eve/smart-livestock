import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

enum RefreshHintState { ok, refreshing, paused }

/// Thin strip under the summary header announcing the 30s auto-refresh.
class RefreshHint extends StatelessWidget {
  const RefreshHint({super.key, this.state = RefreshHintState.ok});

  final RefreshHintState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = switch (state) {
      RefreshHintState.refreshing => l10n.alertRefreshHint,
      RefreshHintState.paused => l10n.alertRefreshPaused,
      RefreshHintState.ok => '${l10n.alertRefreshHint} · ${l10n.alertRefreshedJustNow}',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state == RefreshHintState.refreshing)
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.2,
                color: AppColors.success,
              ),
            )
          else
            Icon(
              state == RefreshHintState.paused ? Icons.pause_circle_outline : Icons.sync,
              size: 10,
              color: AppColors.textSecondary,
            ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 8, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
