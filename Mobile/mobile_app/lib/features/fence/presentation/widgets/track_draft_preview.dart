import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:hkt_livestock_agentic/core/map/map_config.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_draft_area.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_to_envelope_converter.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/track_draft_controller.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/widgets/fence_generation_source_card.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/widgets/track_draft_device_picker.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/widgets/track_draft_range_picker.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Preview step (wizard step 3 / desktop map area), spec §3.4/§3.5:
/// envelope draft (dashed = unconfirmed) over semi-transparent track dots
/// + amber roaming-trimmed points, dark stat strip, legend, source card,
/// and the shared failure layout with the cleaning-detail strip.
class TrackDraftPreview extends ConsumerStatefulWidget {
  const TrackDraftPreview({
    super.key,
    this.isDesktop = false,
    this.onConfirm,
    this.onBack,
  });

  /// Desktop (≥900px) form: larger radii, [8,4] dash, floating overlays.
  final bool isDesktop;

  /// 「载入围栏表单」— Task 5 wires this to the fence form callback.
  final VoidCallback? onConfirm;

  /// Desktop-only「‹ 返回表单」floating button.
  final VoidCallback? onBack;

  @override
  ConsumerState<TrackDraftPreview> createState() => _TrackDraftPreviewState();

  // Amber value on the dark stat strip (prototype .stat-cell .v.warn) —
  // referenced by the stat strip cell builder below.
  static const _trimmedAmber = Color(0xFFF2C879);
}

class _TrackDraftPreviewState extends ConsumerState<TrackDraftPreview> {
  final MapController _mapController = MapController();
  TrackDraftState? _lastFitState;
  TrackDraftState? _pendingFit;
  bool _mapReady = false;

  /// Runs the deferred camera fit once the FlutterMap has rendered at least
  /// once (MapController throws before that — the fit must never run on an
  /// unrendered map).
  int _fitRetries = 0;

