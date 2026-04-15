import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_edit_session.dart';

class FenceEditToolbar extends StatelessWidget {
  const FenceEditToolbar({
    super.key,
    this.isEditing = true,
    required this.activeTool,
    required this.onSave,
    required this.onExit,
    required this.onUndo,
    required this.onRedo,
    required this.onSelectTool,
    this.canSave = true,
    this.canExit = true,
    this.canUndo = true,
    this.canRedo = true,
    this.canSelectTool = true,
  });

  final bool isEditing;
  final FenceEditTool activeTool;
  final VoidCallback onSave;
  final VoidCallback onExit;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final ValueChanged<FenceEditTool> onSelectTool;
  final bool canSave;
  final bool canExit;
  final bool canUndo;
  final bool canRedo;
  final bool canSelectTool;

  @override
  Widget build(BuildContext context) {
    if (!isEditing) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const Key('fence-edit-toolbar'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.surfaceAlt,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            key: const Key('fence-edit-exit'),
            onPressed: canExit ? onExit : null,
            icon: const Icon(Icons.close),
            tooltip: '退出编辑',
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ToolButton(
                    widgetKey: 'fence-edit-tool-move',
                    icon: Icons.open_with,
                    label: '拖点',
                    active: activeTool == FenceEditTool.moveVertex,
                    onPressed: canSelectTool
                        ? () => onSelectTool(FenceEditTool.moveVertex)
                        : null,
                  ),
                  _ToolButton(
                    widgetKey: 'fence-edit-tool-insert',
                    icon: Icons.add_circle_outline,
                    label: '插点',
                    active: activeTool == FenceEditTool.insertVertex,
                    onPressed: canSelectTool
                        ? () => onSelectTool(FenceEditTool.insertVertex)
                        : null,
                  ),
                  _ToolButton(
                    widgetKey: 'fence-edit-tool-delete',
                    icon: Icons.remove_circle_outline,
                    label: '删点',
                    active: activeTool == FenceEditTool.deleteVertex,
                    onPressed: canSelectTool
                        ? () => onSelectTool(FenceEditTool.deleteVertex)
                        : null,
                  ),
                  _ToolButton(
                    widgetKey: 'fence-edit-tool-translate',
                    icon: Icons.pan_tool_alt_outlined,
                    label: '平移',
                    active: activeTool == FenceEditTool.translate,
                    onPressed: canSelectTool
                        ? () => onSelectTool(FenceEditTool.translate)
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            key: const Key('fence-edit-undo'),
            onPressed: canUndo ? onUndo : null,
            icon: const Icon(Icons.undo),
            tooltip: '撤销',
          ),
          IconButton(
            key: const Key('fence-edit-redo'),
            onPressed: canRedo ? onRedo : null,
            icon: const Icon(Icons.redo),
            tooltip: '重做',
          ),
          FilledButton(
            key: const Key('fence-edit-save'),
            onPressed: canSave ? onSave : null,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.widgetKey,
    required this.icon,
    required this.label,
    required this.active,
    required this.onPressed,
  });

  final String widgetKey;
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final child = active
        ? FilledButton.tonalIcon(
            key: Key(widgetKey),
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          )
        : OutlinedButton.icon(
            key: Key(widgetKey),
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          );
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: child,
    );
  }
}
