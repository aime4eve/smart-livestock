package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.TemperatureLog;
import com.smartlivestock.health.domain.service.EstrusAnalysisService;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Reusable same-input estrus-scoring replayer (plan 2026-11-05 Task 3
 * refactor of what used to be private logic inside
 * {@link BaselineEvaluationService}). ONE identical event sequence (the same
 * temperature/activity rows) is pushed through the production estrus-scoring
 * semantics once per baseline candidate: for every temperature arrival
 * (event-time position i) the "latest 7 activities/temperatures as of that
 * point" feed the production formulas — {@code calculateStepIncreasePercent}
 * (newest 3 vs the rest), {@code calculateDistanceDelta}, latest temp minus
 * the side's baseline — and are scored via
 * {@link EstrusAnalysisService#calculateScore}. This mirrors
 * {@code HealthApplicationService.triggerEstrusScoring} minus every write;
 * positions with fewer than 3 activities or 2 temperatures are skipped
 * exactly like the production guard.
 *
 * <p>Two sides in one pass: {@link #replay(List, List, BigDecimal, BigDecimal)}
 * always replays the DEFAULT candidate and — when a learned candidate is
 * given — the LEARNED candidate over the very same normalized sequence. The
 * two sides are independent per position (only {@code tempDelta} depends on
 * the baseline), so the result is bit-identical to replaying the sequence
 * once per baseline; the single pass just avoids re-normalizing the input.
 * The learned side is {@code null} when no learned candidate is supplied.</p>
 *
 * <p>Consumers: the admin baseline A/B evaluation (mechanism comparison) and
 * the datagen simulation evaluation (label-window alignment of ≥70 alert
 * episodes).</p>
 */
@Service
public class EstrusSeriesReplayer {

    /** Consecutive ≥70 scoring positions within this gap merge into one episode. */
    private static final Duration EPISODE_MERGE_GAP = Duration.ofHours(24);

    /** Production guard: the newest 7 rows feed each scoring position. */
    private static final int RECENT_WINDOW = 7;
    private static final int HIGH_SCORE_THRESHOLD = 70;

    private final EstrusAnalysisService estrusAnalysisService;

    public EstrusSeriesReplayer(EstrusAnalysisService estrusAnalysisService) {
        this.estrusAnalysisService = estrusAnalysisService;
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
     * already-sorted input.
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

        void accept(EstrusAnalysisService scoring, Instant at, BigDecimal tempDelta,
                    int stepIncreasePercent, BigDecimal distanceDelta) {
            int score = scoring.calculateScore(stepIncreasePercent, tempDelta, distanceDelta);
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
     * first — the in-memory equivalent of the production
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
