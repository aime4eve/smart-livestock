import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/core/map/map_constants.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/fence_item.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

enum FenceTemplate { rectangle, circle, trajectoryBuffer }

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

FenceTemplatePreset fenceTemplatePresetFor(FenceTemplate template) {
  return switch (template) {
    FenceTemplate.rectangle => FenceTemplatePreset(
        template: template,
        type: FenceType.rectangle,
        drawingPoints: const [
          LatLng(28.2294, 112.9372),
          LatLng(28.2271, 112.9406),
        ],
        focusPoint: MapConstants.mapCenter,
      ),
    FenceTemplate.circle => FenceTemplatePreset(
        template: template,
        type: FenceType.circle,
        drawingPoints: const [
          MapConstants.mapCenter,
          LatLng(28.2295, 112.9390),
        ],
        focusPoint: MapConstants.mapCenter,
      ),
    FenceTemplate.trajectoryBuffer => FenceTemplatePreset(
        template: template,
        type: FenceType.polygon,
        drawingPoints: _trajectoryBufferPolygon(),
        focusPoint: _trajectoryCenter(),
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
            _FenceTemplateAction(
              key: const Key('fence-template-trajectory-buffer'),
              label: l10n.fenceTemplateTrajectoryBuffer,
              icon: Icons.route,
              selected: selectedTemplate == FenceTemplate.trajectoryBuffer,
              onTap: () => onSelected(FenceTemplate.trajectoryBuffer),
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

List<LatLng> _trajectoryBufferPolygon() {
  const anchors = MapConstants.gpsAnchorPoints;
  if (anchors.length < 2) {
    return FenceItem.defaultPointsForType(FenceType.polygon, MapConstants.mapCenter);
  }

  const buffer = 0.0007;
  final left = <LatLng>[];
  final right = <LatLng>[];

  for (var i = 0; i < anchors.length; i++) {
    final current = anchors[i];
    final previous = i == 0 ? anchors[i] : anchors[i - 1];
    final next = i == anchors.length - 1 ? anchors[i] : anchors[i + 1];

    var directionLat = next.latitude - previous.latitude;
    var directionLng = next.longitude - previous.longitude;
    final length = sqrt(directionLat * directionLat + directionLng * directionLng);

    if (length == 0) {
      directionLat = 1;
      directionLng = 0;
    } else {
      directionLat /= length;
      directionLng /= length;
    }

    final normalLat = -directionLng;
    final normalLng = directionLat;
    final lngScale = max(cos(current.latitude * pi / 180).abs(), 0.2);
    final offsetLat = normalLat * buffer;
    final offsetLng = normalLng * buffer / lngScale;

    left.add(
      LatLng(
        current.latitude + offsetLat,
        current.longitude + offsetLng,
      ),
    );
    right.add(
      LatLng(
        current.latitude - offsetLat,
        current.longitude - offsetLng,
      ),
    );
  }

  return [...left, ...right.reversed];
}

LatLng _trajectoryCenter() {
  const anchors = MapConstants.gpsAnchorPoints;
  if (anchors.isEmpty) {
    return MapConstants.mapCenter;
  }

  var lat = 0.0;
  var lng = 0.0;
  for (final point in anchors) {
    lat += point.latitude;
    lng += point.longitude;
  }
  return LatLng(lat / anchors.length, lng / anchors.length);
}
