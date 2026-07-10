import 'package:flutter/material.dart';

class B2bConfirmDialog extends StatelessWidget {
  const B2bConfirmDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.confirmLabel = '确认',
    this.cancelLabel = '取消',
    this.isDestructive = false,
  });

  final String title;
  final String? subtitle;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    String confirmLabel = '确认',
    String cancelLabel = '取消',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => B2bConfirmDialog(
        title: title,
        subtitle: subtitle,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: subtitle != null ? Text(subtitle!) : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
