import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/models/anomaly_models.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// AI anomaly score card for embedding in health detail pages.
///
/// Pure display widget — receives data from parent, no Riverpod dependency.
/// Renders a muted placeholder when [data] is null or score is negligible.
class AnomalyScoreCard extends StatelessWidget {
  const AnomalyScoreCard({super.key, required this.data});
  final AnomalyScoreData? data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (data == null || data!.anomalyScore <= 0.001) {
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

    final score = data!.anomalyScore;
    final color = _scoreColor(score);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(l10n.aiAnomalyScoreLabel,
                _typeLabel(l10n, data!.anomalyType)),
            if (data!.nEff != null)
              _infoRow(l10n.aiAnomalyEffSamples, '${data!.nEff}'),
            if (data!.capabilityUsed != null)
              _infoRow(l10n.aiAnomalyAssessedAt, data!.capabilityUsed!),
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
