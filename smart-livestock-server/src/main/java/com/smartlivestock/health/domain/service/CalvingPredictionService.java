package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.infrastructure.config.CalvingPredictionProperties;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

/**
 * Pure calving-risk kernel (NIX-381 Task 2, plan 2026-11-06 sections
 * "特征口径" and "预计分娩时间窗"). Stateless and deterministic: no repository
 * access, no clock reads — the evaluation instant {@code now} is always an
 * argument. The channel-window maths lives here on purpose so the production
 * orchestration and the simulation replayer share exactly this code instead
 * of the replayer copying private production logic.
 *
 * <p>Conventions shared by every method:</p>
 * <ul>
 *   <li>Windows are half-open event-time intervals {@code [start, end)}; a
 *       sample stamped exactly at {@code now} is never read, so samples at or
 *       after {@code now} never influence a result (no look-ahead).</li>
 *   <li>Same-phase reference level: for each configured offset (24h, 48h) the
 *       window of the current window's width ending {@code offset} hours
 *       before {@code now} is averaged; windows below the sample guard are
 *       skipped and the qualified window means are averaged with EQUAL weight
 *       (each offset counts once whatever its sample count). This differs on
 *       purpose from NIX-380, which pools the raw samples.</li>
 *   <li>Samples with a null timestamp or value (e.g. a null activityIndex)
 *       are skipped; input order is not trusted.</li>
 *   <li>Features are rounded to 2 decimals HALF_UP — the calving_predictions
 *       column scale — before scoring, so a persisted feature row reproduces
 *       its persisted score.</li>
 *   <li>Time arithmetic is {@code Instant ± Duration} only: windows are UTC
 *       instants; farm-zone formatting belongs to the presentation layer.</li>
 * </ul>
 */
@Service
public class CalvingPredictionService {

    /**
     * Fixed bonus for a detected terminal temperature rebound. The simulation
     * pipeline does not generate the rebound shape (generator P11 models a
     * linear decline only), so the value of this component cannot be backed
     * by the current simulation (plan open question 5).
     */
    public static final int REBOUND_BONUS = 10;

    private static final int FEATURE_SCALE = 2;
    private static final int PRIOR_FULL_SCORE = 100;
    private static final BigDecimal MAX_SCORE = BigDecimal.valueOf(100);
    /** Working precision for means and the weight normalization. */
    private static final MathContext MC = MathContext.DECIMAL64;

    /** Temperature sample, decoupled from the persistence model (the caller maps rows). */
    public record TempSample(Instant at, BigDecimal celsius) {
    }

    /** Activity sample, decoupled from the persistence model (the caller maps rows). */
    public record ActivitySample(Instant at, BigDecimal activityIndex) {
    }

    /** Breeding prior state, see {@link #classifyPrior}. */
    public enum PriorState {
        /** Inside the normal band: full score, weight counted. */
        NORMAL,
        /** Far from term: scores 0 with weight counted, and the composite is scaled down. */
        SUPPRESSED,
        /** No usable prior: drops out of the weight normalization. */
        NEUTRAL
    }

    /**
     * Expected calving window. Null bounds mean "cannot estimate".
     * {@code priorConflict} is true when the prior clip found no overlap: the
     * unclipped signs window is kept and callers should leave the window out
     * of the alert text (prior and signs contradict).
     */
    public record WindowEstimate(Instant start, Instant end, boolean priorConflict) {

        /** No window could be estimated. */
        public static WindowEstimate none() {
            return new WindowEstimate(null, null, false);
        }

        /** True when both bounds are known. */
        public boolean isEstimated() {
            return start != null && end != null;
        }

        /** Window midpoint (expected_calving_at), null when not estimated. */
        public Instant midpoint() {
            if (!isEstimated()) {
                return null;
            }
            return start.plus(Duration.between(start, end).dividedBy(2));
        }
    }

    /** Normalized internal sample: non-null timestamp and value. */
    private record Point(Instant at, BigDecimal value) {
    }

    // ------------------------------------------------------------ channel features