  void _flushPendingFit() {
    final pending = _pendingFit;
    if (pending == null || !mounted) return;
    final vertices = pending.preview?.envelope.vertices;
    if (vertices == null || vertices.length < 3) {
      _pendingFit = null;
      return;
    }
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(vertices),
          padding: const EdgeInsets.all(48),
        ),
      );
      // Success: clear the pending fit and reset the retry budget.
      _pendingFit = null;
      _fitRetries = 0;
    } catch (_) {
      // FlutterMap not rendered yet (MapController throws before the first
      // draw even inside onMapReady under fake-async timing) — keep the
      // pending fit and retry next frame, bounded so a never-rendered map
      // cannot spin forever.
      if (++_fitRetries < 30) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _flushPendingFit());
      } else {
        _pendingFit = null;
        _fitRetries = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackDraftControllerProvider);
    // Re-fit the camera whenever a NEW preview arrives (regenerate after
    // parameter changes / hull candidate switch). Fit target = the envelope
    // outline only — including the raw track dots would blow the bounds out
    // to the farthest stray GPS point and shrink the fence to a fraction of
    // the viewport (integration-test feedback 2026-11-12 #4).
    //
    // The fit must wait for the FlutterMap to have rendered at least once
    // (MapController throws before that) — hence the onMapReady gate + the
    // pending-fit flush in _flushPendingFit.
    if (!identical(state, _lastFitState) &&
        state.phase == TrackDraftPhase.previewing &&
        state.preview != null) {
      _lastFitState = state;
      _pendingFit = state;
      if (_mapReady) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _flushPendingFit());
      }
    }
    final preview = state.preview;
    if (state.phase == TrackDraftPhase.failed) {
      return _FailureView(isDesktop: widget.isDesktop);
    }

    if (preview == null || !preview.envelope.isSuccess) {
      // No successful preview yet (fresh desktop panel, or first load).
      if (state.phase == TrackDraftPhase.loading) {
        return const _GeneratingView();
      }
      return _EmptyPreview(isDesktop: widget.isDesktop);
    }

    final content = widget.isDesktop
        ? _desktopLayout(context, state)
        : _mobileLayout(context, state);

    if (state.phase == TrackDraftPhase.loading) {
      // Loading keeps the old preview under a translucent overlay (§5.4).
      return Stack(
        children: [
          content,
          const Positioned.fill(child: _LoadingOverlay()),
        ],
      );
    }
    return content;
  }

  // Component-level visual constants (Task 0 token mapping §1.1/§1.3):
  // dash [5,3] mobile / [8,4] web, opacities .35/.14/.8 (amber: see
  // TrackDraftPreview._trimmedAmber).

  // ── Mobile (wizard step 3) ─────────────────────────────────────────

  Widget _mobileLayout(BuildContext context, TrackDraftState state) {
    final preview = state.preview!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _mapStack(context, state, floating: false)),
        const SizedBox(height: AppSpacing.sm),
        _Legend(trimmed: preview.envelope.roamingTrimmed),
        const SizedBox(height: AppSpacing.xs),
        const _HullMethodChips(),
        const SizedBox(height: AppSpacing.xs),
        _StatStrip.success(
            preview: preview,
            includeHull: false,
            languageCode: Localizations.localeOf(context).languageCode),
        const SizedBox(height: AppSpacing.xs),
        _SourceCard(),
      ],
    );
  }

  // ── Desktop (map area of the ≥900px panel) ─────────────────────────

  Widget _desktopLayout(BuildContext context, TrackDraftState state) {
    final preview = state.preview!;
    return _mapStack(
      context,
      state,
      floating: true,
      overlayBottom: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _HullMethodChips(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _StatStrip.success(
                    preview: preview,
                    includeHull: true,
                    languageCode: Localizations.localeOf(context).languageCode,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _LegendCard(trimmed: preview.envelope.roamingTrimmed),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapStack(
    BuildContext context,
    TrackDraftState state, {
    required bool floating,
    Widget? overlayBottom,
  }) {
    final preview = state.preview!;
    final envelope = preview.envelope;
    final allPoints = <LatLng>[
      for (final p in preview.trackDots) p.toLatLng(),
      ...envelope.vertices,
    ];
    final map = Container(
      decoration: BoxDecoration(
        color: AppColors.mapGreen,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(allPoints),
            padding: const EdgeInsets.all(48),
          ),
          onMapReady: () {
            _mapReady = true;
            _flushPendingFit();
          },
          interactionOptions:
              const InteractionOptions(flags: InteractiveFlag.all),
        ),
        children: [
          TileLayer(
            urlTemplate: MapConfig.tileUrlTemplate,
            userAgentPackageName: 'com.smartlivestock.demo',
          ),
          // ① Track dots: info @ .35 (r2 mobile / r3 web).
          CircleLayer(
            circles: [
              for (final p in preview.trackDots)
                CircleMarker(
                  point: p.toLatLng(),
                  radius: widget.isDesktop ? 3 : 2,
                  color: AppColors.info.withValues(alpha: 0.35),
                ),
            ],
          ),
          // ② Roaming-trimmed points: warning @ .8 (r2.5 / r4).
          CircleLayer(
            circles: [
              for (final p in envelope.trimmedPoints)
                CircleMarker(
                  point: p.toLatLng(),
                  radius: widget.isDesktop ? 4 : 2.5,
                  color: AppColors.warning.withValues(alpha: 0.8),
                ),
            ],
          ),
          // ③ Envelope draft: success @ .14 fill + dashed primary stroke.
          PolygonLayer(
            polygons: [
              Polygon(
                points: envelope.vertices,
                color: AppColors.success.withValues(alpha: 0.14),
                borderColor: AppColors.primary,
                borderStrokeWidth: widget.isDesktop ? 2.5 : 2,
                pattern: StrokePattern.dashed(
                  segments: widget.isDesktop ? const [8, 4] : const [5, 3],
                ),
              ),
            ],
          ),
          // Envelope vertices: solid primary dots (r3 / r5).
          CircleLayer(
            circles: [
              for (final v in envelope.vertices)
                CircleMarker(
                  point: v,
                  radius: widget.isDesktop ? 5 : 3,
                  color: AppColors.primary,
                ),
            ],
          ),
        ],
      ),
    );

    return Stack(
      key: const Key('track-draft-preview-map'),
      fit: StackFit.expand,
      children: [
        map,
        if (state.previewStale)
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            child: _StaleBadge(),
          ),
        if (floating && widget.onConfirm != null)
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onBack != null) ...[
                  _WebButton.soft(
                    label: '‹ ${_l10n(context).commonBack}',
                    onTap: widget.onBack!,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                _WebButton.primary(
                  key: const Key('track-draft-confirm'),
                  label: '${_l10n(context).fenceTrackDraftConfirm} ✓',
                  // Stale previews must be regenerated before loading
                  // into the form (spec §5.4).
                  onTap: state.previewStale ? null : widget.onConfirm!,
                ),
              ],
            ),
          ),
        if (overlayBottom != null)
          Positioned(left: 0, right: 0, bottom: 0, child: overlayBottom),
      ],
    );
  }

  static AppLocalizations _l10n(BuildContext context) =>
      AppLocalizations.of(context)!;
}

