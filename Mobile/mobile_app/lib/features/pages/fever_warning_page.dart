import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/features/fever_warning/presentation/fever_controller.dart';
import 'package:smart_livestock_demo/core/models/health_models.dart';
import 'package:smart_livestock_demo/l10n/gen/app_localizations.dart';

class FeverWarningPage extends ConsumerWidget {
  const FeverWarningPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncList = ref.watch(feverListControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.feverWarningTitle), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text(l10n.commonLoadFailed, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('$e', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.read(feverListControllerProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text(l10n.feverNoData, style: const TextStyle(fontSize: 16)));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(feverListControllerProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: items.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) => _FeverCard(item: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _FeverCard extends StatelessWidget {
  const _FeverCard({required this.item});
  final FeverListItem item;

  Color _statusColor() {
    switch (item.status) {
      case 'CRITICAL': return AppColors.danger;
      case 'FEVER': return AppColors.warning;
      case 'ELEVATED': return AppColors.info;
      default: return AppColors.success;
    }
  }

  IconData _statusIcon() {
    switch (item.status) {
      case 'CRITICAL': return Icons.error;
      case 'FEVER': return Icons.warning;
      default: return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: color.withOpacity(0.3))),
      child: ListTile(
        leading: Icon(_statusIcon(), color: color, size: 28),
        title: Text(item.livestockCode, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${item.breed ?? ""}  ${item.currentTemp.toStringAsFixed(1)}°C  ▲+${item.delta.toStringAsFixed(1)}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Text(item.status, style: TextStyle(fontSize: 11, color: color)),
        ),
        onTap: () => context.push('/twin/fever/${item.livestockId}'),
      ),
    );
  }
}