    /**
     * Net temperature drop {@code refLevel − currentLevel} in °C (2 decimals
     * HALF_UP). {@code currentLevel} is the mean of
     * {@code [now − currentTempWindowHours, now)}; {@code refLevel} is the
     * equal-weight mean of the same-phase reference window means. Positive =
     * cooler than the animal's own same-phase reference (prepartum signal);
     * negative = warmer.
     *
     * @return the drop, or null (component unavailable) when the current
     *         window holds fewer than minCurrentTempSamples samples or no
     *         reference window holds minRefTempSamples samples
     */
    public BigDecimal computeTempDrop(List<TempSample> tempsAsc, Instant now, CalvingPredictionProperties p) {
        List<Point> points = tempPoints(tempsAsc);
        Duration width = Duration.ofHours(p.getCurrentTempWindowHours());
        BigDecimal currentLevel = windowMean(points, now.minus(width), now, p.getMinCurrentTempSamples());
        if (currentLevel == null) {
            return null;
        }
        BigDecimal refLevel = samePhaseReferenceLevel(points, now, width,
                p.getRefWindowOffsetHours(), p.getMinRefTempSamples());
        if (refLevel == null) {
            return null;
        }
        return refLevel.subtract(currentLevel).setScale(FEATURE_SCALE, RoundingMode.HALF_UP);
    }

    /**
     * Activity level ratio {@code currentMean ÷ refLevel} (2 decimals HALF_UP)
     * of {@code [now − currentActivityWindowHours, now)} against the
     * same-phase reference windows. Steps and distance do not participate
     * (derived from activity in the simulation, not independent signals).
     *
     * @return the ratio, or null when the current window holds fewer than
     *         minCurrentActivitySamples non-null samples, no reference window
     *         holds minRefActivitySamples, or the reference level is not
     *         positive (ratio undefined)
     */
    public BigDecimal computeActivityRatio(List<ActivitySample> actsAsc, Instant now,
                                           CalvingPredictionProperties p) {
        List<Point> points = activityPoints(actsAsc);
        Duration width = Duration.ofHours(p.getCurrentActivityWindowHours());
        BigDecimal currentMean = windowMean(points, now.minus(width), now, p.getMinCurrentActivitySamples());
        if (currentMean == null) {
            return null;
        }
        BigDecimal refLevel = samePhaseReferenceLevel(points, now, width,
                p.getRefActivityWindowOffsetHours(), p.getMinRefActivitySamples());
        if (refLevel == null || refLevel.signum() <= 0) {
            return null;
        }
        return currentMean.divide(refLevel, FEATURE_SCALE, RoundingMode.HALF_UP);
    }

    // ------------------------------------------------------------ component scores

    /**
     * Temperature ladder: {@code ≥ high → highScore; ≥ mid → midScore;
     * ≥ low → lowScore; otherwise 0}. A negative drop (rebound / warmer than
     * reference) clamps to 0 — warmth is not evidence against calving. Null
     * scores 0 here; {@link #score} treats null as "component unavailable".
     */
    public int tempDropScore(BigDecimal tempDrop, CalvingPredictionProperties p) {
        if (tempDrop == null || tempDrop.signum() < 0) {
            return 0;
        }
        if (tempDrop.compareTo(p.getTempDropHighCelsius()) >= 0) {
            return p.getTempHighScore();
        }
        if (tempDrop.compareTo(p.getTempDropMidCelsius()) >= 0) {
            return p.getTempMidScore();
        }
        if (tempDrop.compareTo(p.getTempDropLowCelsius()) >= 0) {
            return p.getTempLowScore();
        }
        return 0;
    }

    /**
     * Activity ladder: {@code ≥ high → highScore; ≥ mid → midScore;
     * ≥ low → lowScore; otherwise 0}. Null scores 0 here; {@link #score}
     * treats null as "component unavailable".
     */
    public int activityRatioScore(BigDecimal activityRatio, CalvingPredictionProperties p) {
        if (activityRatio == null) {
            return 0;
        }
        if (activityRatio.compareTo(p.getActivityRatioHigh()) >= 0) {
            return p.getActivityHighScore();
        }
        if (activityRatio.compareTo(p.getActivityRatioMid()) >= 0) {
            return p.getActivityMidScore();
        }
        if (activityRatio.compareTo(p.getActivityRatioLow()) >= 0) {
            return p.getActivityLowScore();
        }
        return 0;
    }

