import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/ai_anomaly/domain/anomaly_models.dart';
import 'package:hkt_livestock_agentic/features/ai_anomaly/presentation/anomaly_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// AI anomaly score card, embedded at the bottom of health detail pages.
/// Only renders when the subscription tier grants [FeatureFlags.healthScore].
class AnomalyScoreCard extends ConsumerWidget {
  const AnomalyScoreCard({super.key, required this.livestockId});
  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncScore = ref.watch(anomalyDetailProvider(livestockId));

    return asyncScore.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) => _buildCard(context, l10n, data),
    );
  }

  Widget _buildCard(
      BuildContext context, AppLocalizations l10n, AnomalyScoreData data) {
    final score = data.anomalyScore;

    // No meaningful data: show a muted placeholder.
    if (score <= 0.001) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.psychology_outlined,
                  size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.aiAnomalyNoData,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      );
    }

    final color = _scoreColor(score);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology, size: 18, color: color),
                    const SizedBox(width: 6),
                    Text(l10n.aiAnomalyTitle,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                 child: Text(
                   '${(score * 100).toStringAsFixed(1)}%',
                   // Score percentage
                   style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Type label
            _infoRow(l10n.aiAnomalyScoreLabel,
                _typeLabel(l10n, data.anomalyType)),
            if (data.nEff != null)
              _infoRow(l10n.aiAnomalyEffSamples, '${data.nEff}'),
            if (data.capabilityUsed != null)
              _infoRow(l10n.aiAnomalyAssessedAt, data.capabilityUsed!),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 0.7) return AppColors.danger;
    if (score > 0.001) return AppColors.warning;
    return AppColors.textSecondary;
  }

  String _typeLabel(AppLocalizations l10n, String type) {
    return switch (type) {
      'circadian_disruption' => l10n.aiAnomalyTypeCircadian,
      'abrupt_change' => l10n.aiAnomalyTypeAbrupt,
      'multivariate' => l10n.aiAnomalyTypeMultivariate,
      _ => l10n.aiAnomalyTypeNormal,
    };
  }
}
