import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/digestive/presentation/digestive_controller.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class DigestivePage extends ConsumerWidget {
  const DigestivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncList = ref.watch(digestiveListControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.digestiveTitle), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.commonLoadFailed}: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text(l10n.digestiveNoData, style: const TextStyle(fontSize: 16)));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(digestiveListControllerProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: items.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) => _DigestiveCard(item: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _DigestiveCard extends StatelessWidget {
  const _DigestiveCard({required this.item});
  final DigestiveListItem item;

  Color _statusColor() {
    switch (item.status) {
      case 'ABNORMAL': return AppColors.danger;
      case 'LOW': return AppColors.warning;
      default: return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _statusColor();
    final dropPercent = item.motilityBaseline > 0
        ? ((1 - item.currentFrequency / item.motilityBaseline) * 100).round()
        : 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: color.withOpacity(0.3))),
      child: ListTile(
        leading: Icon(item.status == 'ABNORMAL' ? Icons.error : Icons.warning, color: color, size: 28),
        title: Text(item.livestockCode, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(l10n.digestiveItemSubtitle(item.breed ?? '', item.currentFrequency.toStringAsFixed(1), dropPercent.toString())),
        trailing: Chip(label: Text(item.status, style: const TextStyle(fontSize: 11)), backgroundColor: color.withOpacity(0.15)),
        onTap: () => context.push('/twin/digestive/${item.livestockId}'),
      ),
    );
  }
}
