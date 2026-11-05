package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.TemperatureLog;
import com.smartlivestock.health.domain.service.EstrusAnalysisService;
import com.smartlivestock.health.infrastructure.config.EstrusScoringProperties;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.function.Function;

/**
 * Reusable same-input estrus-scoring replayer. ONE identical event sequence
 * (the same temperature/activity rows) is pushed through the production
 * estrus-scoring semantics once per baseline candidate: for every temperature
 * arrival (event-time position i) the production features feed the scoring
 * kernel, and ≥70 positions merge into alert episodes exactly like the
 * production hasActiveAlert dedup approximation.
 *
 * <p><b>Dual path (NIX-380 Task 3):</b> the scoring semantics are selected by
 * {@code EstrusScoringProperties.getMode()}, the very same switch the
 * production {@code HealthApplicationService.triggerEstrusScoring} uses:</p>
 * <ul>
 *   <li>{@code LEGACY} — the pre-NIX-380 short-window formula, kept
 *       byte-for-byte: the newest 7 activities/temperatures as of the arrival
 *       feed {@code calculateStepIncreasePercent} (newest 3 vs the rest),
 *       {@code calculateDistanceDelta}, latest temp minus the side's baseline,
 *       scored via {@link EstrusAnalysisService#calculateScore}.</li>
 *   <li>{@code NORMALIZED} (everything else — the properties bean validates
 *       the mode to these two values) — the cross-event-window kernel of
 *       {@code HealthApplicationService.triggerEstrusScoringNormalized}:
 *       current-window mean ÷ pooled mean of same-phase baseline windows
 *       24h apart (mean/mean — see ChannelLevel), per-channel availability
 *       guards, scored via
 *       {@link EstrusAnalysisService#calculateScoreNormalized}. Windows are
 *       half-open {@code [start, end)}; anchor-timestamped activity frames are
 *       excluded (deterministic tie handling, same as the production window
 *       read {@code [anchor − span, anchor)}).</li>
 * </ul>
 * Consumers call {@link #replay} and get whichever semantics production is
 * configured for — replaying a historical configuration only means setting
 * the mode accordingly (e.g. LEGACY to reproduce pre-NIX-380 report numbers).
 *
 * <p>Two sides in one pass: both overloads always replay the DEFAULT
 * candidate and — when a learned candidate is given — the LEARNED candidate
 * over the very same normalized sequence. The two sides are independent per
 * position (only {@code tempDelta} depends on the baseline; the activity and
 * distance factors are baseline-independent and shared), so the result is
 * bit-identical to replaying the sequence once per baseline. The learned side
 * is {@code null} when no learned candidate is supplied.</p>
 *
 * <p>Deliberate I/O deviations from production (both paths): the replay runs
 * over the caller-supplied in-memory sequence without the production read
 * clamps (LEGACY's 7-row top-read is re-derived in memory; NORMALIZED's
 * {@code maxWindowRows} SQL clamp against pathological cadences is not
 * replicated — it is a read-size guard, not scoring semantics).</p>
 *
 * <p>Consumers: the admin baseline A/B evaluation (mechanism comparison) and
 * the datagen simulation evaluation (label-window alignment of ≥70 alert
 * episodes).</p>
 */
@Service
public class EstrusSeriesReplayer {

    /** Consecutive ≥70 scoring positions within this gap merge into one episode. */
    private static final Duration EPISODE_MERGE_GAP = Duration.ofHours(24);

    /** Legacy production guard: the newest 7 rows feed each scoring position. */
    private static final int RECENT_WINDOW = 7;
    private static final int HIGH_SCORE_THRESHOLD = 70;

    /** Scale of level ratios / means — verbatim from the production normalized path. */
    private static final int RATIO_SCALE = 6;

    private final EstrusAnalysisService estrusAnalysisService;
    private final EstrusScoringProperties estrusScoringProperties;

    public EstrusSeriesReplayer(EstrusAnalysisService estrusAnalysisService,
                                EstrusScoringProperties estrusScoringProperties) {
        this.estrusAnalysisService = estrusAnalysisService;
        this.estrusScoringProperties = estrusScoringProperties;
    }

