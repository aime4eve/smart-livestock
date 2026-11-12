import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import 'package:hkt_livestock_agentic/features/fence/data/track_draft_repository.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_draft_area.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_draft_params.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_point.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_to_envelope_converter.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/fence_analytics.dart';

/// Wizard phase state machine (spec §5.4).
enum TrackDraftPhase { editing, loading, previewing, failed }

/// Failure branches of the preview step (spec §3.5 three copy branches +
/// a generic error branch for transport/server failures).
enum TrackDraftFailReason { noData, tooFew, degenerate, error }

/// Wizard output handed to the fence form (Task 5 mounting point):
/// WGS-84 envelope vertices + the generation metadata persisted with the
/// fence (spec §4.3).
typedef TrackDraftCompletion = ({
  List<LatLng> vertices,
  Map<String, Object> metadata,
});

/// Successful preview payload: envelope + everything the map layers, stat
/// strip and source card need.
class TrackDraftPreviewData {
  const TrackDraftPreviewData({
    required this.envelope,
    required this.trackDots,
    required this.deviceNames,
    required this.deviceIds,
    required this.startTime,
    required this.endTime,
    required this.totalRaw,
    required this.areaM2,
  });

  final TrackToEnvelopeResult envelope;

  /// Points drawn as the semi-transparent track-dot layer (fetched points
  /// minus the roaming-trimmed subset, which renders amber on top).
  final List<TrackPoint> trackDots;

  final List<String> deviceNames;
  final List<int> deviceIds;
  final DateTime startTime;
  final DateTime endTime;
  final int totalRaw;

  /// Envelope area in square meters (mu conversion happens in the widget,
  /// spec §5.6).
  final double areaM2;
}

class TrackDraftState {
  const TrackDraftState({
    required this.phase,
    required this.wizardStep,
    required this.candidates,
    required this.candidatesLoading,
    required this.candidatesFailed,
    this.fenceQuota,
    required this.selectedDeviceIds,
    this.quickDays,
    this.startTime,
    this.endTime,
    this.preview,
    required this.previewStale,
    this.hullCandidates = const [],
    this.selectedHullMethod = HullMethod.concaveSimplified,
    this.params = const TrackDraftParams.animalTrack(),
    this.failReason,
    this.failMessage,
  });

  final TrackDraftPhase phase;

  /// Mobile wizard step (0 device / 1 range / 2 preview). The desktop
  /// panel ignores it — both forms share this controller (spec §5.3).
  final int wizardStep;

  final List<TrackDraftDeviceCandidate> candidates;
  final bool candidatesLoading;
  final bool candidatesFailed;
  final FenceQuota? fenceQuota;

  final List<int> selectedDeviceIds;

  /// Active quick chip (7/14/30); null when a custom range was picked.
  final int? quickDays;
  final DateTime? startTime;
  final DateTime? endTime;

  /// Latest successful preview; retained during `loading` (spec §5.4).
  final TrackDraftPreviewData? preview;

  /// Parameter changes after a preview mark it stale (spec §5.4).
  final bool previewStale;

  /// Three hull candidates from the last generate run (spec 修订 v2.1):
  /// fixed order [concaveSimplified, concave, convex]; unavailable ones
  /// render disabled in the preview switcher.
  final List<TrackEnvelopeCandidate> hullCandidates;

  /// Currently previewed hull algorithm; defaults to 凹包·简化.
  final HullMethod selectedHullMethod;

  /// Advanced envelope-calibration bundle (spec §5.7): rancher-tunable via
  /// [TrackDraftController.updateAdvancedParams], recorded with the fence
  /// metadata — never persisted as a farm-level default. Session-scoped:
  /// the provider rebuild resets it to the animalTrack bundle.
  final TrackDraftParams params;

  final TrackDraftFailReason? failReason;

  /// Backend/transport message for [TrackDraftFailReason.error].
  final String? failMessage;

  bool get quotaFull => fenceQuota?.isFull ?? false;

  bool get hasRange => startTime != null && endTime != null;

  /// Hard 30-day cap (frontend hint only; the backend hard-validates).
  bool get rangeTooLong =>
      hasRange &&
      endTime!.difference(startTime!) > const Duration(days: 30);

  bool get rangeInverted => hasRange && !endTime!.isAfter(startTime!);

  bool get canGenerate =>
      selectedDeviceIds.isNotEmpty &&
      hasRange &&
      !rangeTooLong &&
      !rangeInverted &&
      !quotaFull;

  /// Sum of the 30-day point estimates of the selected devices.
  int get estimatedPoints {
    var sum = 0;
    for (final c in candidates) {
      if (selectedDeviceIds.contains(c.deviceId)) sum += c.pointCount;
    }
    return sum;
  }