    /**
     * Breeding prior from days pregnant as of now. NORMAL inside
     * {@code [priorNormalMinDays, priorNormalMaxDays]}; SUPPRESSED below
     * priorSuppressBelowDays; NEUTRAL otherwise — no BREEDING event (null),
     * overdue ({@code > priorNormalMaxDays}), the
     * {@code [priorSuppressBelowDays, priorNormalMinDays)} gap, or the prior
     * switched off.
     *
     * @param gestationDays days pregnant as of now ({@code now − last BREEDING
     *                      occurred_at}), null when unknown
     */
    public PriorState classifyPrior(Integer gestationDays, CalvingPredictionProperties p) {
        if (!p.isUseBreedingPrior() || gestationDays == null) {
            return PriorState.NEUTRAL;
        }
        int days = gestationDays;
        if (days > p.getPriorNormalMaxDays()) {
            return PriorState.NEUTRAL;
        }
        if (days >= p.getPriorNormalMinDays()) {
            return PriorState.NORMAL;
        }
        if (days < p.getPriorSuppressBelowDays()) {
            return PriorState.SUPPRESSED;
        }
        return PriorState.NEUTRAL;
    }

    /**
     * Composite calving risk 0-100.
     *
     * <ol>
     *   <li>Each available component contributes {@code score × weight}; the
     *       sum is divided by the weights of the available components only
     *       (NIX-380 normalization). A null tempDrop / activityRatio and a
     *       NEUTRAL prior drop their weight — with the prior neutral the
     *       default 0.45 / 0.35 renormalize to 0.5625 / 0.4375. A negative
     *       tempDrop is available and scores 0 (its weight stays).</li>
     *   <li>A SUPPRESSED prior is an available component scoring 0, and the
     *       weighted composite is then multiplied by priorSuppressionFactor.</li>
     *   <li>A detected rebound adds {@link #REBOUND_BONUS} after the
     *       suppression; the switch is honored here too, so a disabled
     *       feature can never leak a bonus.</li>
     *   <li>Clamp to [0, 100] and round HALF_UP. No available component
     *       gives a composite of 0.</li>
     * </ol>
     *
     * @param tempDrop        output of {@link #computeTempDrop}, null if unavailable
     * @param activityRatio   output of {@link #computeActivityRatio}, null if unavailable
     * @param gestationDays   days pregnant as of now, null when unknown
     * @param reboundDetected output of {@link #isReboundDetected}
     */
    public int score(BigDecimal tempDrop, BigDecimal activityRatio, Integer gestationDays,
                     boolean reboundDetected, CalvingPredictionProperties p) {
        BigDecimal weightedSum = BigDecimal.ZERO;
        BigDecimal weightSum = BigDecimal.ZERO;
        if (tempDrop != null) {
            BigDecimal weight = BigDecimal.valueOf(p.getWeightTempDrop());
            weightedSum = weightedSum.add(BigDecimal.valueOf(tempDropScore(tempDrop, p)).multiply(weight));
            weightSum = weightSum.add(weight);
        }
        if (activityRatio != null) {
            BigDecimal weight = BigDecimal.valueOf(p.getWeightActivity());
            weightedSum = weightedSum.add(BigDecimal.valueOf(activityRatioScore(activityRatio, p)).multiply(weight));
            weightSum = weightSum.add(weight);
        }
        PriorState prior = classifyPrior(gestationDays, p);
        if (prior != PriorState.NEUTRAL) {
            BigDecimal weight = BigDecimal.valueOf(p.getWeightPrior());
            int priorScore = prior == PriorState.NORMAL ? PRIOR_FULL_SCORE : 0;
            weightedSum = weightedSum.add(BigDecimal.valueOf(priorScore).multiply(weight));
            weightSum = weightSum.add(weight);
        }

        BigDecimal total = weightSum.signum() == 0 ? BigDecimal.ZERO : weightedSum.divide(weightSum, MC);
        if (prior == PriorState.SUPPRESSED) {
            total = total.multiply(BigDecimal.valueOf(p.getPriorSuppressionFactor()));
        }
        if (reboundDetected && p.isReboundDetectionEnabled()) {
            total = total.add(BigDecimal.valueOf(REBOUND_BONUS));
        }
        total = total.max(BigDecimal.ZERO).min(MAX_SCORE);
        return total.setScale(0, RoundingMode.HALF_UP).intValueExact();
    }

    // ------------------------------------------------------------ rebound and onset