    // ------------------------------------------------------------------
    // Result contracts
    // ------------------------------------------------------------------

    /** Outcome of one replay pass: the DEFAULT side and the optional LEARNED side. */
    public record ReplayResult(SideResult defaultSide, SideResult learnedSide) {
    }

    /** Aggregated replay statistics of one baseline side. */
    public record SideResult(int scoringPoints, int highScorePoints,
                             List<EpisodeRecord> episodes,
                             BigDecimal lastTempDelta, Integer lastScore) {
    }

    /**
     * One merged ≥70 alert episode. {@code start}/{@code end} are the first
     * and last high-score instants of the episode; {@code highTimes} keeps
     * the individual scoring positions inside it. {@code livestockId} is
     * stamped by the livestock-aware overload so callers can align episodes
     * against per-animal ground-truth label windows.
     */
    public record EpisodeRecord(Long livestockId, List<Instant> highTimes,
                                Instant start, Instant end) {
    }

    // ------------------------------------------------------------------
    // Replay entry points
    // ------------------------------------------------------------------

    /**
     * Replays the sequence with the fixed DEFAULT baseline plus the optional
     * learned candidate. Inputs may arrive in any order: they are filtered
     * (null timestamps/values dropped) and sorted ascending first, which
     * makes the {@code Asc} contract self-enforcing and idempotent for
     * already-sorted input. The scoring semantics follow the configured
     * {@code EstrusScoringProperties} mode.
     */
    public ReplayResult replay(List<TemperatureLog> tempsAsc, List<ActivityLog> actsAsc,
                               BigDecimal defaultBaseline, BigDecimal learnedBaselineOrNull) {
        return replay(null, tempsAsc, actsAsc, defaultBaseline, learnedBaselineOrNull);
    }

    /**
     * Same computation with the livestock id stamped onto every episode —
     * the shape label-window alignment needs. {@code livestockId} may be
     * {@code null} (the anonymous variant above delegates here).
     */
    public ReplayResult replay(Long livestockId, List<TemperatureLog> temperatures,
                               List<ActivityLog> activities,
                               BigDecimal defaultBaseline, BigDecimal learnedBaselineOrNull) {
        List<TemperatureLog> tempsAsc = temperatures.stream()
                .filter(t -> t.getRecordedAt() != null && t.getTemperature() != null)
                .sorted(Comparator.comparing(TemperatureLog::getRecordedAt))
                .toList();
        List<ActivityLog> actsAsc = activities.stream()
                .filter(a -> a.getRecordedAt() != null)
                .sorted(Comparator.comparing(ActivityLog::getRecordedAt))
                .toList();

        // Mode dispatch mirrors HealthApplicationService.triggerEstrusScoring;
        // the properties bean validates the mode to LEGACY/NORMALIZED only.
        if ("LEGACY".equals(estrusScoringProperties.getMode())) {
            return replayLegacy(livestockId, tempsAsc, actsAsc,
                    defaultBaseline, learnedBaselineOrNull);
        }
        return replayNormalized(livestockId, tempsAsc, actsAsc,
                defaultBaseline, learnedBaselineOrNull);
    }

    // ------------------------------------------------------------------
    // LEGACY path — the pre-NIX-380 short-window formula, byte-for-byte
    // ------------------------------------------------------------------