  TrackDraftState copyWith({
    TrackDraftPhase? phase,
    int? wizardStep,
    List<TrackDraftDeviceCandidate>? candidates,
    bool? candidatesLoading,
    bool? candidatesFailed,
    FenceQuota? fenceQuota,
    List<int>? selectedDeviceIds,
    int? Function()? quickDays,
    DateTime? Function()? startTime,
    DateTime? Function()? endTime,
    TrackDraftPreviewData? Function()? preview,
    bool? previewStale,
    List<TrackEnvelopeCandidate>? hullCandidates,
    HullMethod? selectedHullMethod,
    TrackDraftParams? params,
    TrackDraftFailReason? Function()? failReason,
    String? Function()? failMessage,
  }) {
    return TrackDraftState(
      phase: phase ?? this.phase,
      wizardStep: wizardStep ?? this.wizardStep,
      candidates: candidates ?? this.candidates,
      candidatesLoading: candidatesLoading ?? this.candidatesLoading,
      candidatesFailed: candidatesFailed ?? this.candidatesFailed,
      fenceQuota: fenceQuota ?? this.fenceQuota,
      selectedDeviceIds: selectedDeviceIds ?? this.selectedDeviceIds,
      quickDays: quickDays != null ? quickDays() : this.quickDays,
      startTime: startTime != null ? startTime() : this.startTime,
      endTime: endTime != null ? endTime() : this.endTime,
      preview: preview != null ? preview() : this.preview,
      previewStale: previewStale ?? this.previewStale,
      hullCandidates: hullCandidates ?? this.hullCandidates,
      selectedHullMethod: selectedHullMethod ?? this.selectedHullMethod,
      params: params ?? this.params,
      failReason: failReason != null ? failReason() : this.failReason,
      failMessage: failMessage != null ? failMessage() : this.failMessage,
    );
  }
}

class TrackDraftController extends FarmScopedNotifier<TrackDraftState> {
  @override
  TrackDraftState build() {
    watchActiveFarmId();
    // Default range: last 14 days (prototype screen 3 default chip).
    final now = DateTime.now();
    Future.microtask(loadCandidates);
    return TrackDraftState(
      phase: TrackDraftPhase.editing,
      wizardStep: 0,
      candidates: const [],
      candidatesLoading: true,
      candidatesFailed: false,
      selectedDeviceIds: const [],
      quickDays: 14,
      startTime: now.subtract(const Duration(days: 14)),
      endTime: now,
      previewStale: false,
    );
  }

  Future<void> loadCandidates() async {
    state = state.copyWith(candidatesLoading: true, candidatesFailed: false);
    try {
      final result = await ref.read(trackDraftRepositoryProvider).candidates();
      state = state.copyWith(
        candidates: result.devices,
        fenceQuota: result.fenceQuota,
        candidatesLoading: false,
      );
    } catch (_) {
      state = state.copyWith(candidatesLoading: false, candidatesFailed: true);
    }
  }

  void toggleDevice(int deviceId) {
    final selected = List<int>.from(state.selectedDeviceIds);
    if (selected.contains(deviceId)) {
      selected.remove(deviceId);
    } else {
      selected.add(deviceId);
    }
    _applyParamChange(selectedDeviceIds: selected);
  }

  void setQuickRange(int days) {
    final now = DateTime.now();
    _applyParamChange(
      quickDays: () => days,
      startTime: () => now.subtract(Duration(days: days)),
      endTime: () => now,
    );
  }

  void setCustomRange(DateTime start, DateTime end) {
    _applyParamChange(
      quickDays: () => null,
      startTime: () => start,
      endTime: () => end,
    );
  }

  /// Any parameter change marks an existing preview stale (spec §5.4).
  void _applyParamChange({
    List<int>? selectedDeviceIds,
    int? Function()? quickDays,
    DateTime? Function()? startTime,
    DateTime? Function()? endTime,
    TrackDraftParams? params,
  }) {
    state = state.copyWith(
      selectedDeviceIds: selectedDeviceIds,
      quickDays: quickDays,
      startTime: startTime,
      endTime: endTime,
      params: params,
      previewStale: state.preview != null ? true : state.previewStale,
    );
  }

