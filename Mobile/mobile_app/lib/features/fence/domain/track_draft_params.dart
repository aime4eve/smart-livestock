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
        clusterCellM = null;

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
        clusterCellM = 30;
}
