import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hkt_livestock_agentic/features/tenant/domain/tenant.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class LicenseAdjustDialog extends StatefulWidget {
  const LicenseAdjustDialog({super.key, required this.tenant});

  final Tenant tenant;

  @override
  State<LicenseAdjustDialog> createState() => _LicenseAdjustDialogState();
}

class _LicenseAdjustDialogState extends State<LicenseAdjustDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.tenant.licenseTotal.toString());
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final n = int.tryParse(_ctrl.text);
    if (n == null || n < 0) {
      setState(() => _error = l10n.tenantLicenseInvalidInteger);
      return;
    }
    if (n < widget.tenant.licenseUsed) {
      setState(() => _error = l10n.tenantLicenseBelowUsed(widget.tenant.licenseUsed.toString()));
      return;
    }
    Navigator.of(context).pop(n);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.tenantAdjustLicenseTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.tenantAdjustLicenseUsed(widget.tenant.licenseUsed.toString())),
          const SizedBox(height: 12),
          TextField(
            key: const Key('tenant-license-input'),
            controller: _ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.tenantAdjustLicenseNew,
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('tenant-license-submit'),
          onPressed: _submit,
          child: Text(l10n.tenantAdjustLicenseConfirm),
        ),
      ],
    );
  }
}
