import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/admin/feature_gate/domain/feature_gate_models.dart';
import 'package:hkt_livestock_agentic/features/admin/feature_gate/presentation/feature_gate_controller.dart';
import 'package:hkt_livestock_agentic/features/admin/feature_gate/presentation/gate_status_chip.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Resolve feature_key to its localized display name.
String featureDisplayName(AppLocalizations l10n, String featureKey) {
  switch (featureKey) {
    case 'livestock_management':  return l10n.featLivestockManagement;
    case 'fence_management':      return l10n.featFenceManagement;
    case 'alert_management':      return l10n.featAlertManagement;
    case 'worker_management':     return l10n.featWorkerManagement;
    case 'advanced_analytics':    return l10n.featAdvancedAnalytics;
    case 'api_access':            return l10n.featApiAccess;
    case 'health_monitoring':     return l10n.featHealthMonitoring;
    case 'temperature_monitor':   return l10n.featTemperatureMonitor;
    case 'peristaltic_monitor':   return l10n.featPeristalticMonitor;
    case 'health_score':          return l10n.featHealthScore;
    case 'estrus_detect':         return l10n.featEstrusDetect;
    case 'epidemic_alert':        return l10n.featEpidemicAlert;
    default: return featureKey;
  }
}

String _unitLabel(AppLocalizations l10n, FeatureUnit unit) {
  switch (unit) {
    case FeatureUnit.head:   return l10n.featureGateUnitHead;
    case FeatureUnit.count:  return l10n.featureGateUnitCount;
    case FeatureUnit.person: return l10n.featureGateUnitPerson;
    case FeatureUnit.day:    return l10n.featureGateUnitDay;
    case FeatureUnit.none:   return '';
  }
}

class FeatureGateCard extends ConsumerStatefulWidget {
  const FeatureGateCard({super.key, required this.gate});

  final FeatureGateEntry gate;

  @override
  ConsumerState<FeatureGateCard> createState() => _FeatureGateCardState();
}

class _FeatureGateCardState extends ConsumerState<FeatureGateCard> {
  bool _editing = false;
  late TextEditingController _limitCtrl;
  late TextEditingController _retentionCtrl;
  late bool _editEnabled;
  bool _switchBusy = false;

  @override
  void initState() {
    super.initState();
    _limitCtrl = TextEditingController(text: '${widget.gate.limitValue}');
    _retentionCtrl = TextEditingController(text: '${widget.gate.retentionDays}');
    _editEnabled = widget.gate.isEnabled;
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    _retentionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gate = widget.gate;
    final meta = gate.meta;
    final type = gate.gateType?.toUpperCase();
    final showValue = type == 'LIMIT' || type == 'FILTER';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: HighfiCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: _editing
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
            boxShadow: _editing
                ? const [BoxShadow(color: Color(0x1E263126), blurRadius: 16, offset: Offset(0, 4))]
                : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          featureDisplayName(l10n, gate.featureKey),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                gate.featureKey,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontFamily: 'monospace',
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GateStatusChip(gateType: gate.gateType, isEnabled: gate.isEnabled),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (showValue)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: _ValueDisplay(gate: gate, unit: meta?.unit ?? FeatureUnit.none, l10n: l10n),
                    ),
                  _QuickSwitch(
                    value: gate.isEnabled,
                    busy: _switchBusy,
                    onChanged: _toggleSwitch,
                  ),
                  IconButton(
                    key: const Key('gate-edit'),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    visualDensity: VisualDensity.compact,
                    color: AppColors.textSecondary,
                    onPressed: () => setState(() => _editing = !_editing),
                  ),
                ],
              ),
              if (_editing) _buildEditRow(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditRow(AppLocalizations l10n) {
    final gate = widget.gate;
    final type = gate.gateType?.toUpperCase();
    final hasLimit = type == 'LIMIT';
    final hasRetention = type == 'FILTER';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasLimit || hasRetention)
            Row(
              children: [
                Text(
                  hasLimit ? l10n.featureGateLimit : l10n.featureGateRetentionDays,
                  style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: TextField(
                      controller: hasLimit ? _limitCtrl : _retentionCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      ),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Switch(value: _editEnabled, onChanged: (v) => setState(() => _editEnabled = v), activeThumbColor: AppColors.success),
              ],
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: Switch(value: _editEnabled, onChanged: (v) => setState(() => _editEnabled = v), activeThumbColor: AppColors.success),
            ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _editing = false;
                    _editEnabled = gate.isEnabled;
                    _limitCtrl.text = '${gate.limitValue}';
                    _retentionCtrl.text = '${gate.retentionDays}';
                  });
                },
                child: Text(l10n.commonCancel, style: const TextStyle(fontSize: 10)),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: const Size(0, 28),
                ),
                child: Text(l10n.commonSave, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSwitch(bool value) async {
    setState(() => _switchBusy = true);
    try {
      await ref.read(featureGateControllerProvider.notifier).updateGate(
            widget.gate.id,
            isEnabled: value,
          );
    } finally {
      if (mounted) setState(() => _switchBusy = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final gate = widget.gate;
    final type = gate.gateType?.toUpperCase();
    await ref.read(featureGateControllerProvider.notifier).updateGate(
          gate.id,
          limitValue: type == 'LIMIT' ? int.tryParse(_limitCtrl.text) : null,
          retentionDays: type == 'FILTER' ? int.tryParse(_retentionCtrl.text) : null,
          isEnabled: _editEnabled,
        );
    if (mounted) {
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.featureGateUpdated(featureDisplayName(l10n, gate.featureKey)))),
      );
    }
  }
}

class _ValueDisplay extends StatelessWidget {
  const _ValueDisplay({required this.gate, required this.unit, required this.l10n});
  final FeatureGateEntry gate;
  final FeatureUnit unit;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final type = gate.gateType?.toUpperCase();
    final value = type == 'FILTER' ? gate.retentionDays : gate.limitValue;
    final color = type == 'FILTER' ? AppColors.info : AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('$value', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        Text(_unitLabel(l10n, unit), style: const TextStyle(fontSize: 8, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _QuickSwitch extends StatelessWidget {
  const _QuickSwitch({required this.value, required this.onChanged, this.busy = false});
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 20,
      child: FittedBox(
        child: Switch(
          value: value,
          onChanged: busy ? null : onChanged,
          activeThumbColor: AppColors.success,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: AppColors.border,
        ),
      ),
    );
  }
}
