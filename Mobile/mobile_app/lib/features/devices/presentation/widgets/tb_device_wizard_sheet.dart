import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/devices/domain/devices_repository.dart';
import 'package:hkt_livestock_agentic/features/devices/presentation/tb_device_wizard_controller.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/livestock_controller.dart';
import 'package:hkt_livestock_agentic/features/livestock/domain/livestock_repository.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

enum _WizardStep { input, confirm, result }

const _noLivestock = '__none__';

class TbDeviceWizardSheet extends ConsumerStatefulWidget {
  const TbDeviceWizardSheet({super.key});

  @override
  ConsumerState<TbDeviceWizardSheet> createState() => _TbDeviceWizardSheetState();
}

class _TbDeviceWizardSheetState extends ConsumerState<TbDeviceWizardSheet> {
  final _euiController = TextEditingController();
  final _deviceCodeController = TextEditingController();
  final List<LivestockSummary> _livestock = [];
  String? _selectedLivestockId;
  bool _livestockLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLivestock());
  }

  @override
  void dispose() {
    _euiController.dispose();
    _deviceCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadLivestock() async {
    try {
      final data = await ref.read(livestockRepositoryProvider)
          .loadAll(page: 1, pageSize: 200);
      if (mounted) {
        setState(() {
          _livestock
            ..clear()
            ..addAll(data.items);
          _livestockLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _livestockLoading = false);
    }
  }

  Future<void> _preflight() async {
    final controller = ref.read(tbDeviceWizardControllerProvider.notifier);
    await controller.preflight(_euiController.text);
    final preflight = ref.read(tbDeviceWizardControllerProvider).preflight;
    if (preflight != null && mounted) {
      final candidate = preflight.selectedCandidate;
      if (candidate != null) {
        _deviceCodeController.text =
            'TB-${preflight.nsProjectId ?? 0}-${preflight.eui}';
      }
    }
  }

  Future<void> _provision(TbDevicePreflight preflight) async {
    await ref.read(tbDeviceWizardControllerProvider.notifier).provision(
          preflight: preflight,
          deviceCode: _deviceCodeController.text,
          livestockId: _selectedLivestockId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(tbDeviceWizardControllerProvider);
    final step = state.result == null
        ? (state.preflight == null ? _WizardStep.input : _WizardStep.confirm)
        : _WizardStep.result;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.tbWizardTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            _StepIndicator(step: step),
            const SizedBox(height: AppSpacing.lg),
            if (state.error != null) ...[
              _MessageTile(
                message: state.error!,
                backgroundColor: AppColors.dangerSoft,
                foregroundColor: AppColors.danger,
                icon: Icons.error_outline,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            switch (step) {
              _WizardStep.input => _InputStep(
                  controller: _euiController,
                  loading: state.loading,
                  onEuiChanged: (_) => setState(() {}),
                  onPreflight: _preflight,
                ),
              _WizardStep.confirm => _ConfirmStep(
                  preflight: state.preflight!,
                  deviceCodeController: _deviceCodeController,
                  livestock: _livestock,
                  livestockLoading: _livestockLoading,
                  selectedLivestockId: _selectedLivestockId,
                  loading: state.loading,
                  onLivestockChanged: (value) =>
                      setState(() => _selectedLivestockId = value),
                  onRecheck: _preflight,
                  onProvision: () => _provision(state.preflight!),
                ),
              _WizardStep.result => _ResultStep(result: state.result!),
            },
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final _WizardStep step;

  @override
  Widget build(BuildContext context) {
    final currentIndex = step.index;
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0)
            const Expanded(child: Divider(height: 1)),
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= currentIndex ? AppColors.primary : AppColors.surfaceAlt,
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
 '${i + 1}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: i <= currentIndex ? Colors.white : AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InputStep extends StatelessWidget {
  const _InputStep({
    required this.controller,
    required this.loading,
    required this.onEuiChanged,
    required this.onPreflight,
  });

  final TextEditingController controller;
  final bool loading;
  final ValueChanged<String> onEuiChanged;
  final VoidCallback onPreflight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('tb-wizard-eui'),
          controller: controller,
          onChanged: onEuiChanged,
          decoration: InputDecoration(
            labelText: l10n.tbWizardEuiLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          key: const Key('tb-wizard-preflight'),
          onPressed: loading || controller.text.trim().isEmpty ? null : onPreflight,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: Text(l10n.tbWizardPreflightAction),
        ),
      ],
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({
    required this.preflight,
    required this.deviceCodeController,
    required this.livestock,
    required this.livestockLoading,
    required this.selectedLivestockId,
    required this.loading,
    required this.onLivestockChanged,
    required this.onRecheck,
    required this.onProvision,
  });

  final TbDevicePreflight preflight;
  final TextEditingController deviceCodeController;
  final List<LivestockSummary> livestock;
  final bool livestockLoading;
  final String? selectedLivestockId;
  final bool loading;
  final ValueChanged<String?> onLivestockChanged;
  final VoidCallback onRecheck;
  final VoidCallback onProvision;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final candidate = preflight.selectedCandidate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PreflightCard(preflight: preflight),
        if (preflight.candidates.length > 1) ...[
          _MessageTile(
            message: l10n.tbWizardAmbiguousWarning,
            backgroundColor: AppColors.warningSoft,
            foregroundColor: AppColors.warningStrong,
            icon: Icons.warning_amber,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (candidate != null && candidate.profileValid) ...[
          TextField(
            key: const Key('tb-wizard-code'),
            controller: deviceCodeController,
            decoration: InputDecoration(
              labelText: l10n.deviceFormFieldCode,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            key: const Key('tb-wizard-livestock'),
            initialValue: selectedLivestockId ?? _noLivestock,
            decoration: InputDecoration(
              labelText: l10n.tbWizardLivestockLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final item in livestock)
                DropdownMenuItem(
                  value: item.id,
                  child: Text(item.livestockCode),
                ),
              DropdownMenuItem(
                value: _noLivestock,
                child: Text(l10n.tbWizardNoLivestock),
              ),
            ],
            onChanged: livestockLoading ? null : onLivestockChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          if ((selectedLivestockId ?? _noLivestock) == _noLivestock)
            _MessageTile(
              message: l10n.tbWizardNoLivestockNote,
              backgroundColor: AppColors.warningSoft,
              foregroundColor: AppColors.warningStrong,
              icon: Icons.info_outline,
            ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loading ? null : onRecheck,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.tbWizardRecheck),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('tb-wizard-provision'),
                  onPressed: loading ? null : onProvision,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bolt),
                  label: Text(l10n.tbWizardProvisionAction),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PreflightCard extends StatelessWidget {
  const _PreflightCard({required this.preflight});

  final TbDevicePreflight preflight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final candidate = preflight.selectedCandidate;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _DetailRow(
            label: l10n.tbWizardEuiLabel,
            value: preflight.eui,
          ),
          _DetailRow(
            label: l10n.tbWizardNsProject,
            value: preflight.nsProjectId?.toString() ?? l10n.tbWizardMissing,
          ),
          _DetailRow(
            label: l10n.tbWizardTbDevice,
            value: candidate?.tbDeviceId ?? l10n.tbWizardMissing,
          ),
          _DetailRow(
            label: l10n.tbWizardProfile,
            value: candidate?.profileName ?? l10n.tbWizardMissing,
          ),
          _DetailRow(
            label: l10n.tbWizardLatestTelemetry,
            value: preflight.latestTelemetryAt ?? l10n.tbWizardNoTelemetry,
          ),
          _DetailRow(
            label: l10n.tbWizardStatus,
            value: _statusText(context, preflight.status),
            trailing: _StatusBadge(status: preflight.status),
          ),
        ],
      ),
    );
  }
}

class _ResultStep extends StatelessWidget {
  const _ResultStep({required this.result});

  final TbDeviceProvisionResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final installed = result.livestockId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 2.5,
          children: [
            _ResultTile(
              title: l10n.tbWizardResultDevice,
              value: result.localDeviceId,
              done: true,
            ),
            _ResultTile(
              title: l10n.tbWizardResultBinding,
              value: result.bindingStatus,
              done: result.bindingStatus == 'RESOLVED',
            ),
            _ResultTile(
              title: l10n.tbWizardResultActivation,
              value: result.deviceStatus,
              done: result.deviceStatus == 'ACTIVE',
            ),
            _ResultTile(
              title: l10n.tbWizardResultInstallation,
              value: installed ? l10n.tbWizardInstalled : l10n.tbWizardSkipped,
              done: installed,
            ),
            _ResultTile(
              title: l10n.tbWizardResultFence,
              value: installed ? l10n.tbWizardEnabled : l10n.tbWizardDisabled,
              done: installed,
            ),
            _ResultTile(
              title: l10n.tbWizardResultHealth,
              value: installed ? l10n.tbWizardEnabled : l10n.tbWizardDisabled,
              done: installed,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _MessageTile(
          message: _triggerText(context, result.firstTelemetryTrigger),
          backgroundColor: result.firstTelemetryTrigger == 'TB_TRIGGERED'
              ? AppColors.successSoft
              : AppColors.infoSoft,
          foregroundColor: result.firstTelemetryTrigger == 'TB_TRIGGERED'
              ? AppColors.successStrong
              : AppColors.infoStrong,
          icon: result.firstTelemetryTrigger == 'TB_TRIGGERED'
              ? Icons.check_circle_outline
              : Icons.schedule,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonConfirm),
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.title,
    required this.value,
    required this.done,
  });

  final String title;
  final String value;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.remove_circle_outline,
                size: 14,
                color: done ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'ACTIVE' => AppColors.success,
      'PENDING_NS' || 'PENDING_TB_DEVICE' || 'PENDING_TELEMETRY' =>
        AppColors.warning,
      _ => AppColors.info,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foregroundColor, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

String _statusText(BuildContext context, String status) {
  final l10n = AppLocalizations.of(context)!;
  return switch (status) {
    'PENDING_NS' => l10n.tbWizardStatusPendingNs,
    'PENDING_TB_DEVICE' => l10n.tbWizardStatusPendingTbDevice,
    'PENDING_TELEMETRY' => l10n.tbWizardStatusPendingTelemetry,
    'READY_TO_INGEST' => l10n.tbWizardStatusReady,
    'PENDING_INSTALLATION' => l10n.tbWizardStatusPendingInstallation,
    'ACTIVE' => l10n.tbWizardStatusActive,
    _ => l10n.tbWizardStatusUnknown(status),
  };
}

String _triggerText(BuildContext context, String status) {
  final l10n = AppLocalizations.of(context)!;
  return switch (status) {
    'TB_TRIGGERED' => l10n.tbWizardTriggerDone,
    'TB_TRIGGER_SKIPPED_DISABLED' => l10n.tbWizardTriggerDisabled,
    'TB_TRIGGER_BINDING_NOT_FOUND' => l10n.tbWizardTriggerBindingMissing,
    'TB_TRIGGER_FAILED' => l10n.tbWizardTriggerFailed,
    _ => l10n.tbWizardStatusUnknown(status),
  };
}
