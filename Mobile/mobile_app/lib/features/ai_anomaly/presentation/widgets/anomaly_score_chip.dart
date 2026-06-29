import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/ai_anomaly/presentation/anomaly_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Compact AI anomaly score chip for list rows.
/// Renders nothing when score is negligible (< 0.001).
class AnomalyScoreChip extends ConsumerWidget {
  const AnomalyScoreChip({super.key, required this.livestockId});
  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncScore = ref.watch(anomalyDetailProvider(livestockId));

    return asyncScore.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final score = data.anomalyScore;
        if (score <= 0.001) return const SizedBox.shrink();

        final l10n = AppLocalizations.of(context)!;
        final color = score >= 0.7 ? AppColors.danger : AppColors.warning;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.psychology, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                '${l10n.aiAnomalyScoreLabel}: ${(score * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}