    private ReplayResult replayLegacy(Long livestockId, List<TemperatureLog> tempsAsc,
                                      List<ActivityLog> actsAsc,
                                      BigDecimal defaultBaseline, BigDecimal learnedBaselineOrNull) {
        boolean learnedActive = learnedBaselineOrNull != null;
        SideAccumulator defaultSide = new SideAccumulator();
        SideAccumulator learnedSide = learnedActive ? new SideAccumulator() : null;

        int actCursor = 0; // activities with recordedAt <= the current arrival
        for (int i = 0; i < tempsAsc.size(); i++) {
            Instant at = tempsAsc.get(i).getRecordedAt();
            while (actCursor < actsAsc.size() && !actsAsc.get(actCursor).getRecordedAt().isAfter(at)) {
                actCursor++;
            }
            // Production guard: recentActivities.size() < 3 || recentTemps.size() < 2 → skip.
            if (actCursor < 3 || i < 1) {
                continue;
            }
            // Production reads findByLivestockIdOrderByRecordedAtDesc(id, 7):
            // the newest rows as of this arrival, newest first.
            List<ActivityLog> recentActivities = newestFirst(actsAsc, actCursor);
            List<TemperatureLog> recentTemps = newestFirst(tempsAsc, i + 1);

            // Baseline-independent factors, computed once per position.
            int stepIncreasePercent = stepIncreasePercent(recentActivities);
            BigDecimal distanceDelta = distanceDelta(recentActivities);
            BigDecimal latestTemp = recentTemps.get(0).getTemperature();

            defaultSide.accept(estrusAnalysisService, at, latestTemp.subtract(defaultBaseline),
                    stepIncreasePercent, distanceDelta);
            if (learnedActive) {
                learnedSide.accept(estrusAnalysisService, at,
                        latestTemp.subtract(learnedBaselineOrNull), stepIncreasePercent, distanceDelta);
            }
        }

        return new ReplayResult(defaultSide.build(livestockId),
                learnedActive ? learnedSide.build(livestockId) : null);
    }

    // ------------------------------------------------------------------
    // NORMALIZED path — bit-for-bit replica of
    // HealthApplicationService.triggerEstrusScoringNormalized, read-only
    // and evaluated at EVERY temperature arrival (production scores only
    // the newest; the replay rolls the same semantics over history)
    // ------------------------------------------------------------------

    private ReplayResult replayNormalized(Long livestockId, List<TemperatureLog> tempsAsc,
                                          List<ActivityLog> actsAsc,
                                          BigDecimal defaultBaseline, BigDecimal learnedBaselineOrNull) {
        EstrusScoringProperties props = estrusScoringProperties;
        EstrusAnalysisService.EstrusFeatureLadder activityLadder = props.toActivityLadder();
        EstrusAnalysisService.EstrusFeatureLadder distanceLadder = props.toDistanceLadder();

        boolean learnedActive = learnedBaselineOrNull != null;
        SideAccumulator defaultSide = new SideAccumulator();
        SideAccumulator learnedSide = learnedActive ? new SideAccumulator() : null;

        // Activities strictly before the current arrival feed the windows: the
        // production read is the half-open [anchor − span, anchor), so an
        // activity frame stamped exactly at the anchor is excluded (deterministic
        // tie handling). The LEGACY path keeps its <= cursor; only this path
        // uses the strict <.
        int actCursor = 0; // activities with recordedAt < the current arrival (strict)
        for (int i = 0; i < tempsAsc.size(); i++) {
            Instant at = tempsAsc.get(i).getRecordedAt();
            while (actCursor < actsAsc.size() && actsAsc.get(actCursor).getRecordedAt().isBefore(at)) {
                actCursor++;
            }
            // The anchor-timestamped frame can never be in the eligible prefix.
            List<ActivityLog> eligibleActs = actsAsc.subList(0, actCursor);

            // Guard: temperature component needs a minimum sample count. The
            // production guard counts the newest-7 read; positions in the replay
            // see i + 1 samples (assumes minTemperatureSamples within the read
            // clamp, true for the validated configuration space).
            if (i + 1 < props.getMinTemperatureSamples()) {
                continue;
            }
            // The anchor row is the newest temperature as of this arrival —
            // the same row production takes recentTemps.get(0) from.
            BigDecimal latestTemp = tempsAsc.get(i).getTemperature();

            // Channel selection: activityIndex preferred, stepCount as the
            // ear-tag fallback; never mixed within one channel decision.
            // Distance is judged independently and may be unavailable (the
            // kernel drops its weight). Baseline-independent: computed once
            // per position and shared by both sides.
            ChannelLevel activityLevel = channelLevel(eligibleActs, at,
                    ActivityLog::getActivityIndex, props);
            if (activityLevel == null) {
                activityLevel = channelLevel(eligibleActs, at,
                        log -> log.getStepCount() == null ? null : BigDecimal.valueOf(log.getStepCount()),
                        props);
            }
            // Guard: without an activity component there is nothing to normalize.
            if (activityLevel == null) {
                continue;
            }
            ChannelLevel distanceLevel = channelLevel(eligibleActs, at,
                    ActivityLog::getDistanceMeters, props);

            defaultSide.acceptNormalized(estrusAnalysisService, at,
                    latestTemp.subtract(defaultBaseline),
                    activityLevel.ratio(),
                    distanceLevel == null ? null : distanceLevel.ratio(),
                    activityLadder, distanceLadder);
            if (learnedActive) {
                learnedSide.acceptNormalized(estrusAnalysisService, at,
                        latestTemp.subtract(learnedBaselineOrNull),
                        activityLevel.ratio(),
                        distanceLevel == null ? null : distanceLevel.ratio(),
                        activityLadder, distanceLadder);
            }
        }

        return new ReplayResult(defaultSide.build(livestockId),
                learnedActive ? learnedSide.build(livestockId) : null);
    }

