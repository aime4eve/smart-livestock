import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

import '../../gateways/presentation/gateway_controller.dart' show gatewayRepositoryProvider;

/// F10 admin gateway reconciliation (prototype screen 4): registered list,
/// never-marked gateways seen in telemetry, and the overall mark rate.
class GatewayOverviewPage extends ConsumerStatefulWidget {
  const GatewayOverviewPage({super.key});

  @override
  ConsumerState<GatewayOverviewPage> createState() => _GatewayOverviewPageState();
}

class _GatewayOverviewPageState extends ConsumerState<GatewayOverviewPage> {
  Map<String, dynamic>? _overview;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(gatewayRepositoryProvider).adminOverview();
      if (mounted) setState(() => _overview = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overview = _overview;
    final registered = (overview?['registered'] as List?) ?? const [];
    final unmarked = (overview?['unmarked'] as List?) ?? const [];
    final markRate = ((overview?['markRate'] as num?)?.toDouble() ?? 0) * 100;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l10n.gatewayAdminTitle)),
      body: _error != null
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_error!,
                  style: const TextStyle(color: AppColors.textSecondary)),
              TextButton(onPressed: _load, child: Text(l10n.commonRetry)),
            ]))
          : overview == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Row(children: [
                      _statCell('${registered.length}', l10n.gatewayAdminRegistered),
                      const SizedBox(width: AppSpacing.sm),
                      _statCell('${unmarked.length}', l10n.gatewayAdminUnmarked),
                      const SizedBox(width: AppSpacing.sm),
                      _statCell('${markRate.toStringAsFixed(0)}%',
                          l10n.gatewayAdminMarkRate),
                    ]),
                    if (unmarked.isNotEmpty) ...[
                      Padding(
                        padding:
                            const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
                        child: Text(l10n.gatewayAdminUnmarkedList(unmarked.length),
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                        child: Column(
                          children: [
                            for (final id in unmarked)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md, vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(id, style: const TextStyle(fontSize: 13))),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    Padding(
                      padding:
                          const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
                      child: Text(l10n.gatewayAdminRegisteredList(registered.length),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    for (final reg in registered)
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text((reg['gatewayId'] as String?) ?? '--',
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                  '${reg['latitude'] ?? '--'}, ${reg['longitude'] ?? '--'}',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textSecondary)),
                              Text(
                                  l10n.gatewayAdminMarkedBy(
                                      '${reg['markedBy'] ?? '--'}',
                                      (reg['source'] as String?) ?? 'APP'),
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textSecondary)),
                            ]),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.gatewayAdminFootnote,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary, height: 1.6)),
                  ],
                ),
    );
  }

  Widget _statCell(String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Column(children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
      );
}
