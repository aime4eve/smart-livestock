import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Dialog to edit a failed check's EUI and retry.
///
/// Two entry points:
/// 1. FAILED inline check in quality_check_list — provide [failedCheck]
/// 2. Batch import failed row — provide [rowResult] from batch result
class EditRetryDialog extends ConsumerStatefulWidget {
  const EditRetryDialog({
    super.key,
    this.failedCheck,
    this.rowResult,
    this.checkType = 'STATIC',
    this.startedAt,
    this.endedAt,
  });

  /// Failed QualityCheck from the checks list.
  final QualityCheck? failedCheck;

  /// Failed RowResult from a batch import result.
  final RowResult? rowResult;

  // Fallback fields when only rowResult is provided
  final String checkType;
  final DateTime? startedAt;
  final DateTime? endedAt;

  @override
  ConsumerState<EditRetryDialog> createState() => _EditRetryDialogState();
}

class _EditRetryDialogState extends ConsumerState<EditRetryDialog> {
  late final TextEditingController _euiCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initialEui = widget.failedCheck?.deviceCode ?? widget.rowResult?.eui ?? '';
    _euiCtrl = TextEditingController(text: initialEui);
  }

  @override
  void dispose() {
    _euiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final errorMsg = widget.failedCheck?.errorMessage ?? widget.rowResult?.message ?? '';

    return AlertDialog(
      key: const Key('edit-retry-dialog'),
      title: Text(l10n.gpsQualityEditRetry),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (errorMsg.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(errorMsg, style: const TextStyle(fontSize: 12, color: AppColors.danger))),
                ]),
              ),
            // Editable EUI
            TextField(
              key: const Key('edit-retry-eui-input'),
              controller: _euiCtrl,
              decoration: InputDecoration(
                labelText: l10n.gpsQualityDeviceEui,
                prefixIcon: const Icon(Icons.wifi_tethering, size: 18),
              ),
            ),
            // Info: check type + time (read-only)
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              _infoChip(widget.failedCheck?.deviceCode != null
                  ? (widget.failedCheck!.checkType == 'STATIC'
                      ? l10n.gpsQualityTestTypeStatic
                      : l10n.gpsQualityTestTypeDynamic)
                  : l10n.gpsQualityNoData),
              const SizedBox(width: AppSpacing.sm),
              _infoChip(widget.failedCheck?.startedAt != null
                  ? '${widget.failedCheck!.startedAt.toLocal().toString().substring(0, 16)}'
                  : l10n.gpsQualityNoData),
            ]),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.danger)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l10n.gpsQualityCancelSession),
        ),
        FilledButton(
          key: const Key('edit-retry-submit-btn'),
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(l10n.gpsQualityEditAndRetry),
        ),
      ],
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final eui = _euiCtrl.text.trim();
    if (eui.isEmpty) {
      setState(() => _error = l10n.gpsQualityRequiredField);
      return;
    }

    setState(() => _saving = true);
    try {
      final checkType = widget.failedCheck?.checkType ?? widget.checkType;
      final startedAt = widget.failedCheck?.startedAt ?? widget.startedAt ?? DateTime.now();
      final endedAt = widget.failedCheck?.endedAt ?? widget.endedAt;

      await ref.read(gpsQualityApiRepositoryProvider).retryRow(
        eui: eui,
        checkType: checkType,
        startedAt: startedAt,
        endedAt: endedAt,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ref.invalidate(checksProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gpsQualityRegisterSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
  }
}
