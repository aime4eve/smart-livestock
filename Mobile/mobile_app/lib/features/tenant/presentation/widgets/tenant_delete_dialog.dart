import 'package:flutter/material.dart';

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
    if (_reasonCtrl.text.trim().isEmpty) {
      setState(() => _error = '请输入删除原因');
      return;
    }
    Navigator.of(context).pop(_reasonCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('删除租户'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('即将删除租户「${widget.tenantName}」。该操作不可撤销。'),
          const SizedBox(height: 12),
          TextField(
            key: const Key('tenant-delete-reason'),
            controller: _reasonCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: '删除原因',
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
          key: const Key('tenant-delete-confirm'),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _confirm,
          child: const Text('确认删除'),
        ),
      ],
    );
  }
}
