import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/features/epidemic/presentation/epidemic_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class EpidemicPage extends ConsumerWidget {
  const EpidemicPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(epidemicControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.epidemicTitle), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.commonLoadFailed}: $e')),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.read(epidemicControllerProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildMetricsSection(context, data),
              const SizedBox(height: 16),
              _buildContactsSection(context, data),
              const SizedBox(height: 16),
              _buildRiskCard(context, data),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsSection(BuildContext context, EpidemicData data) {
    final l10n = AppLocalizations.of(context)!;
    final m = data.metrics;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.epidemicHerdHealth, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Row(children: [
        _metricCard(l10n.epidemicAvgTemperature, '${m.avgTemperature.toStringAsFixed(2)}°C', AppColors.info),
        const SizedBox(width: 8),
        _metricCard(l10n.epidemicAbnormalRate, '${(m.abnormalRate * 100).toStringAsFixed(1)}%', m.abnormalRate > 0.15 ? AppColors.danger : m.abnormalRate > 0.05 ? AppColors.warning : AppColors.success),
        const SizedBox(width: 8),
        _metricCard(l10n.epidemicAbnormalCount, '${m.abnormalCount}头', AppColors.warning),
      ]),
    ]);
  }

  Widget _metricCard(String label, String value, Color color) {
    return Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
      Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    ]))));
  }

  Widget _buildContactsSection(BuildContext context, EpidemicData data) {
    final l10n = AppLocalizations.of(context)!;
    if (data.contacts.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.epidemicContactTracing, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...data.contacts.map((c) => Card(
        margin: const EdgeInsets.only(bottom: 6),
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.compare_arrows, size: 20, color: AppColors.warning),
          title: Text('${c.fromId} ↔ ${c.toId}'),
          subtitle: Text('${c.proximity.toStringAsFixed(1)}m · ${_formatTime(c.lastContact)}'),
        ),
      )),
    ]);
  }

  Widget _buildRiskCard(BuildContext context, EpidemicData data) {
    final l10n = AppLocalizations.of(context)!;
    final color = data.riskLevel == '警戒' ? AppColors.danger : data.riskLevel == '关注' ? AppColors.warning : AppColors.success;
    return Card(
      color: color.withOpacity(0.08),
      child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        Icon(Icons.shield, color: color),
        const SizedBox(width: 8),
        Text(l10n.epidemicRiskLevel(data.riskLevel), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ])),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