    // ------------------------------------------------------------------
    // Episode merge (public: BaselineEvaluationService keeps its static
    // episodeCount contract by delegating here)
    // ------------------------------------------------------------------

    /**
     * Merges ≥70 scoring positions into alert episodes (production
     * hasActiveAlert dedup approximation): times sorted ascending,
     * consecutive gaps ≤ 24h belong to the same episode, a larger gap starts
     * a new one. {@code highScoreTimes} may be null/empty (→ no episodes)
     * and is normalized here, so the result never depends on input order.
     */
    public static List<EpisodeRecord> mergeEpisodes(Long livestockId, List<Instant> highScoreTimes) {
        if (highScoreTimes == null || highScoreTimes.isEmpty()) {
            return List.of();
        }
        List<Instant> sorted = highScoreTimes.stream().sorted().toList();
        List<EpisodeRecord> episodes = new ArrayList<>();
        List<Instant> current = new ArrayList<>();
        current.add(sorted.get(0));
        for (int i = 1; i < sorted.size(); i++) {
            Instant previous = sorted.get(i - 1);
            Instant time = sorted.get(i);
            if (Duration.between(previous, time).compareTo(EPISODE_MERGE_GAP) > 0) {
                episodes.add(new EpisodeRecord(livestockId, List.copyOf(current),
                        current.get(0), current.get(current.size() - 1)));
                current = new ArrayList<>();
            }
            current.add(time);
        }
        episodes.add(new EpisodeRecord(livestockId, List.copyOf(current),
                current.get(0), current.get(current.size() - 1)));
        return episodes;
    }

    /**
     * Episode count of a high-score instant list — the numeric contract the
     * admin evaluation carried before the refactor (null/empty → 0).
     */
    public static int episodeCount(List<Instant> highScoreTimes) {
        return mergeEpisodes(null, highScoreTimes).size();
    }

    // ------------------------------------------------------------------
    // Per-side accumulation (one pass, two baselines)
    // ------------------------------------------------------------------

    /** Mutable side builder collapsed into a {@link SideResult} at the end. */
    private static final class SideAccumulator {
        private int scoringPoints;
        private int highScorePoints;
        private final List<Instant> highScoreTimes = new ArrayList<>();
        private BigDecimal lastTempDelta;
        private Integer lastScore;

        /** Legacy short-window scoring position. */
        void accept(EstrusAnalysisService scoring, Instant at, BigDecimal tempDelta,
                    int stepIncreasePercent, BigDecimal distanceDelta) {
            record(scoring.calculateScore(stepIncreasePercent, tempDelta, distanceDelta),
                    at, tempDelta);
        }

