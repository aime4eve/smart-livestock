import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/device_profile_rules/domain/device_profile_rule_models.dart';
import 'package:hkt_livestock_agentic/features/admin/device_profile_rules/presentation/device_profile_rule_controller.dart';
import 'package:hkt_livestock_agentic/features/admin/device_profile_rules/presentation/device_profile_rule_form_sheet.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Platform admin page for the TB device profile allowlist (NIX-214).
class DeviceProfileRulesPage extends ConsumerWidget {
  const DeviceProfileRulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncRules = ref.watch(deviceProfileRulesControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deviceProfileRuleTitle)),
      body: asyncRules.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.md),
              Text('$e'),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(deviceProfileRulesControllerProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
        data: (data) => _RulesBody(data: data),
      ),
    );
  }
}

class _RulesBody extends ConsumerStatefulWidget {
  const _RulesBody({required this.data});

  final DeviceProfileRulesData data;

  @override
  ConsumerState<_RulesBody> createState() => _RulesBodyState();
}

class _RulesBodyState extends ConsumerState<_RulesBody> {
  int? _togglingId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rules = widget.data.rules;
    final enabledCount = rules.where((r) => r.enabled).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
          child: _HintBar(text: l10n.deviceProfileRuleHint),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
          child: Row(
            children: [
              Text(
                l10n.deviceProfileRuleStat(rules.length, enabledCount,
                    rules.length - enabledCount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.deviceProfileRuleReload),
                onPressed: () =>
                    ref.read(deviceProfileRulesControllerProvider.notifier).refresh(),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.deviceProfileRuleAdd),
                onPressed: () => _openForm(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: rules.isEmpty
              ? Center(child: Text(l10n.deviceProfileRuleEmpty))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    child: Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 900),
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(1),
                              1: FixedColumnWidth(120),
                              2: FixedColumnWidth(70),
                              3: FlexColumnWidth(0.8),
                              4: FixedColumnWidth(140),
                              5: FixedColumnWidth(120),
                            },
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            children: [
                              TableRow(
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                ),
                                children: [
                                  _headerCell(l10n.deviceProfileRuleColName),
                                  _headerCell(l10n.deviceProfileRuleColType),
                                  _headerCell(l10n.deviceProfileRuleColStatus),
                                  _headerCell(l10n.deviceProfileRuleColRemark),
                                  _headerCell(l10n.deviceProfileRuleColUpdatedAt),
                                  _headerCell(l10n.deviceProfileRuleColActions),
                                ],
                              ),
                              for (final rule in rules)
                                TableRow(
                                  children: [
                                    _nameCell(rule, l10n),
                                    _typeCell(rule),
                                    _switchCell(rule, l10n),
                                    _remarkCell(rule),
                                    _timeCell(rule),
                                    _actionsCell(context, rule, l10n),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _nameCell(DeviceProfileRule rule, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 11),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              rule.profileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: rule.enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _SourceChip(
            label: widget.data.isFromTb(rule.profileName)
                ? l10n.deviceProfileRuleSourceTb
                : l10n.deviceProfileRuleSourceManual,
          ),
        ],
      ),
    );
  }

  Widget _typeCell(DeviceProfileRule rule) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 11),
      child: Align(
        alignment: Alignment.centerLeft,
        child: rule.enabled
            ? _TypeBadge(deviceType: rule.deviceType)
            : const _DisabledBadge(),
      ),
    );
  }

  Widget _switchCell(DeviceProfileRule rule, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 8),
      child: _togglingId == rule.id
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Switch(
              value: rule.enabled,
              activeThumbColor: AppColors.success,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (value) async {
                final failMsg = l10n.deviceProfileRuleToggleFailed;
                final messenger = ScaffoldMessenger.of(context);
                setState(() => _togglingId = rule.id);
                try {
                  await ref
                      .read(deviceProfileRulesControllerProvider.notifier)
                      .setEnabled(rule, value);
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('$failMsg: $e')),
                  );
                }
                if (mounted) setState(() => _togglingId = null);
              },
            ),
    );
  }

  Widget _remarkCell(DeviceProfileRule rule) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 11),
      child: Text(
        rule.remark ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _timeCell(DeviceProfileRule rule) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 11),
      child: Text(
        (rule.updatedAt ?? '').replaceAll('T', ' ').split('.').first,
        style: const TextStyle(
            fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _actionsCell(
      BuildContext context, DeviceProfileRule rule, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onPressed: () => _openForm(context, existing: rule),
            child: Text(l10n.commonEdit),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              foregroundColor: AppColors.danger,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onPressed: () => _confirmDelete(context, rule),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, {DeviceProfileRule? existing}) {
    showDialog<bool>(
      context: context,
      builder: (_) => DeviceProfileRuleFormSheet(
        existing: existing,
        currentRules: widget.data.rules,
      ),
    ).then((saved) {
      if (saved == true) {
        ref.read(deviceProfileRulesControllerProvider.notifier).silentRefresh();
      }
    });
  }

  Future<void> _confirmDelete(BuildContext context, DeviceProfileRule rule) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmSheet(rule: rule),
    );
    if (confirmed != true) return;
    try {
      await ref.read(deviceProfileRulesControllerProvider.notifier).deleteRule(rule.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deviceProfileRuleDeleted)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.commonDeleteFailed(e.toString())),
        ));
      }
    }
  }
}

class _HintBar extends StatelessWidget {
  const _HintBar({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        border: Border.all(color: AppColors.info),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              size: 14, color: AppColors.infoStrong),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 11, height: 1.5, color: AppColors.infoStrong),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.deviceType});

  final RuleDeviceType deviceType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (bg, fg, label) = switch (deviceType) {
      RuleDeviceType.earTag => (
          AppColors.successSoft,
          AppColors.successStrong,
          l10n.deviceProfileRuleTypeEarTag
        ),
      RuleDeviceType.tracker => (
          AppColors.infoSoft,
          AppColors.infoStrong,
          l10n.deviceProfileRuleTypeTracker
        ),
      RuleDeviceType.capsule => (
          const Color(0xFFF9E6EF),
          const Color(0xFFC25689),
          l10n.deviceProfileRuleTypeCapsule
        ),
    };
    return _pill(bg, fg, label);
  }

  static Widget _pill(Color bg, Color fg, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisabledBadge extends StatelessWidget {
  const _DisabledBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _TypeBadge._pill(
      AppColors.surfaceMuted,
      AppColors.textSecondary,
      l10n.deviceProfileRuleDisabledBadge,
    );
  }
}

class _DeleteConfirmSheet extends StatelessWidget {
  const _DeleteConfirmSheet({required this.rule});

  final DeviceProfileRule rule;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.dangerSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AppColors.danger),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.deviceProfileRuleDeleteTitle,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text.rich(
                TextSpan(
                  text: l10n.deviceProfileRuleDeleteBody,
                  children: [
                    TextSpan(
                      text: rule.profileName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: '？'),
                  ],
                  style: const TextStyle(fontSize: 12, height: 1.7),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  border: Border.all(color: AppColors.warning),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Text(
                  l10n.deviceProfileRuleDeleteWarn(rule.profileName),
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.6,
                    color: AppColors.warningStrong,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.commonCancel),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l10n.commonDelete),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
