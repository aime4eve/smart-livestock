import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/l10n/gen/app_localizations.dart';

class TenantDeleteDialog extends StatefulWidget {
  const TenantDeleteDialog({super.key, required this.tenantName});

  final String tenantName;

  @override
  State<TenantDeleteDialog> createState() => _TenantDeleteDialogState();
}

class _TenantDeleteDialogState extends State<TenantDeleteDialog> {
  final _reasonCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final l10n = AppLocalizations.of(context)!;
    if (_reasonCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.tenantDeleteReasonRequired);
      return;
    }
    Navigator.of(context).pop(_reasonCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.tenantDeleteTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.tenantDeleteMessage(widget.tenantName)),
          const SizedBox(height: 12),
          TextField(
            key: const Key('tenant-delete-reason'),
            controller: _reasonCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.tenantDeleteReason,
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
          key: const Key('tenant-delete-confirm'),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _confirm,
          child: Text(l10n.commonConfirmDelete),
        ),
      ],
    );
  }
}