        /** Normalized cross-event-window scoring position. */
        void acceptNormalized(EstrusAnalysisService scoring, Instant at, BigDecimal tempDelta,
                              BigDecimal activityRatio, BigDecimal distanceRatio,
                              EstrusAnalysisService.EstrusFeatureLadder activityLadder,
                              EstrusAnalysisService.EstrusFeatureLadder distanceLadder) {
            record(scoring.calculateScoreNormalized(activityRatio, tempDelta, distanceRatio,
                            activityLadder, distanceLadder),
                    at, tempDelta);
        }

        private void record(int score, Instant at, BigDecimal tempDelta) {
            scoringPoints++;
            if (score >= HIGH_SCORE_THRESHOLD) {
                highScorePoints++;
                highScoreTimes.add(at);
            }
            lastTempDelta = tempDelta;
            lastScore = score;
        }

        SideResult build(Long livestockId) {
            return new SideResult(scoringPoints, highScorePoints,
                    mergeEpisodes(livestockId, highScoreTimes), lastTempDelta, lastScore);
        }
    }

    /**
     * The last {@code count} rows (at most {@code RECENT_WINDOW}), newest
     * first — the in-memory equivalent of the LEGACY production
     * {@code ...OrderByRecordedAtDesc(id, 7)} read at one arrival instant.
     */
    private static <T> List<T> newestFirst(List<T> ascending, int count) {
        int from = Math.max(0, count - RECENT_WINDOW);
        List<T> result = new ArrayList<>(count - from);
        for (int k = count - 1; k >= from; k--) {
            result.add(ascending.get(k));
        }
        return result;
    }

    // ------------------------------------------------------------------
    // Normalized channel machinery — copied verbatim from
    // HealthApplicationService (channelLevel / window filter / mean);
    // the private production helpers are not widened for reuse
    // (the replay must stay a read-only replica, and small duplication is
    // the accepted price — same as the LEGACY feature copies below)
    // ------------------------------------------------------------------

    /**
     * Channel levels of one activity channel: the current-window arithmetic
     * mean, the pooled arithmetic mean of its qualified baseline-window
     * samples, and their ratio (mean ÷ pooled mean). The ratio feeds the
     * scoring ladder. Windows are half-open {@code [start, end)} — the same
     * convention as the production window read feeding them.
     *
     * <p>Mean/mean, not mean/median — simulation forensics (NIX-380) showed
     * mean vs pooled median on the bimodal day/night activity envelope
     * systematically diverges at day-boundary windows (minority day frames
     * lift the mean while the median stays in the night cluster), inflating
     * clean-cow ratios to ~2×. Same-phase windows carry the same frame mix,
     * so mean ÷ pooled mean is coherent. Verbatim mirror of the production
     * {@code HealthApplicationService.channelLevel}.</p>
     *
     * <p>Availability rules (NIX-380 §2, judged per channel on sample counts):
     * the channel is usable only when the current window holds at least
     * {@code minCurrentActivitySamples} non-null samples AND at least half of
     * the baseline windows qualify (each holding at least
     * {@code minBaselineActivitySamples} non-null samples) — half, not all, so
     * one polluted or cold-start window cannot disable the baseline. Returns
     * null when unavailable or when the pooled baseline level is not positive
     * (level ≤ 0 makes the ratio undefined).</p>
     */
    private record ChannelLevel(BigDecimal currentMean, BigDecimal baselineLevel, BigDecimal ratio) {
    }

