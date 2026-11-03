import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Platform-configurable expiry thresholds for the subscription-health
/// verdict (GET/PUT /admin/subscription-health-settings, backend contract
/// §16). Saving invalidates the backend cache so verdicts take effect
/// immediately. Frontend pre-validates the strict descending order; the
/// backend re-validates and returns VALIDATION_ERROR anyway.
class SubscriptionHealthSettingsCard extends StatefulWidget {
  const SubscriptionHealthSettingsCard({super.key});

  @override
  State<SubscriptionHealthSettingsCard> createState() =>
      _SubscriptionHealthSettingsCardState();
}

class _SubscriptionHealthSettingsCardState
    extends State<SubscriptionHealthSettingsCard> {
  final _warnCtrl = TextEditingController();
  final _cautionCtrl = TextEditingController();
  final _dangerCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _orderError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _warnCtrl.dispose();
    _cautionCtrl.dispose();
    _dangerCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiClient.instance.get('/admin/subscription-health-settings');
      if (!mounted) return;
      setState(() {
        _warnCtrl.text = '${data['warnDays'] ?? 14}';
        _cautionCtrl.text = '${data['cautionDays'] ?? 7}';
        _dangerCtrl.text = '${data['dangerDays'] ?? 3}';
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'load');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _parseTiers(List<TextEditingController> ctrls, List<int> out) {
    for (final c in ctrls) {
      final v = int.tryParse(c.text.trim());
      if (v == null || v <= 0) return false;
      out.add(v);
    }
    return out[0] > out[1] && out[1] > out[2];
  }

  Future<void> _save(AppLocalizations l10n) async {
    final tiers = <int>[];
    if (!_parseTiers([_warnCtrl, _cautionCtrl, _dangerCtrl], tiers)) {
      setState(() => _orderError = l10n.subscriptionHealthSettingsInvalidOrder);
      return;
    }
    setState(() {
      _orderError = null;
      _saving = true;
    });
    String toast;
    try {
      await ApiClient.instance.put('/admin/subscription-health-settings',
          body: {
            'warnDays': tiers[0],
            'cautionDays': tiers[1],
            'dangerDays': tiers[2],
          });
      toast = l10n.subscriptionHealthSettingsSaved;
    } on ApiException catch (e) {
      // The backend's localized validation message wins (e.g. order check).
      toast = e.message;
    } catch (_) {
      toast = l10n.subscriptionHealthSettingsSaveFailed;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toast)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      key: const Key('health-settings-card'),
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _loading
            ? const Center(
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.subscriptionHealthSettingsTitle,
                      key: const Key('health-settings-title'),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.sm),
                  if (_error != null)
                    Text(l10n.subscriptionHealthSettingsLoadFailed,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.danger))
                  else ...[
                    Row(children: [
                      _tierField(l10n.subscriptionHealthSettingsWarnLabel,
                          _warnCtrl, 'warn'),
                      const SizedBox(width: AppSpacing.sm),
                      _tierField(l10n.subscriptionHealthSettingsCautionLabel,
                          _cautionCtrl, 'caution'),
                      const SizedBox(width: AppSpacing.sm),
                      _tierField(l10n.subscriptionHealthSettingsDangerLabel,
                          _dangerCtrl, 'danger'),
                    ]),
                    if (_orderError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(_orderError!,
                            key: const Key('health-settings-order-error'),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.danger)),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const Key('health-settings-save'),
                        onPressed: _saving ? null : () => _save(l10n),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surfaceAlt,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : Text(l10n.subscriptionHealthSettingsSave,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _tierField(String label, TextEditingController ctrl, String keyName) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          TextField(
            key: Key('health-settings-$keyName'),
            controller: ctrl,
            keyboardType: TextInputType.number,
            onChanged: (_) {
              // Clear the stale order error as soon as any field changes.
              if (_orderError != null && mounted) {
                setState(() => _orderError = null);
              }
            },
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
