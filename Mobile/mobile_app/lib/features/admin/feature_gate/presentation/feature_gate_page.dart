import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/feature_gate/domain/feature_gate_models.dart';
import 'package:hkt_livestock_agentic/features/admin/feature_gate/presentation/feature_gate_card.dart';
import 'package:hkt_livestock_agentic/features/admin/feature_gate/presentation/feature_gate_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class FeatureGatePage extends ConsumerWidget {
  const FeatureGatePage({super.key});

  // Tier keys match the backend values (lowercase).
  static const _tierKeys = ['basic', 'standard', 'premium', 'enterprise'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncGates = ref.watch(featureGateControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.featureGateTitle)),
      body: asyncGates.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text('$e'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(featureGateControllerProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
        data: (gates) {
          final tierLabels = [
            l10n.featureGateTierBasic,
            l10n.featureGateTierStandard,
            l10n.featureGateTierPremium,
            l10n.featureGateTierEnterprise,
          ];
          return DefaultTabController(
            length: _tierKeys.length,
            child: Column(
              children: [
                TabBar(
                  tabAlignment: TabAlignment.start,
                  isScrollable: false,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: List.generate(_tierKeys.length, (i) {
                    final count = gates.where((g) => g.tier == _tierKeys[i]).length;
                    return Tab(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(tierLabels[i], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          Text('$count', style: const TextStyle(fontSize: 8)),
                        ],
                      ),
                    );
                  }),
                ),
                Expanded(
                  child: TabBarView(
                    children: _tierKeys.map((tierKey) {
                      final tierGates = gates.where((g) => g.tier == tierKey).toList();
                      return _TierContent(gates: tierGates);
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TierContent extends ConsumerWidget {
  const _TierContent({required this.gates});
  final List<FeatureGateEntry> gates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (gates.isEmpty) {
      return Center(child: Text(l10n.featureGateNoData));
    }

    // Group by category: platform first, then health.
    final platform = gates.where((g) => g.meta?.category == FeatureCategory.platform).toList();
    final health = gates.where((g) => g.meta?.category == FeatureCategory.health).toList();

    return ListView(
      key: const Key('feature-gate-list'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (platform.isNotEmpty) ...[
          _SectionHeader(label: l10n.featureGateCatPlatform, count: platform.length),
          ...platform.map((g) => FeatureGateCard(gate: g)),
        ],
        if (health.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _SectionHeader(label: l10n.featureGateCatHealth, count: health.length),
          ...health.map((g) => FeatureGateCard(gate: g)),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.sm),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
