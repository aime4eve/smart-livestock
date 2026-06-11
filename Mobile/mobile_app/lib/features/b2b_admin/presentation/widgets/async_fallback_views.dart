import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/l10n/gen/app_localizations.dart';

class B2bErrorView extends StatelessWidget {
  const B2bErrorView({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.commonLoadFailed,
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.error)),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(message, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

class B2bEmptyView extends StatelessWidget {
  const B2bEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: theme.disabledColor),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.commonNoData, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