  /// Advanced-params intent (spec §5.7): maps the three slider display
  /// values to pipeline semantics — trim percent → roaming quantile
  /// (5% → keep 95%), cluster meters and simplification percent pass
  /// through as fractions. A criteria change like any other: rides the
  /// shared [_applyParamChange] path so an existing preview is marked
  /// stale.
  void updateAdvancedParams({
    required double roamingTrimPct,
    required double clusterCellM,
    required double areaTrimPct,
  }) {
    _applyParamChange(
      params: const TrackDraftParams.animalTrack().copyWith(
        roamingQuantile: 1 - roamingTrimPct / 100,
        clusterCellM: clusterCellM,
        areaTrimPct: areaTrimPct / 100,
      ),
    );
  }

  /// Mobile wizard step 1 → 2 (device step guard lives in [canProceedFromDevices]).
  bool get canProceedFromDevices =>
      state.selectedDeviceIds.isNotEmpty && !state.quotaFull;

  void nextToRange() {
    if (!canProceedFromDevices) return;
    state = state.copyWith(wizardStep: 1);
  }

  void backToDevices() {
    state = state.copyWith(wizardStep: 0);
  }

  /// Step 2 → 3 / desktop "生成预览": fetch + run the envelope pipeline.
  Future<void> generate() async {
    if (!state.canGenerate) return;
    // Farm-switch race guard (review 低1): snapshot at entry and compare
    // before every post-await write — a switch mid-flight rebuilds this
    // farm-scoped provider and the stale continuation must be dropped
    // instead of polluting the fresh state.
    final farmIdAtStart =
        ref.read(sessionControllerProvider.select((s) => s.activeFarmId));
    final deviceIds = List<int>.from(state.selectedDeviceIds);
    final start = state.startTime!;
    final end = state.endTime!;
    // Snapshot like the other inputs: a slider change mid-flight must not
    // bleed into the in-flight pipeline run.
    final params = state.params;
    // Loading keeps the previous preview under the overlay (spec §5.4).
    state = state.copyWith(
      phase: TrackDraftPhase.loading,
      wizardStep: 2,
      failReason: () => null,
      failMessage: () => null,
    );
    try {
      final source = await ref.read(trackDraftRepositoryProvider).source(
            deviceIds: deviceIds,
            startTime: start,
            endTime: end,
          );
      if (_farmSwitched(farmIdAtStart)) return;
      if (source.points.isEmpty) {
        state = state.copyWith(
          phase: TrackDraftPhase.failed,
          failReason: () => TrackDraftFailReason.noData,
        );
        return;
      }
      final hullCandidates = TrackToEnvelopeConverter.buildTrackDraftCandidates(
        source.points,
        params: params,
      );
      // Default selection: first available candidate in the fixed priority
      // order concaveSimplified → concave → convex (spec 修订 v2.1).
      TrackEnvelopeCandidate? selected;
      for (final c in hullCandidates) {
        if (c.isAvailable) {
          selected = c;
          break;
        }
      }
      if (selected == null) {
        // All three candidates failed: reuse the existing failure copy
        // branches, with the shared cleaning stats as strip diagnostics.
        final envelope = hullCandidates.first.result;
        state = state.copyWith(
          phase: TrackDraftPhase.failed,
          hullCandidates: hullCandidates,
          failReason: () => envelope.failure == EnvelopeFailure.degenerate
              ? TrackDraftFailReason.degenerate
              : TrackDraftFailReason.tooFew,
          // Failure diagnostics ride on the envelope result; keep a
          // minimal preview holder so the failure strip can render.
          preview: () => TrackDraftPreviewData(
            envelope: envelope,
            trackDots: const [],
            deviceNames: _deviceNames(deviceIds),
            deviceIds: deviceIds,
            startTime: start,
            endTime: end,
            totalRaw: source.totalRaw,
            areaM2: 0,
          ),
        );
        return;
      }
      state = state.copyWith(
        phase: TrackDraftPhase.previewing,
        previewStale: false,
        hullCandidates: hullCandidates,
        selectedHullMethod: selected.method,
        preview: () => _previewData(
          candidate: selected!,
          points: source.points,
          totalRaw: source.totalRaw,
          deviceIds: deviceIds,
          deviceNames: _deviceNames(deviceIds),
          start: start,
          end: end,
        ),
      );
      // Generate-success fires where it happens — when the preview lands
      // (review 低2), not at wizard confirmation; counts mirror the
      // provenance metadata (deviceIds / usedPoints). Cleaning stats are
      // shared across candidates, so the count is selection-independent.
      ref.read(fenceAnalyticsSinkProvider).emitEvent(
            FenceAnalyticsEvent.trackDraftGenerateSuccess(
              deviceCount: deviceIds.length,
              pointCount: selected.result.remainingValid,
            ),
          );
    } on ApiException catch (e) {
      if (_farmSwitched(farmIdAtStart)) return;
      state = state.copyWith(
        phase: TrackDraftPhase.failed,
        failReason: () => TrackDraftFailReason.error,
        failMessage: () => e.message,
      );
    } catch (_) {
      if (_farmSwitched(farmIdAtStart)) return;
      state = state.copyWith(
        phase: TrackDraftPhase.failed,
        failReason: () => TrackDraftFailReason.error,
      );
    }
  }

