import 'track_to_envelope_converter.dart';

/// Immutable parameter bundle for the track → envelope pipeline
/// (fence-from-device-track, spec §5.2).
///
/// The converter's `static const` defaults remain the single source of truth
/// for the GPX/RTK baseline: [TrackDraftParams.gpxDefault] references them
/// verbatim, so running the pipeline with the default bundle is bit-identical
/// to running it without parameters. [TrackDraftParams.animalTrack] carries
/// the animal-track initial values; real-device calibration may only tune
/// these values, never the pipeline structure.
class TrackDraftParams {
  /// Accuracy filter threshold (meters).
  final double accuracyThresholdM;

  /// Base boundary-cell edge length for hull tightening (meters).
  final double lMaxBaseM;

  /// Implied-speed outlier threshold (m/s).
  final double speedOutlierMps;

  /// MAD scrub multiplier.
  final double madMultiplier;

  /// MAD scrub floor, prevents over-scrubbing (meters).
  final double madFloorM;

  /// Degenerate-rejection area floor (square meters).
  final double minAreaM2;

  /// Douglas-Peucker simplification tolerance (meters).
  final double simplifyEpsilonM;

  /// Vertex cap of the emitted ring.
  final int maxVertices;

  /// Hard cap on hull-tightening insertions.
  final int maxInsertions;

  /// Roaming-trim distance quantile; null disables the trim step entirely.
  final double? roamingQuantile;

  /// Grid-thinning cell size (meters) applied to the input of the
  /// concaveSimplified candidate only; null disables it. Dense GPS clusters
  /// make the hull boundary weave in and out of the cluster (deep detours
  /// that per-vertex area trimming cannot undo) — thinning the cluster to
  /// one point per cell removes the detour at its source. Each cell keeps
  /// the point farthest from the sample centroid, so the outer outline
  /// survives.
  final double? clusterCellM;

  /// Area-contribution simplification tolerance (fraction of the initial
  /// ring area) consumed by the concaveSimplified candidate only — the
  /// concave and convex branches never read it. Defaults to the converter's
  /// static const in both bundles, so the pre-parameterized pipeline output
  /// stays bit-identical (regression isolation gate).
  final double areaTrimPct;

  /// GPX/RTK default bundle: the current pipeline values with no roaming
  /// trim. Output with this bundle is bit-identical to the pre-parameterized
  /// pipeline (regression isolation gate).
  const TrackDraftParams.gpxDefault()
      : accuracyThresholdM = TrackToEnvelopeConverter.accuracyThresholdM,
        lMaxBaseM = TrackToEnvelopeConverter.lMaxBaseM,
        speedOutlierMps = TrackToEnvelopeConverter.speedOutlierMps,
        madMultiplier = TrackToEnvelopeConverter.madMultiplier,
        madFloorM = TrackToEnvelopeConverter.madFloorM,
        minAreaM2 = TrackToEnvelopeConverter.minAreaM2,
        simplifyEpsilonM = TrackToEnvelopeConverter.simplifyEpsilonM,
        maxVertices = TrackToEnvelopeConverter.maxVertices,
        maxInsertions = TrackToEnvelopeConverter.maxInsertions,
        roamingQuantile = null,
        clusterCellM = null,
        areaTrimPct = TrackToEnvelopeConverter.areaContributionTolPct;

  /// Animal-track bundle (initial values, pending real-device calibration):
  /// 40m accuracy threshold, 40m L_max base, 95% roaming trim; every other
  /// parameter inherits the GPX default.
  const TrackDraftParams.animalTrack()
      : accuracyThresholdM = 40,
        lMaxBaseM = 40,
        speedOutlierMps = TrackToEnvelopeConverter.speedOutlierMps,
        madMultiplier = TrackToEnvelopeConverter.madMultiplier,
        madFloorM = TrackToEnvelopeConverter.madFloorM,
        minAreaM2 = TrackToEnvelopeConverter.minAreaM2,
        simplifyEpsilonM = TrackToEnvelopeConverter.simplifyEpsilonM,
        maxVertices = TrackToEnvelopeConverter.maxVertices,
        maxInsertions = TrackToEnvelopeConverter.maxInsertions,
        roamingQuantile = 0.95,
        clusterCellM = 30,
        areaTrimPct = TrackToEnvelopeConverter.areaContributionTolPct;

  const TrackDraftParams._({
    required this.accuracyThresholdM,
    required this.lMaxBaseM,
    required this.speedOutlierMps,
    required this.madMultiplier,
    required this.madFloorM,
    required this.minAreaM2,
    required this.simplifyEpsilonM,
    required this.maxVertices,
    required this.maxInsertions,
    required this.roamingQuantile,
    required this.clusterCellM,
    required this.areaTrimPct,
  });

  /// Rancher-tunable overrides for the wizard's advanced-params sliders:
  /// only the three slider-driven values change; every other parameter
  /// inherits [this]. Always derived from [TrackDraftParams.animalTrack] —
  /// the wizard never exposes the other calibration knobs.
  TrackDraftParams copyWith({
    double? roamingQuantile,
    double? clusterCellM,
    double? areaTrimPct,
  }) =>
      TrackDraftParams._(
        accuracyThresholdM: accuracyThresholdM,
        lMaxBaseM: lMaxBaseM,
        speedOutlierMps: speedOutlierMps,
        madMultiplier: madMultiplier,
        madFloorM: madFloorM,
        minAreaM2: minAreaM2,
        simplifyEpsilonM: simplifyEpsilonM,
        maxVertices: maxVertices,
        maxInsertions: maxInsertions,
        roamingQuantile: roamingQuantile ?? this.roamingQuantile,
        clusterCellM: clusterCellM ?? this.clusterCellM,
        areaTrimPct: areaTrimPct ?? this.areaTrimPct,
      );

  // ── Slider-display inverses (single source of truth for the wizard UI
  //    and the generation metadata; the metadata persists these human-
  //    readable values, never the internal conversions). The ×4 round trip
  //    absorbs the binary error of the /100 and ×100 conversions against
  //    the 0.25%-step slider grid. ─────────────────────────────────────

  /// Trim-farthest slider value in percent (5 = 5%).
  int get roamingTrimPctDisplay =>
      ((1 - (roamingQuantile ?? 0.95)) * 100).round();

  /// Cluster-merge slider value in meters (30).
  int get clusterCellMDisplay => clusterCellM?.round() ?? 30;

  /// Outline-simplification slider value in percent (0.5 = 0.5%).
  double get areaTrimPctDisplay => (areaTrimPct * 100 * 4).round() / 4;
}
