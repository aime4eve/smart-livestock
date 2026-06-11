import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/l10n/gen/app_localizations.dart';

enum FenceUnsavedAction { save, discard, continueEditing }

Future<FenceUnsavedAction?> showFenceUnsavedDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<FenceUnsavedAction>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        key: const Key('fence-unsaved-dialog'),
        title: Text(l10n.fenceUnsavedTitle),
        content: Text(l10n.fenceUnsavedMessage),
        actions: [
          TextButton(
            key: const Key('fence-unsaved-continue'),
            onPressed: () => Navigator.of(dialogContext).pop(
              FenceUnsavedAction.continueEditing,
            ),
            child: Text(l10n.fenceUnsavedContinue),
          ),
          TextButton(
            key: const Key('fence-unsaved-discard'),
            onPressed: () => Navigator.of(dialogContext).pop(
              FenceUnsavedAction.discard,
            ),
            child: Text(l10n.fenceUnsavedDiscard),
          ),
          FilledButton(
            key: const Key('fence-unsaved-save'),
            onPressed: () => Navigator.of(dialogContext).pop(
              FenceUnsavedAction.save,
            ),
            child: Text(l10n.fenceUnsavedSaveExit),
          ),
        ],
      );
    },
  );
}