  /// Preview switcher intent (spec 修订 v2.1): pure state swap — no network,
  /// no recompute (candidates were built once in [generate]); unavailable
  /// candidates are rejected; the stale flag is untouched.
  void selectHullMethod(HullMethod method) {
    if (state.selectedHullMethod == method) return;
    final preview = state.preview;
    if (preview == null) return;
    TrackEnvelopeCandidate? match;
    for (final c in state.hullCandidates) {
      if (c.method == method && c.isAvailable) {
        match = c;
        break;
      }
    }
    if (match == null) return;
    // The roaming-trimmed subset is shared across candidates (same cleaning
    // run), so the track-dot layer is identical — only the envelope swaps.
    state = state.copyWith(
      selectedHullMethod: method,
      preview: () => _previewData(
        candidate: match!,
        points: preview.trackDots,
        totalRaw: preview.totalRaw,
        deviceIds: preview.deviceIds,
        deviceNames: preview.deviceNames,
        start: preview.startTime,
        end: preview.endTime,
      ),
    );
  }

  /// Assembles the preview payload for a hull candidate.
  static TrackDraftPreviewData _previewData({
    required TrackEnvelopeCandidate candidate,
    required List<TrackPoint> points,
    required int totalRaw,
    required List<int> deviceIds,
    required List<String> deviceNames,
    required DateTime start,
    required DateTime end,
  }) {
    final envelope = candidate.result;
    final trimmedSet = envelope.trimmedPoints.toSet();
    return TrackDraftPreviewData(
      envelope: envelope,
      trackDots: [
        for (final p in points)
          if (!trimmedSet.contains(p)) p,
      ],
      deviceNames: deviceNames,
      deviceIds: deviceIds,
      startTime: start,
      endTime: end,
      totalRaw: totalRaw,
      areaM2: polygonAreaM2(envelope.vertices),
    );
  }

  /// True when [farmIdAtStart] no longer matches the active farm, or the
  /// controller was rebuilt/disposed by the switch (ref read fails).
  bool _farmSwitched(String? farmIdAtStart) {
    try {
      return ref.read(
            sessionControllerProvider.select((s) => s.activeFarmId),
          ) !=
          farmIdAtStart;
    } catch (_) {
      return true;
    }
  }

  /// 「调整条件」/「返回调整条件」: the only inbound edge of `editing`
  /// (spec §5.4) — keeps the selected devices and time range.
  void backToEditing() {
    if (state.phase != TrackDraftPhase.previewing &&
        state.phase != TrackDraftPhase.failed) {
      return;
    }
    state = state.copyWith(
      phase: TrackDraftPhase.editing,
      wizardStep: 1,
      failReason: () => null,
      failMessage: () => null,
    );
  }

  List<String> _deviceNames(List<int> ids) => [
        for (final c in state.candidates)
          if (ids.contains(c.deviceId)) c.name,
      ];

  /// Builds the wizard output for the fence form (Task 5 calls this after
  /// the user confirms); returns null when no successful preview exists.
  /// The three advanced params are always appended in slider-display form
  /// (human-readable, full traceability even at defaults).
  TrackDraftCompletion? buildCompletion() {
    final preview = state.preview;
    if (state.phase != TrackDraftPhase.previewing ||
        preview == null ||
        !preview.envelope.isSuccess) {
      return null;
    }
    final p = state.params;
    return (
      vertices: preview.envelope.vertices,
      metadata: <String, Object>{
        'method': 'DEVICE_TRACK',
        'deviceIds': preview.deviceIds,
        'startTime': preview.startTime.toIso8601String(),
        'endTime': preview.endTime.toIso8601String(),
        'rawPointCount': preview.totalRaw,
        'usedPoints': preview.envelope.remainingValid,
        'outlierTrimmed': preview.envelope.roamingTrimmed,
        'hullMethod': preview.envelope.method.metadataKey,
        'roamingTrimPct': p.roamingTrimPctDisplay,
        'clusterCellM': p.clusterCellMDisplay,
        'areaTrimPct': p.areaTrimPctDisplay,
      },
    );
  }
}

final trackDraftControllerProvider =
    NotifierProvider<TrackDraftController, TrackDraftState>(
  TrackDraftController.new,
);
