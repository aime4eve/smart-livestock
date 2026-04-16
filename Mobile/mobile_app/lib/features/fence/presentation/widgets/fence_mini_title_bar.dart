import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';

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
              tooltip: '返回',
              iconSize: 20,
            ),
            Expanded(
              child: Text(
                '编辑围栏：$fenceName',
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
              tooltip: '撤销',
              iconSize: 20,
            ),
            IconButton(
              key: const Key('fence-edit-redo'),
              onPressed: canRedo ? onRedo : null,
              icon: Icon(
                Icons.redo,
                color: canRedo ? Colors.white : Colors.white38,
              ),
              tooltip: '重做',
              iconSize: 20,
            ),
          ],
        ),
      ),
    );
  }
}
