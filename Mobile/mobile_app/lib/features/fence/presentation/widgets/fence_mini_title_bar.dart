import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class FenceMiniTitleBar extends StatelessWidget {
  const FenceMiniTitleBar({
    super.key,
    required this.fenceName,
    required this.onBack,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
  });

  final String fenceName;
  final VoidCallback onBack;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const Key('fence-edit-mini-title'),
      height: 48,
      color: AppColors.overlayDark,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              key: const Key('fence-edit-back'),
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: l10n.commonBack,
              iconSize: 20,
            ),
            Expanded(
              child: Text(
                l10n.fenceEditTitle(fenceName),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              key: const Key('fence-edit-undo'),
              onPressed: canUndo ? onUndo : null,
              icon: Icon(
                Icons.undo,
                color: canUndo ? Colors.white : Colors.white38,
              ),
              tooltip: l10n.fenceEditUndo,
              iconSize: 20,
            ),
            IconButton(
              key: const Key('fence-edit-redo'),
              onPressed: canRedo ? onRedo : null,
              icon: Icon(
                Icons.redo,
                color: canRedo ? Colors.white : Colors.white38,
              ),
              tooltip: l10n.fenceEditRedo,
              iconSize: 20,
            ),
          ],
        ),
      ),
    );
  }
}
