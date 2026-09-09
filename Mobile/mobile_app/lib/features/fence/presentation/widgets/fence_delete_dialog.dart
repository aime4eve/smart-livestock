import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// 历史告警的处理方式：保留（解除关联）或连同围栏一起删除。
enum FenceDeleteAlertsChoice { keep, deleteWithAlerts }

/// 删除围栏的确认对话框。
///
/// 返回所选的告警处理方式；用户取消时返回 null。
/// 后端语义见 FenceController.deleteFence 的 deleteAlerts 参数：
/// keep → deleteAlerts=false（告警保留，仅解除 fence_id 关联）；
/// deleteWithAlerts → deleteAlerts=true（历史告警一并删除）。
Future<FenceDeleteAlertsChoice?> showFenceDeleteConfirmDialog(
  BuildContext context, {
  required String fenceName,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<FenceDeleteAlertsChoice>(
    context: context,
    builder: (ctx) {
      var choice = FenceDeleteAlertsChoice.keep;
      return StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.commonConfirmDelete),
          content: RadioGroup<FenceDeleteAlertsChoice>(
            groupValue: choice,
            onChanged: (v) => setDialogState(() => choice = v ?? choice),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.ranchConfirmDeleteFence(fenceName)),
                const SizedBox(height: 8),
                Text(l10n.fenceDeleteAlertsPrompt),
                RadioListTile<FenceDeleteAlertsChoice>(
                  key: const Key('fence-delete-choice-keep'),
                  value: FenceDeleteAlertsChoice.keep,
                  title: Text(l10n.fenceDeleteKeepAlerts),
                ),
                RadioListTile<FenceDeleteAlertsChoice>(
                  key: const Key('fence-delete-choice-with-alerts'),
                  value: FenceDeleteAlertsChoice.deleteWithAlerts,
                  title: Text(
                    l10n.fenceDeleteWithAlerts,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              key: const Key('fence-delete-cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              key: const Key('fence-delete-confirm'),
              onPressed: () => Navigator.of(ctx).pop(choice),
              child: Text(l10n.commonDelete,
                  style: const TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      );
    },
  );
}