// ── Generating / empty placeholders ──────────────────────────────────

class _GeneratingView extends StatelessWidget {
  const _GeneratingView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      key: const Key('track-draft-generating'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.fenceTrackDraftGenerating,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: AppColors.surfaceAlt.withValues(alpha: 0.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.fenceTrackDraftGenerating,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const Key('track-draft-preview-empty'),
      decoration: BoxDecoration(
        color: AppColors.mapGreen,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route,
                size: 32, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.fenceTrackDraftGenerate,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Legend ───────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend({required this.trimmed});

  final int trimmed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      key: const Key('track-draft-legend'),
      spacing: 12,
      runSpacing: 4,
      children: [
        _legendItem(
          label: l10n.fenceTrackDraftLegendEnvelope,
          swatch: Container(
            width: 14,
            height: 9,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.14),
              border: Border.all(color: AppColors.primary, width: 1.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        _legendItem(
          label: l10n.fenceTrackDraftLegendTrackDots,
          swatch: _dot(AppColors.info.withValues(alpha: 0.5)),
        ),
        _legendItem(
          label: l10n.fenceTrackDraftLegendTrimmed(trimmed),
          swatch: _dot(AppColors.warning),
        ),
      ],
    );
  }

  static Widget _dot(Color color) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  static Widget _legendItem({required String label, required Widget swatch}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Desktop floating legend card (white capsule, shadow-elev).
class _LegendCard extends StatelessWidget {
  const _LegendCard({required this.trimmed});

  final int trimmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          // Prototype --shadow-elev (component-level value).
          BoxShadow(
            color: Color(0x29263126),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: _Legend(trimmed: trimmed),
    );
  }
}

// ── Hull algorithm switcher (spec 修订 v2.1) ─────────────────────────

/// Algorithm switcher chips shown above the stat strip (mobile + desktop
/// share this widget). Renders the three candidates from the controller;
/// unavailable ones are greyed out and non-tappable. Pure Riverpod state —
/// no setState.
class _HullMethodChips extends ConsumerWidget {
  const _HullMethodChips();

  /// Switcher Keys follow the task contract (dash-separated), while the
  /// persisted metadata key is snake_case.
  static String _chipKey(HullMethod method) => switch (method) {
        HullMethod.concave => 'track-draft-hull-concave',
        HullMethod.convex => 'track-draft-hull-convex',
        HullMethod.concaveSimplified => 'track-draft-hull-concave-simplified',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackDraftControllerProvider);
    if (state.hullCandidates.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(trackDraftControllerProvider.notifier);
    return Row(
      key: const Key('track-draft-hull-switcher'),
      children: [
        for (var i = 0; i < state.hullCandidates.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _HullChip(
              key: Key(_chipKey(state.hullCandidates[i].method)),
              label: hullMethodDisplayName(
                    l10n,
                    state.hullCandidates[i].method.metadataKey,
                  ) ??
                  state.hullCandidates[i].method.metadataKey,
              selected: state.selectedHullMethod ==
                  state.hullCandidates[i].method,
              enabled: state.hullCandidates[i].isAvailable,
              onTap: () => controller.selectHullMethod(
                state.hullCandidates[i].method,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Capsule chip mirroring the range-picker chips (fidelity §4): selected =
/// solid primary with white text, unselected = white bg + border +
/// textSecondary, disabled = border-colored bg (greyed out).
class _HullChip extends StatelessWidget {
  const _HullChip({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : enabled
                  ? AppColors.surfaceAlt
                  : AppColors.border,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected
                ? Colors.white
                : enabled
                    ? AppColors.textSecondary
                    : Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

// ── Stat strip ───────────────────────────────────────────────────────

class _StatCellData {
  const _StatCellData(this.value, this.label, {this.amber = false});

  final String value;
  final String label;
  final bool amber;
}

class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.cells});

  factory _StatStrip.success({
    required TrackDraftPreviewData preview,
    required bool includeHull,
    required String languageCode,
  }) {
    // Labels resolve in build(); store the preview and flag via a
    // closure-friendly wrapper instead.
    return _StatStrip(
        cells: _successCells(preview, includeHull, languageCode));
  }

  factory _StatStrip.failure({TrackToEnvelopeResult? result}) {
    return _StatStrip(cells: _failureCells(result));
  }

  final List<_StatCellData> cells;

  // Label lookups need l10n; resolved lazily in build via _labels.
  static List<_StatCellData> _successCells(TrackDraftPreviewData preview,
          bool includeHull, String languageCode) =>
      // Placeholder labels replaced in build (see _resolveLabels).
      [
        _StatCellData(
            formatPointCount(preview.envelope.remainingValid), 'valid'),
        _StatCellData(formatPointCount(preview.envelope.roamingTrimmed),
            'trimmed',
            amber: true),
        _StatCellData('${preview.envelope.vertexCount}', 'vertices'),
        _StatCellData(_areaLabel(languageCode, preview.areaM2), 'area'),
        // 5th cell「生成方式」follows the selected hull candidate (spec 修订
        // v2.1); the raw metadata key resolves through the shared mapping.
        if (includeHull)
          _StatCellData(preview.envelope.method.metadataKey, 'hull'),
      ];

  static List<_StatCellData> _failureCells(TrackToEnvelopeResult? result) => [
        _StatCellData(formatPointCount(result?.rawCount ?? 0), 'raw'),
        _StatCellData(formatPointCount(result?.accuracyDropped ?? 0),
            'accuracyDropped',
            amber: true),
        _StatCellData(formatPointCount(result?.roamingTrimmed ?? 0),
            'roaming',
            amber: true),
        _StatCellData(formatPointCount(result?.remainingValid ?? 0),
            'remaining',
            amber: true),
      ];

  static String _areaLabel(String languageCode, double areaM2) {
    // Locale-unit value (zh: mu 1dp / others: ha 2dp); below the display
    // floor it degrades to raw ㎡ via the sqm: marker resolved in build
    // with fenceTrackDraftAreaSqmFallback.
    final area = formatAreaForLocale(languageCode, areaM2);
    return area.fallback ? 'sqm:${area.value}' : area.value;
  }

  String _resolveLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    return switch (key) {
      'valid' => l10n.fenceTrackDraftStatValid,
      'trimmed' => l10n.fenceTrackDraftStatTrimmed,
      'vertices' => l10n.fenceTrackDraftStatVertices,
      'area' => l10n.fenceTrackDraftStatArea,
      'hull' => l10n.fenceTrackDraftStatHull,
      'raw' => l10n.fenceTrackDraftStatRaw,
      'accuracyDropped' => l10n.fenceTrackDraftStatAccuracyDropped,
      'roaming' => l10n.fenceTrackDraftStatRoaming,
      'remaining' => l10n.fenceTrackDraftStatRemaining,
      _ => key,
    };
  }

  String _resolveValue(BuildContext context, _StatCellData cell) {
    final l10n = AppLocalizations.of(context)!;
    if (cell.value.startsWith('sqm:')) {
      final n = int.tryParse(cell.value.substring(4)) ?? 0;
      return l10n.fenceTrackDraftAreaSqmFallback(n);
    }
    // Hull algorithm names resolve through the shared metadata-key mapping
    // (legacy two-value fences included); anything else prints as-is.
    return hullMethodDisplayName(l10n, cell.value) ?? cell.value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('track-draft-stat-strip'),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        // stat-strip-bg = AppColors.textPrimary (#263126, same-value reuse).
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29263126),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 24,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _resolveValue(context, cells[i]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: cells[i].amber
                          ? TrackDraftPreview._trimmedAmber
                          : Colors.white,
                    ),
                  ),
                  Text(
                    _resolveLabel(context, cells[i].label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Source card ──────────────────────────────────────────────────────

class _SourceCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final preview = ref.watch(trackDraftControllerProvider).preview!;
    String fmt(DateTime t) {
      String two(int v) => v.toString().padLeft(2, '0');
      return '${t.year}-${two(t.month)}-${two(t.day)}';
    }

    return TrackDraftMetaCard(
      key: const Key('track-draft-source-card'),
      icon: Icons.receipt_long,
      title: l10n.fenceTrackDraftPreviewSourceTitle,
      rows: [
        (
          l10n.fenceTrackDraftMetaDevices,
          _joinNames(context, preview.deviceNames),
        ),
        (
          l10n.fenceTrackDraftMetaTimeRange,
          '${fmt(preview.startTime)} ~ ${fmt(preview.endTime)}',
        ),
      ],
    );
  }
}

/// Locale-aware device-name separator (review 低6): zh uses the
/// ideographic comma, everything else a plain comma.
String _joinNames(BuildContext context, List<String> names) => names.join(
      Localizations.localeOf(context).languageCode == 'zh' ? '、' : ', ',
    );

// ── Stale badge ──────────────────────────────────────────────────────

class _StaleBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const Key('track-draft-stale-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 12, color: AppColors.warning),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              l10n.fenceTrackDraftStaleNotice,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.warning,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Failure view (spec §3.5) ─────────────────────────────────────────

class _FailureView extends ConsumerWidget {
  const _FailureView({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(trackDraftControllerProvider);
    final reason = state.failReason ?? TrackDraftFailReason.error;

    final (title, desc) = switch (reason) {
      TrackDraftFailReason.noData => (
          l10n.fenceTrackDraftFailNoData,
          l10n.fenceTrackDraftFailNoDataDesc,
        ),
      TrackDraftFailReason.tooFew => (
          l10n.fenceTrackDraftFailTooFew,
          l10n.fenceTrackDraftFailTooFewDesc,
        ),
      TrackDraftFailReason.degenerate => (
          l10n.fenceTrackDraftFailDegenerate,
          l10n.fenceTrackDraftFailDegenerateDesc,
        ),
      TrackDraftFailReason.error => (
          l10n.commonError,
          state.failMessage ?? '',
        ),
    };

    // Cleaning-detail strip only reflects the failing run (diagnostics
    // holder); never a stale success preview.
    final diag = (reason == TrackDraftFailReason.tooFew ||
            reason == TrackDraftFailReason.degenerate)
        ? state.preview?.envelope
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.pets,
                        size: 24, color: AppColors.warning),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  key: const Key('track-draft-fail-title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    desc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.fenceTrackDraftFailSuggests,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                      height: 1.7,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _StatStrip.failure(result: diag),
                const SizedBox(height: AppSpacing.lg),
                // The only way out: back to editing (spec §3.5/§5.4).
                FilledButton(
                  key: const Key('track-draft-fail-back'),
                  onPressed: () => ref
                      .read(trackDraftControllerProvider.notifier)
                      .backToEditing(),
                  child: Text('‹ ${l10n.fenceTrackDraftBackToAdjust}'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Desktop floating button (prototype .web-btn).
class _WebButton extends StatelessWidget {
  const _WebButton._({
    super.key,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  factory _WebButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onTap,
  }) =>
      _WebButton._(key: key, label: label, primary: true, onTap: onTap);

  factory _WebButton.soft({required String label, required VoidCallback onTap}) =>
      _WebButton._(label: label, primary: false, onTap: onTap);

  final String label;
  final bool primary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final bg = primary
        ? (enabled ? AppColors.primary : AppColors.border)
        : AppColors.surfaceAlt;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: primary ? null : Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: primary ? Colors.white : AppColors.primaryDark,
            ),
          ),
        ),
      ),
    );
  }
}
