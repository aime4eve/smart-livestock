import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/device_profile_rules/domain/device_profile_rule_models.dart';
import 'package:hkt_livestock_agentic/features/admin/device_profile_rules/presentation/device_profile_rule_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Create/edit dialog for one allowlist rule (NIX-214 prototype screen B).
/// The profile name is immutable after creation — the backend ignores it on
/// update, so the field is locked in edit mode.
class DeviceProfileRuleFormSheet extends ConsumerStatefulWidget {
  const DeviceProfileRuleFormSheet({
    super.key,
    this.existing,
    required this.currentRules,
  });

  final DeviceProfileRule? existing;
  final List<DeviceProfileRule> currentRules;

  @override
  ConsumerState<DeviceProfileRuleFormSheet> createState() =>
      _DeviceProfileRuleFormSheetState();
}

class _DeviceProfileRuleFormSheetState
    extends ConsumerState<DeviceProfileRuleFormSheet> {
  final _nameController = TextEditingController();
  final _remarkController = TextEditingController();
  RuleDeviceType _deviceType = RuleDeviceType.tracker;
  bool _enabled = true;
  bool _manualMode = false;
  bool _saving = false;
  String? _errorText;
  String? _selectedTbName;

  DeviceProfileRule? get _existing => widget.existing;
  bool get _isEdit => _existing != null;

  @override
  void initState() {
    super.initState();
    final existing = _existing;
    if (existing != null) {
      _nameController.text = existing.profileName;
      _remarkController.text = existing.remark ?? '';
      _deviceType = existing.deviceType;
      _enabled = existing.enabled;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEdit
                            ? l10n.deviceProfileRuleEditTitle
                            : l10n.deviceProfileRuleAddTitle,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildNameField(l10n),
                const SizedBox(height: AppSpacing.lg),
                _buildTypeSegment(l10n),
                const SizedBox(height: AppSpacing.lg),
                _buildEnabledRow(l10n),
                const SizedBox(height: AppSpacing.lg),
                _buildRemarkField(l10n),
                if (_errorText != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _errorText!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(false),
                      child: Text(l10n.commonCancel),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _saving ? null : () => _submit(l10n),
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(l10n.commonSave),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(l10n.deviceProfileRuleFieldName, required: true),
        const SizedBox(height: 6),
        if (_isEdit)
          TextField(
            controller: _nameController,
            readOnly: true,
            style: const TextStyle(fontSize: 12),
            decoration: _inputDecoration(),
          )
        else if (_manualMode)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                maxLength: 128,
                style: const TextStyle(fontSize: 12),
                decoration: _inputDecoration(
                    hint: l10n.deviceProfileRuleManualHint),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  onPressed: () =>
                      setState(() => _manualMode = false),
                  child: Text(l10n.deviceProfileRuleUseTbList),
                ),
              ),
            ],
          )
        else
          FutureBuilder<List<TbProfile>>(
            future:
                ref.read(deviceProfileRuleRepositoryProvider).listTbProfiles(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                      child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )),
                );
              }
              if (snapshot.hasError) {
                // TB unreachable → fall back to manual input per spec §9.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_manualMode) {
                    setState(() => _manualMode = true);
                  }
                });
                return Text(
                  l10n.deviceProfileRuleTbUnavailable,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.warningStrong),
                );
              }
              final profiles = snapshot.data ?? const <TbProfile>[];
              final existingNames =
                  widget.currentRules.map((r) => r.profileName).toSet();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedTbName,
                    isExpanded: true,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textPrimary),
                    decoration: _inputDecoration(
                        hint: l10n.deviceProfileRulePickTb),
                    items: [
                      for (final p in profiles)
                        DropdownMenuItem(
                          value: p.name,
                          enabled: !existingNames.contains(p.name),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: existingNames.contains(p.name)
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (existingNames.contains(p.name))
                                Text(
                                  l10n.deviceProfileRuleTagTaken,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedTbName = value),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () =>
                          setState(() => _manualMode = true),
                      child: Text(l10n.deviceProfileRuleManualInput),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildTypeSegment(AppLocalizations l10n) {
    Widget option(RuleDeviceType type, IconData icon, String label) {
      final selected = _deviceType == type;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _deviceType = type),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? AppColors.primarySoft : Colors.transparent,
            ),
            child: Column(
              children: [
                Icon(icon,
                    size: 18,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(l10n.deviceProfileRuleFieldDeviceType, required: true),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.sm - 1),
            child: Row(
              children: [
                option(RuleDeviceType.earTag, Icons.sell_outlined,
                    l10n.deviceProfileRuleTypeEarTag),
                Container(width: 1, color: AppColors.border),
                option(RuleDeviceType.tracker, Icons.pets_outlined,
                    l10n.deviceProfileRuleTypeTracker),
                Container(width: 1, color: AppColors.border),
                option(RuleDeviceType.capsule, Icons.medication_outlined,
                    l10n.deviceProfileRuleTypeCapsule),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.deviceProfileRuleTypeHelp,
          style: const TextStyle(
              fontSize: 10, height: 1.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildEnabledRow(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Switch(
              value: _enabled,
              activeThumbColor: AppColors.success,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _enabled
                  ? l10n.deviceProfileRuleEnabled
                  : l10n.deviceProfileRuleDisabled,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Text(
          l10n.deviceProfileRuleEnabledHelp,
          style: const TextStyle(
              fontSize: 10, height: 1.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildRemarkField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(l10n.deviceProfileRuleFieldRemark),
        const SizedBox(height: 6),
        TextField(
          controller: _remarkController,
          maxLength: 255,
          maxLines: 2,
          style: const TextStyle(fontSize: 12),
          decoration: _inputDecoration(
              hint: l10n.deviceProfileRuleRemarkHint),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        if (required)
          const Text(' *',
              style: TextStyle(fontSize: 12, color: AppColors.danger)),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      counterText: '',
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final name = _isEdit ? _existing!.profileName : _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = l10n.deviceProfileRuleNameRequired);
      return;
    }
    final duplicate = widget.currentRules.any((r) =>
        r.profileName == name && r.id != _existing?.id);
    if (duplicate) {
      setState(() => _errorText = l10n.deviceProfileRuleDuplicateLocal);
      return;
    }
    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      await ref.read(deviceProfileRulesControllerProvider.notifier).saveRule(
            ruleId: _existing?.id,
            profileName: name,
            deviceType: _deviceType,
            enabled: _enabled,
            remark:
                _remarkController.text.trim().isEmpty
                    ? null
                    : _remarkController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _saving = false;
        _errorText = e.toString();
      });
    }
  }
}
