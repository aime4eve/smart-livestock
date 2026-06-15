import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/feature_gate/domain/feature_gate_models.dart';
import 'package:hkt_livestock_agentic/features/admin/feature_gate/presentation/feature_gate_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class FeatureGatePage extends ConsumerWidget {
  const FeatureGatePage({super.key});

  static const _tiers = ['BASIC', 'STANDARD', 'PREMIUM', 'ENTERPRISE'];

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
          final grouped = <String, List<FeatureGateEntry>>{};
          for (final g in gates) {
            grouped.putIfAbsent(g.tier, () => []).add(g);
          }
          return DefaultTabController(
            length: _tiers.length,
            child: Column(
              children: [
                TabBar(
                  tabs: _tiers.map((t) => Tab(text: t)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: _tiers.map((tier) {
                      final items = grouped[tier] ?? [];
                      if (items.isEmpty) {
                        return Center(child: Text(l10n.featureGateNoData));
                      }
                      return _GateList(items: items);
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

class _GateList extends ConsumerWidget {
  const _GateList({required this.items});
  final List<FeatureGateEntry> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final gate = items[index];
        return _GateTile(gate: gate);
      },
    );
  }
}

class _GateTile extends ConsumerStatefulWidget {
  const _GateTile({required this.gate});
  final FeatureGateEntry gate;

  @override
  ConsumerState<_GateTile> createState() => _GateTileState();
}

class _GateTileState extends ConsumerState<_GateTile> {
  late TextEditingController _limitCtrl;
  late TextEditingController _retentionCtrl;
  late bool _isEnabled;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _limitCtrl = TextEditingController(text: '${widget.gate.limitValue}');
    _retentionCtrl = TextEditingController(text: '${widget.gate.retentionDays}');
    _isEnabled = widget.gate.isEnabled;
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    _retentionCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(widget.gate.featureKey, style: Theme.of(context).textTheme.bodyMedium),
          ),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: _limitCtrl,
              decoration: InputDecoration(labelText: l10n.featureGateLimit, isDense: true, border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (_) => _markDirty(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: _retentionCtrl,
              decoration: InputDecoration(labelText: l10n.featureGateRetentionDays, isDense: true, border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (_) => _markDirty(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch(
            value: _isEnabled,
            onChanged: (v) {
              setState(() { _isEnabled = v; _markDirty(); });
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.tonal(
            onPressed: _dirty ? _save : null,
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(featureGateControllerProvider.notifier).updateGate(
      widget.gate.id,
      limitValue: int.tryParse(_limitCtrl.text),
      retentionDays: int.tryParse(_retentionCtrl.text),
      isEnabled: _isEnabled,
    );
    if (mounted) {
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.featureGateUpdated(widget.gate.featureKey))),
      );
    }
  }
}
