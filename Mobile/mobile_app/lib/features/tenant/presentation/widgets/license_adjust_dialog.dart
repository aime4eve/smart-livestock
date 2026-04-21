import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';

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
    final n = int.tryParse(_ctrl.text);
    if (n == null || n < 0) {
      setState(() => _error = '请输入非负整数');
      return;
    }
    if (n < widget.tenant.licenseUsed) {
      setState(() => _error = '新配额不能小于当前已使用量（${widget.tenant.licenseUsed}）');
      return;
    }
    Navigator.of(context).pop(n);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('调整 License 配额'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('当前已使用：${widget.tenant.licenseUsed}'),
          const SizedBox(height: 12),
          TextField(
            key: const Key('tenant-license-input'),
            controller: _ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: '新 License 配额',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          key: const Key('tenant-license-submit'),
          onPressed: _submit,
          child: const Text('确认调整'),
        ),
      ],
    );
  }
}