    private static ChannelLevel channelLevel(List<ActivityLog> logs, Instant anchor,
                                             Function<ActivityLog, BigDecimal> channel,
                                             EstrusScoringProperties props) {
        long currentWindowHours = props.getCurrentWindowHours();
        int baselineWindowCount = props.getBaselineWindowCount();
        long offsetHours = props.getBaselineWindowOffsetHours();

        List<BigDecimal> current = channelSamplesInWindow(
                logs, anchor.minus(Duration.ofHours(currentWindowHours)), anchor, channel);
        if (current.size() < props.getMinCurrentActivitySamples()) return null;

        List<BigDecimal> pooled = new ArrayList<>();
        int qualifiedWindows = 0;
        for (int k = 1; k <= baselineWindowCount; k++) {
            // Same wall-clock phase as the current window: each baseline window
            // sits an exact 24h multiple before it (the offset is validated as
            // a positive multiple of 24), so the daily activity envelope
            // cancels out and the ratio reflects the true level change.
            Instant windowEnd = anchor.minus(Duration.ofHours(offsetHours * k));
            Instant windowStart = windowEnd.minus(Duration.ofHours(currentWindowHours));
            List<BigDecimal> samples = channelSamplesInWindow(logs, windowStart, windowEnd, channel);
            if (samples.size() >= props.getMinBaselineActivitySamples()) {
                qualifiedWindows++;
                pooled.addAll(samples);
            }
        }
        // ceil(baselineWindowCount / 2) qualified windows required.
        if (qualifiedWindows * 2 < baselineWindowCount) return null;

        // Pooled arithmetic mean, not median — see the ChannelLevel javadoc
        // (mean/mean coherence on the bimodal day/night envelope). The pool is
        // non-empty here: qualifiedWindows >= 1 by the ceil guard above.
        BigDecimal baselineLevel = arithmeticMean(pooled);
        if (baselineLevel == null || baselineLevel.signum() <= 0) return null;

        BigDecimal mean = arithmeticMean(current);
        if (mean == null) return null;
        return new ChannelLevel(mean, baselineLevel,
                mean.divide(baselineLevel, RATIO_SCALE, RoundingMode.HALF_UP));
    }

    /** Non-null channel samples whose recordedAt falls in the half-open window {@code [start, end)}. */
    private static List<BigDecimal> channelSamplesInWindow(List<ActivityLog> logs, Instant start, Instant end,
                                                           Function<ActivityLog, BigDecimal> channel) {
        return logs.stream()
                .filter(l -> l.getRecordedAt() != null
                        && !l.getRecordedAt().isBefore(start)
                        && l.getRecordedAt().isBefore(end))
                .map(channel)
                .filter(Objects::nonNull)
                .toList();
    }

    /** Arithmetic mean over a non-empty list; null only when the list is empty. */
    private static BigDecimal arithmeticMean(List<BigDecimal> samples) {
        if (samples.isEmpty()) return null;
        BigDecimal sum = samples.stream().reduce(BigDecimal.ZERO, BigDecimal::add);
        return sum.divide(BigDecimal.valueOf(samples.size()), RATIO_SCALE, RoundingMode.HALF_UP);
    }

    // ------------------------------------------------------------------
    // LEGACY feature copies — production semantics copied verbatim from
    // HealthApplicationService
    // ------------------------------------------------------------------

    /**
     * Production semantics copied verbatim from
     * {@code HealthApplicationService.calculateStepIncreasePercent}: the
     * newest 3 rows vs the rest of the latest-7 read. {@code logs} is
     * newest-first.
     */
    private static int stepIncreasePercent(List<ActivityLog> logs) {
        if (logs.size() < 2) {
            return 0;
        }
        int recentSteps = logs.stream()
                .limit(3)
                .mapToInt(l -> l.getStepCount() != null ? l.getStepCount() : 0)
                .sum();
        int olderSteps = logs.stream()
                .skip(3)
                .mapToInt(l -> l.getStepCount() != null ? l.getStepCount() : 0)
                .sum();
        if (olderSteps == 0) {
            return recentSteps > 0 ? 100 : 0;
        }
        return Math.round((float) (recentSteps - olderSteps) / olderSteps * 100);
    }

    /**
     * Production semantics copied verbatim from
     * {@code HealthApplicationService.calculateDistanceDelta}: newest-3
     * distance sum minus the rest. {@code logs} is newest-first.
     */
    private static BigDecimal distanceDelta(List<ActivityLog> logs) {
        if (logs.size() < 2) {
            return BigDecimal.ZERO;
        }
        BigDecimal recentDist = logs.stream()
                .limit(3)
                .map(l -> l.getDistanceMeters() != null ? l.getDistanceMeters() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal olderDist = logs.stream()
                .skip(3)
                .map(l -> l.getDistanceMeters() != null ? l.getDistanceMeters() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        return recentDist.subtract(olderDist);
    }
}