    /**
     * Terminal temperature rebound (plan open question 5). The lookback
     * {@code [now − reboundLookbackHours, now)} is tiled into contiguous
     * blocks of reboundWindowHours (12h / 3h → four blocks); a block mean
     * needs minRefTempSamples samples. Detected when
     * {@code firstBlockMean − lowestBlockMean ≥ reboundDropCelsius} (net drop
     * inside the lookback) AND {@code latestBlockMean − lowestBlockMean ≥
     * reboundRiseCelsius} (rise into the latest block).
     *
     * <p>Fixed contiguous blocks instead of sliding windows: fewer candidates
     * keep the lowest-mean pick less biased by noise. The lowest block is
     * taken over all qualified blocks; as both thresholds are positive it can
     * only pass when it lies strictly between the first and the latest block.
     * Under-sampled interior blocks are skipped; an under-sampled first or
     * latest block, an empty input or the switch off yields false.</p>
     */
    public boolean isReboundDetected(List<TempSample> tempsAsc, Instant now, CalvingPredictionProperties p) {
        if (!p.isReboundDetectionEnabled()) {
            return false;
        }
        long blockHours = p.getReboundWindowHours();
        if (blockHours <= 0) {
            return false;
        }
        int blockCount = (int) (p.getReboundLookbackHours() / blockHours);
        if (blockCount < 3) {
            return false;
        }
        List<Point> points = tempPoints(tempsAsc);
        Duration block = Duration.ofHours(blockHours);
        Instant lookbackStart = now.minus(block.multipliedBy(blockCount));

        BigDecimal[] blockMeans = new BigDecimal[blockCount];
        for (int k = 0; k < blockCount; k++) {
            Instant start = lookbackStart.plus(block.multipliedBy(k));
            blockMeans[k] = windowMean(points, start, start.plus(block), p.getMinRefTempSamples());
        }
        BigDecimal first = blockMeans[0];
        BigDecimal latest = blockMeans[blockCount - 1];
        if (first == null || latest == null) {
            return false;
        }
        BigDecimal lowest = first;
        for (BigDecimal mean : blockMeans) {
            if (mean != null && mean.compareTo(lowest) < 0) {
                lowest = mean;
            }
        }
        boolean dropped = first.subtract(lowest).compareTo(p.getReboundDropCelsius()) >= 0;
        boolean rose = latest.subtract(lowest).compareTo(p.getReboundRiseCelsius()) >= 0;
        return dropped && rose;
    }

    /**
     * Onset of the temperature decline. Scans adjacent sample pairs from
     * oldest to newest (sorted by time; samples at or after {@code now}
     * ignored) and returns the timestamp of the EARLIER sample of the first
     * pair of the first run of onsetConsecutiveSamples consecutive pairs that
     * each drop by at least onsetDropCelsius ({@code previous − next ≥
     * threshold}, inclusive). The scan covers whatever range the caller
     * passes.
     */
    public Optional<Instant> detectOnset(List<TempSample> tempsAsc, Instant now, CalvingPredictionProperties p) {
        List<Point> points = new ArrayList<>();
        for (Point point : tempPoints(tempsAsc)) {
            if (point.at().isBefore(now)) {
                points.add(point);
            }
        }
        points.sort(Comparator.comparing(Point::at));

        int required = p.getOnsetConsecutiveSamples();
        int run = 0;
        Instant runStart = null;
        for (int i = 1; i < points.size(); i++) {
            Point previous = points.get(i - 1);
            BigDecimal drop = previous.value().subtract(points.get(i).value());
            if (drop.compareTo(p.getOnsetDropCelsius()) >= 0) {
                if (run == 0) {
                    runStart = previous.at();
                }
                run++;
                if (run >= required) {
                    return Optional.of(runStart);
                }
            } else {
                run = 0;
                runStart = null;
            }
        }
        return Optional.empty();
    }

    // ------------------------------------------------------------ window estimate

