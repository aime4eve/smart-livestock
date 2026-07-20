import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/core/widgets/date_time_input_field.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Dialog for creating a single GPS quality check (EUI-driven).
class CreateCheckDialog extends ConsumerStatefulWidget {
  const CreateCheckDialog({super.key});

  @override
  ConsumerState<CreateCheckDialog> createState() => _CreateCheckDialogState();
}

class _CreateCheckDialogState extends ConsumerState<CreateCheckDialog> {
  final _euiCtrl = TextEditingController();
  final _deviceCodeCtrl = TextEditingController();
  String _testType = 'STATIC';
  int? _rtkPointId;
  int? _routeId;
  DateTime? _startedAt;
  DateTime? _endedAt;
  bool _saving = false;
  String? _euiError;

  @override
  void dispose() {
    _euiCtrl.dispose();
    _deviceCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rtkPoints = ref.watch(rtkPointsProvider).value ?? [];
    final routes = ref.watch(dynamicRoutesProvider).value ?? [];

    return AlertDialog(
      key: const Key('create-check-dialog'),
      title: Text(l10n.gpsQualityCreateCheck),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // EUI field (required)
              TextField(
                key: const Key('check-eui-input'),
                controller: _euiCtrl,
                decoration: InputDecoration(
                  labelText: l10n.gpsQualityDeviceEui,
                  hintText: 'e.g. ABC123456789',
                  errorText: _euiError,
                  prefixIcon: const Icon(Icons.wifi_tethering, size: 18),
                ),
                onChanged: (_) => setState(() => _euiError = null),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Device code (optional)
              TextField(
                key: const Key('check-device-code-input'),
                controller: _deviceCodeCtrl,
                decoration: InputDecoration(
                  labelText: l10n.gpsQualityDevice,
                  hintText: l10n.commonOptional,
                  prefixIcon: const Icon(Icons.devices, size: 18),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Test type toggle
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'STATIC',
                    label: Text(l10n.gpsQualityTestTypeStatic, style: const TextStyle(fontSize: 12)),
                    icon: const Icon(Icons.location_on, size: 16),
                  ),
                  ButtonSegment(
                    value: 'DYNAMIC',
                    label: Text(l10n.gpsQualityTestTypeDynamic, style: const TextStyle(fontSize: 12)),
                    icon: const Icon(Icons.directions_walk, size: 16),
                  ),
                ],
                selected: {_testType},
                onSelectionChanged: (v) => setState(() {
                  _testType = v.first;
                  _rtkPointId = null;
                  _routeId = null;
                }),
                showSelectedIcon: false,
              ),
              const SizedBox(height: AppSpacing.sm),
              // Truth reference selection
              if (_testType == 'STATIC')
                DropdownButtonFormField<int>(
                  key: const Key('check-rtk-point-select'),
                  decoration: InputDecoration(labelText: l10n.gpsQualitySelectRtkPoint),
                  value: _rtkPointId,
                  isExpanded: true,
                  items: rtkPoints.map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.locationName} · ${p.pointLabel}', style: const TextStyle(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setState(() => _rtkPointId = v),
                )
              else
                DropdownButtonFormField<int>(
                  key: const Key('check-route-select'),
                  decoration: InputDecoration(labelText: l10n.gpsQualitySelectRoute),
                  value: _routeId,
                  isExpanded: true,
                  items: routes.map((r) => DropdownMenuItem(
                    value: r.id,
                    child: Text(r.name, style: const TextStyle(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setState(() => _routeId = v),
                ),
              const SizedBox(height: AppSpacing.md),
              // Time range
              DateTimeInputField(
                key: const Key('check-start-time'),
                label: l10n.gpsQualityStartTime,
                value: _startedAt,
                onChanged: (v) => setState(() => _startedAt = v),
                isRequired: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              DateTimeInputField(
                key: const Key('check-end-time'),
                label: l10n.gpsQualityEndTime,
                value: _endedAt,
                onChanged: (v) => setState(() => _endedAt = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l10n.gpsQualityCancelSession),
        ),
        FilledButton(
          key: const Key('create-check-submit-btn'),
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(l10n.gpsQualityCreateCheck),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final eui = _euiCtrl.text.trim();
    if (eui.isEmpty) {
      setState(() => _euiError = l10n.gpsQualityRequiredField);
      return;
    }
    if (_testType == 'STATIC' && _rtkPointId == null) return;
    if (_testType == 'DYNAMIC' && _routeId == null) return;
    if (_startedAt == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(gpsQualityApiRepositoryProvider).createCheck(
        eui: eui,
        deviceCode: _deviceCodeCtrl.text.trim().isEmpty ? null : _deviceCodeCtrl.text.trim(),
        checkType: _testType,
        rtkPointId: _testType == 'STATIC' ? _rtkPointId : null,
        routeId: _testType == 'DYNAMIC' ? _routeId : null,
        startedAt: _startedAt!,
        endedAt: _endedAt,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ref.invalidate(checksProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
