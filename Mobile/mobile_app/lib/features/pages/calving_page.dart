import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/utils/app_time.dart';
import 'package:hkt_livestock_agentic/features/calving/presentation/calving_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Calving prediction list (NIX-389), cloned from the estrus page structure.
/// The server gates the endpoint; a 403 surfaces as the load-failed state.
class CalvingPage extends ConsumerWidget {
  const CalvingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncList = ref.watch(calvingListControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.calvingPredictionTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.commonLoadFailed}: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(
                l10n.calvingNoData,
                style: const TextStyle(fontSize: 16),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(calvingListControllerProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: items.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) =>
                  _CalvingCard(item: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _CalvingCard extends StatelessWidget {
  const _CalvingCard({required this.item});

  final CalvingPredictionItem item;

  /// Alert band (>= 70) renders in the danger colour, watch band (50-69) in
  /// the warning colour — both signal attention, unlike the estrus page.
  Color _scoreColor() {
    if (item.riskScore >= 70) return AppColors.danger;
    if (item.riskScore >= 50) return AppColors.warning;
    return AppColors.textSecondary;
  }

  /// Expected calving window in local time; any missing end renders as "—".
  String _windowText() {
    final start = item.expectedWindowStart;
    final end = item.expectedWindowEnd;
    if (start == null && end == null) return '—';
    if (start != null && end != null) {
      return '${formatMdhm(start)} ~ ${formatMdhm(end)}';
    }
    return formatMdhm(start ?? end!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _scoreColor();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            '${item.riskScore}',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ),
        title: Text(
          item.livestockCode,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${l10n.calvingRiskScore}: ${item.riskScore}',
              style: TextStyle(fontSize: 11, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              '${l10n.calvingWindow}: ${_windowText()}',
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              item.predictedAt != null
                  ? '${l10n.calvingPredictedAt}: ${formatMdhm(item.predictedAt!)}'
                  : '${l10n.calvingPredictedAt}: —',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
