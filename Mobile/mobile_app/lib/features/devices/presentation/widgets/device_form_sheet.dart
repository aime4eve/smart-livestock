import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/devices/domain/devices_repository.dart';
import 'package:hkt_livestock_agentic/features/devices/presentation/devices_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class DeviceFormSheet extends ConsumerStatefulWidget {
  const DeviceFormSheet({super.key, this.existing});

  final DeviceItem? existing;

  @override
  ConsumerState<DeviceFormSheet> createState() => _DeviceFormSheetState();
}

class _DeviceFormSheetState extends ConsumerState<DeviceFormSheet> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _euiCtrl;
  DeviceType _type = DeviceType.gps;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _euiCtrl = TextEditingController();
    if (widget.existing != null) _type = widget.existing!.type;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _euiCtrl.dispose();
    super.dispose();
  }

  String _typeToApi(DeviceType t) => switch (t) {
    DeviceType.gps => 'TRACKER',
    DeviceType.rumenCapsule => 'CAPSULE',
    DeviceType.earTag => 'EAR_TAG',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _isEdit ? l10n.deviceEditTitle : l10n.deviceRegisterTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Code
            TextField(
              key: const Key('device-form-code'),
              controller: _codeCtrl,
              decoration: InputDecoration(
                labelText: l10n.deviceFormFieldCode,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Type
            SegmentedButton<DeviceType>(
              segments: [
                ButtonSegment(value: DeviceType.gps, label: Text(l10n.deviceTypeGps)),
                ButtonSegment(value: DeviceType.rumenCapsule, label: Text(l10n.deviceTypeRumenCapsule)),
                ButtonSegment(value: DeviceType.earTag, label: Text(l10n.deviceTypeEarTag)),
              ],
              selected: {_type},
              onSelectionChanged: _isEdit ? null : (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            // devEui
            TextField(
              key: const Key('device-form-devEui'),
              controller: _euiCtrl,
              decoration: InputDecoration(
                labelText: l10n.deviceFormFieldDevEui,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.commonCancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    key: const Key('device-form-submit'),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.commonConfirm),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    final body = <String, dynamic>{
      'deviceCode': _codeCtrl.text.trim(),
      'deviceType': _typeToApi(_type),
      if (_euiCtrl.text.trim().isNotEmpty) 'devEui': _euiCtrl.text.trim(),
    };
    try {
      final repo = ref.read(devicesRepositoryProvider);
      if (_isEdit) {
        await repo.update(widget.existing!.id, body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.deviceUpdateSuccess)));
          Navigator.of(context).pop();
        }
      } else {
        await repo.create(body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.deviceRegisterSuccess)));
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