    /**
     * Expected calving window (an estimate — user-facing copy must say "预计").
     *
     * <ol>
     *   <li>onset present →
     *       {@code [onset + onsetWindowStartHours, onset + onsetWindowEndHours]}
     *       (Costa 2016 gradual-decline phase);</li>
     *   <li>else activity rise seen →
     *       {@code [now + activityWindowStartHours, now + activityWindowEndHours]}
     *       (~8h activity rise, widened against noise);</li>
     *   <li>else {@link WindowEstimate#none()}.</li>
     * </ol>
     *
     * <p>Prior clip (simplified per the NIX-381 Task 2 brief): when the prior
     * is on and gestationDays is known, the signs window is intersected with
     * {@code [now, now + gestationWindowAfterDays × 24h]}. An empty
     * intersection means prior and signs contradict: the unclipped signs
     * window is returned with {@code priorConflict = true} and the caller
     * leaves the window out of the alert text (plan: keep the signs window on
     * an empty intersection). Only the presence of gestationDays is
     * consulted, not its value.</p>
     *
     * @param gestationDays days pregnant as of now, null when unknown
     */
    public WindowEstimate estimateWindow(Instant now, Optional<Instant> onset, boolean activityRiseSeen,
                                         Integer gestationDays, CalvingPredictionProperties p) {
        WindowEstimate signs;
        if (onset != null && onset.isPresent()) {
            Instant at = onset.get();
            signs = new WindowEstimate(
                    at.plus(Duration.ofHours(p.getOnsetWindowStartHours())),
                    at.plus(Duration.ofHours(p.getOnsetWindowEndHours())),
                    false);
        } else if (activityRiseSeen) {
            signs = new WindowEstimate(
                    now.plus(Duration.ofHours(p.getActivityWindowStartHours())),
                    now.plus(Duration.ofHours(p.getActivityWindowEndHours())),
                    false);
        } else {
            return WindowEstimate.none();
        }

        if (!p.isUseBreedingPrior() || gestationDays == null) {
            return signs;
        }
        Instant horizon = now.plus(Duration.ofHours(24L * p.getGestationWindowAfterDays()));
        Instant clippedStart = signs.start().isAfter(now) ? signs.start() : now;
        Instant clippedEnd = signs.end().isBefore(horizon) ? signs.end() : horizon;
        if (!clippedStart.isBefore(clippedEnd)) {
            // Prior and signs contradict: keep the signs window, flag it.
            return new WindowEstimate(signs.start(), signs.end(), true);
        }
        return new WindowEstimate(clippedStart, clippedEnd, false);
    }

    // ------------------------------------------------------------ internals

    private static List<Point> tempPoints(List<TempSample> samples) {
        List<Point> points = new ArrayList<>();
        if (samples == null) {
            return points;
        }
        for (TempSample sample : samples) {
            if (sample != null && sample.at() != null && sample.celsius() != null) {
                points.add(new Point(sample.at(), sample.celsius()));
            }
        }
        return points;
    }

    private static List<Point> activityPoints(List<ActivitySample> samples) {
        List<Point> points = new ArrayList<>();
        if (samples == null) {
            return points;
        }
        for (ActivitySample sample : samples) {
            if (sample != null && sample.at() != null && sample.activityIndex() != null) {
                points.add(new Point(sample.at(), sample.activityIndex()));
            }
        }
        return points;
    }

    /** Mean of the values in {@code [start, end)}; null when fewer than
     *  {@code minSamples} (or no) points fall inside. */
    private static BigDecimal windowMean(List<Point> points, Instant start, Instant end, int minSamples) {
        BigDecimal sum = BigDecimal.ZERO;
        int count = 0;
        for (Point point : points) {
            if (!point.at().isBefore(start) && point.at().isBefore(end)) {
                sum = sum.add(point.value());
                count++;
            }
        }
        if (count == 0 || count < minSamples) {
            return null;
        }
        return sum.divide(BigDecimal.valueOf(count), MC);
    }

    /**
     * Equal-weight mean of the qualified same-phase reference window means:
     * window k spans {@code [now − offset_k − width, now − offset_k)}.
     * Windows below the sample guard are skipped; null when none qualifies.
     */
    private static BigDecimal samePhaseReferenceLevel(List<Point> points, Instant now, Duration width,
                                                      List<Long> offsetHours, int minSamples) {
        if (offsetHours == null) {
            return null;
        }
        BigDecimal sumOfMeans = BigDecimal.ZERO;
        int qualified = 0;
        for (Long offset : offsetHours) {
            if (offset == null) {
                continue;
            }
            Instant end = now.minus(Duration.ofHours(offset));
            BigDecimal mean = windowMean(points, end.minus(width), end, minSamples);
            if (mean != null) {
                sumOfMeans = sumOfMeans.add(mean);
                qualified++;
            }
        }
        if (qualified == 0) {
            return null;
        }
        return sumOfMeans.divide(BigDecimal.valueOf(qualified), MC);
    }
}
