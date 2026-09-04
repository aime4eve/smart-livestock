import 'package:flutter/material.dart';

import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/core/map/map_constants.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/fence_item.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

enum FenceTemplate { rectangle, circle }

class FenceTemplatePreset {
  const FenceTemplatePreset({
    required this.template,
    required this.type,
    required this.drawingPoints,
    required this.focusPoint,
  });

  final FenceTemplate template;
  final FenceType type;
  final List<LatLng> drawingPoints;
  final LatLng focusPoint;
}

/// 生成模板预设。[anchor] 为模板形状的落点（屏幕坐标系），
/// 默认保持演示区域中心，实际调用方应传当前牧场坐标。
FenceTemplatePreset fenceTemplatePresetFor(
  FenceTemplate template, {
  LatLng anchor = MapConstants.mapCenter,
}) {
  return switch (template) {
    FenceTemplate.rectangle => FenceTemplatePreset(
        template: template,
        type: FenceType.rectangle,
        drawingPoints: [
          LatLng(anchor.latitude + 0.0012, anchor.longitude - 0.0016),
          LatLng(anchor.latitude - 0.0011, anchor.longitude + 0.0018),
        ],
        focusPoint: anchor,
      ),
    FenceTemplate.circle => FenceTemplatePreset(
        template: template,
        type: FenceType.circle,
        drawingPoints: [
          anchor,
          LatLng(anchor.latitude + 0.0013, anchor.longitude + 0.0002),
        ],
        focusPoint: anchor,
      ),
  };
}

class FenceTemplatePicker extends StatelessWidget {
  const FenceTemplatePicker({
    super.key,
    required this.selectedTemplate,
    required this.onSelected,
  });

  final FenceTemplate? selectedTemplate;
  final ValueChanged<FenceTemplate> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.fenceTemplateTitle,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.fenceTemplateDesc,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _FenceTemplateAction(
              key: const Key('fence-template-rectangle'),
              label: l10n.fenceTemplateRectangle,
              icon: Icons.crop_square,
              selected: selectedTemplate == FenceTemplate.rectangle,
              onTap: () => onSelected(FenceTemplate.rectangle),
            ),
            _FenceTemplateAction(
              key: const Key('fence-template-circle'),
              label: l10n.fenceTemplateCircle,
              icon: Icons.circle_outlined,
              selected: selectedTemplate == FenceTemplate.circle,
              onTap: () => onSelected(FenceTemplate.circle),
            ),
          ],
        ),
      ],
    );
  }
}

class _FenceTemplateAction extends StatelessWidget {
  const _FenceTemplateAction({
    required super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 112),
      child: selected
          ? FilledButton.tonalIcon(
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(label),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(label),
            ),
    );
  }
}

