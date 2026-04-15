import 'package:flutter/material.dart';

enum FenceUnsavedAction { save, discard, continueEditing }

Future<FenceUnsavedAction?> showFenceUnsavedDialog(BuildContext context) {
  return showDialog<FenceUnsavedAction>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        key: const Key('fence-unsaved-dialog'),
        title: const Text('有未保存修改'),
        content: const Text('你有未保存的边界修改。请选择下一步。'),
        actions: [
          TextButton(
            key: const Key('fence-unsaved-continue'),
            onPressed: () => Navigator.of(dialogContext).pop(
              FenceUnsavedAction.continueEditing,
            ),
            child: const Text('继续编辑'),
          ),
          TextButton(
            key: const Key('fence-unsaved-discard'),
            onPressed: () => Navigator.of(dialogContext).pop(
              FenceUnsavedAction.discard,
            ),
            child: const Text('放弃更改'),
          ),
          FilledButton(
            key: const Key('fence-unsaved-save'),
            onPressed: () => Navigator.of(dialogContext).pop(
              FenceUnsavedAction.save,
            ),
            child: const Text('保存并退出'),
          ),
        ],
      );
    },
  );
}
