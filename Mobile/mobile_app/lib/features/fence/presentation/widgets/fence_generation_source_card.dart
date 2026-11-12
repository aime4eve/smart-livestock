import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/utils/app_time.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Shared display-name mapping for the persisted `hullMethod` metadata
/// value ('concave' / 'convex' / 'concave_simplified', spec 修订 v2.1).
/// Returns null for missing/legacy-unknown values so callers hide the row.
/// The preview stat strip resolves the selected candidate through this same
/// function — single source of truth for algorithm display names.
String? hullMethodDisplayName(AppLocalizations l10n, Object? hullMethod) {
  return switch (hullMethod) {
    'concave' => l10n.fenceTrackHullConcave,
    'convex' => l10n.fenceTrackHullConvex,
    'concave_simplified' => l10n.fenceTrackHullConcaveSimplified,
    _ => null,
  };
}

/// "Generation source" card for fence detail surfaces (spec §4.3, prototype
/// .meta-card): shows how a fence was generated (method / device count /
/// track time range / generation time). Rendered only when the fence carries
/// `generationMetadata`; callers must null-check before mounting.
class FenceGenerationSourceCard extends StatelessWidget {
  const FenceGenerationSourceCard({super.key, required this.metadata});

  /// Raw `generationMetadata` map echoed by GET /fences (spec §4.3).
  final Map<String, dynamic> metadata;

  String _methodLabel(AppLocalizations l10n) {
    final method = metadata['method'];
    return switch (method) {
      'DEVICE_TRACK' => l10n.fenceTrackDraftMethodDeviceTrack,
      String s => s,
      _ => '',
    };
  }

  /// Hull algorithm row; hidden for legacy fences without the key.
  String? _hullLabel(AppLocalizations l10n) =>
      hullMethodDisplayName(l10n, metadata['hullMethod']);

  int? get _deviceCount {
    final ids = metadata['deviceIds'];
    return ids is List ? ids.length : null;
  }

  String? get _timeRange {
    final start = parseApiTime(metadata['startTime'] as String?);
    final end = parseApiTime(metadata['endTime'] as String?);
    if (start == null || end == null) return null;
    final fmt = DateFormat('yyyy-MM-dd');
    return '${fmt.format(start)} ~ ${fmt.format(end)}';
  }

  String? get _generatedAt {
    final at = parseApiTime(metadata['generatedAt'] as String?);
    return at == null ? null : formatYmdhm(at);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = <({String label, String value})>[
      (label: l10n.fenceTrackDraftSourceMethod, value: _methodLabel(l10n)),
      if (_hullLabel(l10n) != null)
        (label: l10n.fenceTrackDraftStatHull, value: _hullLabel(l10n)!),
      if (_deviceCount != null)
        (
          label: l10n.fenceTrackDraftMetaDevices,
          value: l10n.fenceTrackDraftSourceDeviceCount(_deviceCount!),
        ),
      if (_timeRange != null)
        (
          label: l10n.fenceTrackDraftSourceTimeRange,
          value: _timeRange!,
        ),
      if (_generatedAt != null)
        (
          label: l10n.fenceTrackDraftSourceGeneratedAt,
          value: _generatedAt!,
        ),
    ].where((r) => r.value.isNotEmpty).toList();

    return Container(
      key: const Key('fence-generation-source-card'),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.fenceTrackDraftSourceCardTitle,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 5),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      row.label,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
