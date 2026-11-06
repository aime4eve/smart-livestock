package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.infrastructure.config.CalvingPredictionProperties;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.TreeSet;

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
 *       window of the observation window's width ending {@code offset} hours
 *       before the ANCHOR is averaged — the anchor is the observation window
 *       end (t0 for the temperature drop, each evaluation point for the onset
 *       scan, {@code now} for the activity ratio), never a fixed {@code now}
 *       against a different observation window, so the circadian envelope
 *       cancels. Windows below the sample guard are skipped and the qualified
 *       window means are averaged with EQUAL weight (each offset counts once
 *       whatever its sample count). This differs on purpose from NIX-380,
 *       which pools the raw samples.</li>
 *   <li>Samples with a null timestamp or value (e.g. a null activityIndex)
 *       are skipped; input order is not trusted.</li>
 *   <li>Drinking valleys are not filtered here: callers pass temperature
 *       series with the drinking-event windows already removed
 *       ({@link #excludeWindows}); activity series stay raw.</li>
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
     * {@code priorConflict} is true when the signs window does not overlap the
     * breeding-prior window: the signs window is kept unchanged and callers
     * should leave the window out of the alert text (prior and signs contradict).
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

    /**
     * Half-open exclusion window {@code [start, end)}, e.g. a drinking event
     * plus its recovery. A window with a null bound excludes nothing (there is
     * no open-ended form, unlike {@code BaselineExclusionWindow}).
     */
    public record ExclusionWindow(Instant start, Instant end) {
    }

    /** Normalized internal sample: non-null timestamp and value. */
    private record Point(Instant at, BigDecimal value) {
    }

    // ------------------------------------------------------------ alert state machine

    /**
     * Alert state-machine decision for one evaluation (NIX-381 Task 4
     * extraction of the orchestration's private rules — see
     * {@code CalvingPredictionApplicationService} "Alert state machine").
     * Extracted so the production evaluation and the simulation replayer
     * share one implementation instead of a copied one. Pure: no I/O, no
     * clock.
     *
     * <ul>
     *   <li>{@code newColumnValue}: value for health_snapshots.calving_risk_score.
     *       Non-null = store the score (persist / crossed / hold band);
     *       null = clear (release) or reset (sub-persist score without a
     *       ticket, so a stale {@code prev >= alert} can never pair with a
     *       later crossing as two "consecutive" evaluations). Whether the
     *       UPDATE actually runs is {@link #storeColumn}.</li>
     *   <li>{@code raise}: the score has persisted at/above the alert
     *       threshold (crossed) and no ACTIVE ticket exists — create it.</li>
     *   <li>{@code release}: an ACTIVE ticket exists and the score fell
     *       below the release threshold — resolve it (immediate hysteresis;
     *       the hold band between release and alert keeps the ticket).</li>
     *   <li>{@code storeRow}: write a calving_predictions history row
     *       (score at/above persist, a raise or a release; steady state
     *       writes nothing).</li>
     * </ul>
     */
    public record AlertTransition(Integer newColumnValue, boolean raise, boolean release, boolean storeRow) {

        /**
         * Whether the targeted column UPDATE must run: the stored value
         * actually changes. A release/reset clears a non-null column, the
         * persist/crossed/hold branch stores a score different from prev,
         * same-value steady state skips the write. (Release implies a
         * non-null prev — an ACTIVE ticket always coexists with a stored
         * score — so the equality form reproduces the orchestration's
         * unconditional release write exactly.)
         */
        public boolean storeColumn(Integer prevColumnValue) {
            return !Objects.equals(prevColumnValue, newColumnValue);
        }
    }

    /**
     * Persistence rule: whether {@code newScore} counts as a sustained
     * crossing of the alert threshold. With alertPersistencePoints 1 a single
     * score at/above the threshold crosses; above 1 the PREVIOUS column value
     * must already sit at/above it ({@code prev >= alert && new >= alert} —
     * review 2b: the first crossing only lands the score). The column holds
     * one previous score, so any alertPersistencePoints above 2 behaves as 2.
     * Separated from {@link #transition} because the caller needs the verdict
     * before deciding whether an ACTIVE-ticket lookup can matter at all.
     */
    public boolean crossedAlert(Integer prevColumnValue, int newScore, CalvingPredictionProperties p) {
        return p.getAlertPersistencePoints() <= 1
                ? newScore >= p.getAlertThreshold()
                : prevColumnValue != null && prevColumnValue >= p.getAlertThreshold()
                        && newScore >= p.getAlertThreshold();
    }

    /**
     * One step of the alert state machine (semantics of the Task 3
     * orchestration, verbatim):
     *
     * <ol>
     *   <li>{@code crossed = crossedAlert(prev, newScore, p)}.</li>
     *   <li>{@code alertActive = (crossed || prev != null) && hasActiveAlert}
     *       — the caller only looks up the ticket when crossed or a score is
     *       stored (never-scored heads cost no lookup), and raise/release
     *       commit with the column, so an ACTIVE ticket implies a non-null
     *       column.</li>
     *   <li>{@code raise = crossed && !alertActive}.</li>
     *   <li>{@code release = alertActive && newScore < releaseThreshold}.</li>
     *   <li>Column: release → null (clear); score at/above persist, crossed
     *       or an ACTIVE ticket (hold band tracking) → newScore; otherwise →
     *       null (sub-persist reset).</li>
     *   <li>{@code storeRow = newScore >= persistThreshold || raise || release}.</li>
     * </ol>
     *
     * @param prevColumnValue health_snapshots.calving_risk_score before this
     *                        evaluation, null = never scored or released
     * @param hasActiveAlert  whether an ACTIVE CALVING_WARNING ticket exists
     *                        for the head (the caller's guarded lookup result)
     */
    public AlertTransition transition(Integer prevColumnValue, int newScore, boolean hasActiveAlert,
                                      CalvingPredictionProperties p) {
        boolean crossed = crossedAlert(prevColumnValue, newScore, p);
        boolean alertActive = (crossed || prevColumnValue != null) && hasActiveAlert;
        boolean raise = crossed && !alertActive;
        boolean release = alertActive && newScore < p.getReleaseThreshold();

        Integer newColumnValue;
        if (release) {
            newColumnValue = null;
        } else if (newScore >= p.getPersistThreshold() || crossed || alertActive) {
            newColumnValue = newScore;
        } else {
            // Below persist without a ticket: reset a stale prev, else stay silent.
            newColumnValue = null;
        }
        boolean storeRow = newScore >= p.getPersistThreshold() || raise || release;
        return new AlertTransition(newColumnValue, raise, release, storeRow);
    }

    // ------------------------------------------------------------ drinking exclusion

    /**
     * Removes the samples whose timestamp falls inside any window
     * {@code [start, end)}: a sample at {@code start} is removed, one at
     * {@code end} is kept. Window order and overlaps do not matter; null
     * windows and windows with a null bound are ignored; samples without a
     * timestamp are kept (the kernel methods skip them anyway). Null or empty
     * {@code windows} return {@code samples} itself (identity); otherwise a
     * new list in input order.
     */
    public static List<TempSample> excludeWindows(List<TempSample> samples, List<ExclusionWindow> windows) {
        if (samples == null || windows == null || windows.isEmpty()) {
            return samples;
        }
        List<TempSample> kept = new ArrayList<>();
        for (TempSample sample : samples) {
            if (sample == null || sample.at() == null || !insideAny(sample.at(), windows)) {
                kept.add(sample);
            }
        }
        return kept;
    }

    // ------------------------------------------------------------ channel features

    /**
     * Net temperature drop {@code refLevel − currentLevel} in °C (2 decimals
     * HALF_UP), read from the NEWEST CLEAN window (stale-window selection,
     * NIX-381 review 2d). Drinking exclusion empties the trailing 6h window for
     * most of the day while the prepartum decline lasts ≥ 24h, so a fixed
     * {@code [now − 6h, now)} read would leave the channel usable only a few
     * hours per night.
     *
     * <ul>
     *   <li>Observation window: {@code [t0 − currentTempWindowHours, t0)} where
     *       t0 is the LARGEST candidate instant ≥ {@code now −
     *       staleWindowMaxLagHours} whose window holds at least
     *       minCurrentTempSamples samples; candidates are {@code now} itself
     *       and every sample instant ≤ now. A fresh series therefore reads
     *       exactly {@code [now − 6h, now)} (t0 = now), as before.</li>
     *   <li>Reference: the same-phase level ANCHORED AT t0, i.e. the windows
     *       {@code [t0 − offset − 6h, t0 − offset)} — the circadian envelope
     *       only cancels when the reference sits exact 24h multiples before the
     *       observation window, not before {@code now}.</li>
     * </ul>
     *
     * <p>Positive = cooler than the animal's own same-phase reference
     * (prepartum signal); negative = warmer.</p>
     *
     * <p>Input: the caller's series with drinking-event windows already
     * excluded ({@link #excludeWindows}); the window means here do not reject
     * drinking valleys.</p>
     *
     * @return the drop, or null (component unavailable — the no-temperature
     *         score cap takes over) when no clean window exists within the
     *         stale lag or no reference window holds minRefTempSamples samples
     */
    public BigDecimal computeTempDrop(List<TempSample> tempsAsc, Instant now, CalvingPredictionProperties p) {
        List<Point> points = tempPoints(tempsAsc);
        Duration width = Duration.ofHours(p.getCurrentTempWindowHours());

        TreeSet<Instant> candidates = new TreeSet<>();
        for (Point point : points) {
            if (!point.at().isAfter(now)) {
                candidates.add(point.at());
            }
        }
        candidates.add(now);
        Instant lagFloor = now.minus(Duration.ofHours(p.getStaleWindowMaxLagHours()));

        Instant t0 = null;
        BigDecimal currentLevel = null;
        for (Instant t : candidates.descendingSet()) {
            if (t.isBefore(lagFloor)) {
                break; // older than the stale lag: no clean window close enough
            }
            BigDecimal mean = windowMean(points, t.minus(width), t, p.getMinCurrentTempSamples());
            if (mean != null) {
                t0 = t;
                currentLevel = mean;
                break;
            }
        }
        if (t0 == null) {
            return null;
        }
        BigDecimal refLevel = samePhaseReferenceLevel(points, t0, width,
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
     * <p>Input: the raw activity series. Drinking-window exclusion applies to
     * the temperature channel only — drinking does not shape the simulated
     * activity, and excluding it would remove most daytime activity samples,
     * the main short-term signal.</p>
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
     *   <li>Single-channel cap (NIX-381 review 2c), the final clamp:
     *       temperature is the main evidence channel, so when tempDrop is
     *       null the score is {@code min(score, singleChannelCapNoTemp)} —
     *       activity and/or prior alone reach the prompt level at most, never
     *       the alert level. A zero or negative tempDrop is available evidence
     *       and is not capped.</li>
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
        int rounded = total.setScale(0, RoundingMode.HALF_UP).intValueExact();
        if (tempDrop == null) {
            // Main evidence (temperature) unavailable: prompt level at most.
            rounded = Math.min(rounded, p.getSingleChannelCapNoTemp());
        }
        return rounded;
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
     *
     * <p>Input: the caller's series with drinking-event windows already
     * excluded ({@link #excludeWindows}).</p>
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
     * Onset of the temperature decline, level-based (NIX-381 review A): the
     * first sustained drop of the trailing temperature level below the
     * same-phase reference level.
     *
     * <ul>
     *   <li>Evaluation points: every distinct sample instant {@code t} before
     *       {@code now}, scanned oldest first (duplicate timestamps form one
     *       point; samples at or after {@code now} are ignored).</li>
     *   <li>Level: the mean over {@code [t − currentTempWindowHours, t)} — the
     *       sample at {@code t} is not part of its own window. A point whose
     *       window holds fewer than minCurrentTempSamples samples is skipped:
     *       it neither counts toward nor breaks a run.</li>
     *   <li>Reference: per evaluation point, the same-phase level anchored on
     *       that point — windows {@code [t − offset − 6h, t − offset)} (NIX-381
     *       review 2d; the anchoring helper is shared with
     *       {@link #computeTempDrop}). One now-anchored reference would compare
     *       night levels against day-phase windows across a 36h+ scan and
     *       fabricate crossings. A point whose reference windows are all
     *       under-sampled is skipped (the run carries over).</li>
     *   <li>Onset: the instant {@code t} of the first point of the first run of
     *       onsetConsecutiveSamples consecutive points that each satisfy
     *       {@code refLevel − level(t) ≥ onsetDropCelsius} (inclusive); the
     *       scan stops there.</li>
     * </ul>
     *
     * <p>Detection lag: the onset marks when the trailing level has sunk
     * onsetDropCelsius below the reference, not when the decline starts —
     * roughly {@code onsetDropCelsius ÷ slope} plus half the trailing window
     * later (simulated slope 0.3 °C / 36h: ~18h + ~3h).</p>
     *
     * <p>Input: the caller's series with drinking-event windows already
     * excluded ({@link #excludeWindows}); a trailing mean does not reject a
     * drinking valley (one −3 °C sample lowers a 12-sample level by 0.25 °C).</p>
     *
     * @return the onset, or empty when no qualifying run exists (including when
     *         no evaluation point has a qualified reference)
     */
    public Optional<Instant> detectOnset(List<TempSample> tempsAsc, Instant now, CalvingPredictionProperties p) {
        List<Point> points = new ArrayList<>();
        for (Point point : tempPoints(tempsAsc)) {
            if (point.at().isBefore(now)) {
                points.add(point);
            }
        }
        Duration width = Duration.ofHours(p.getCurrentTempWindowHours());

        TreeSet<Instant> evaluationPoints = new TreeSet<>();
        for (Point point : points) {
            evaluationPoints.add(point.at());
        }
        int required = p.getOnsetConsecutiveSamples();
        int run = 0;
        Instant runStart = null;
        for (Instant t : evaluationPoints) {
            BigDecimal level = windowMean(points, t.minus(width), t, p.getMinCurrentTempSamples());
            if (level == null) {
                // Under-sampled point: skipped, the run carries over.
                continue;
            }
            BigDecimal refLevel = samePhaseReferenceLevel(points, t, width,
                    p.getRefWindowOffsetHours(), p.getMinRefTempSamples());
            if (refLevel == null) {
                // Reference unavailable at this point: skipped, the run carries over.
                continue;
            }
            if (refLevel.subtract(level).compareTo(p.getOnsetDropCelsius()) >= 0) {
                if (run == 0) {
                    runStart = t;
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
     *       {@code [onset + onsetWindowStartHours, onset + onsetWindowEndHours]},
     *       default {@code [+2h, +30h]} (Burfeind 2011: once the decline is
     *       detected, calving is expected within ~24h);</li>
     *   <li>else activity rise seen →
     *       {@code [now + activityWindowStartHours, now + activityWindowEndHours]}
     *       (~8h activity rise, widened against noise);</li>
     *   <li>else {@link WindowEstimate#none()}.</li>
     * </ol>
     *
     * <p>The detected onset lags the start of the decline (see
     * {@link #detectOnset}), so the onset window counts from the detection
     * instant, not from the decline start; final offsets pending the Task 4
     * simulation calibration.</p>
     *
     * <p>Prior intersection (NIX-381 review C): when the prior is on and
     * gestationDays {@code g} is known, the due date lies
     * {@code gestationDays(config) − g} days after now and the prior window is
     * {@code [now + (gestationDays − gestationWindowBeforeDays − g) × 24h,
     * now + (gestationDays + gestationWindowAfterDays − g) × 24h]}; the signs
     * window is intersected with it. An empty intersection — including a
     * prior window lying entirely before or after the signs window — means
     * prior and signs contradict: the signs window is returned unchanged with
     * {@code priorConflict = true} and the caller leaves the window out of the
     * alert text. Without a known {@code g} (or with the prior off) the signs
     * window is returned as is. Nothing is clipped to {@code now}, so a window
     * may start in the past.</p>
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
        long daysToDue = (long) p.getGestationDays() - gestationDays;
        Instant priorStart = now.plus(Duration.ofHours(24L * (daysToDue - p.getGestationWindowBeforeDays())));
        Instant priorEnd = now.plus(Duration.ofHours(24L * (daysToDue + p.getGestationWindowAfterDays())));
        Instant start = signs.start().isAfter(priorStart) ? signs.start() : priorStart;
        Instant end = signs.end().isBefore(priorEnd) ? signs.end() : priorEnd;
        if (!start.isBefore(end)) {
            // Prior and signs contradict: keep the signs window, flag it.
            return new WindowEstimate(signs.start(), signs.end(), true);
        }
        return new WindowEstimate(start, end, false);
    }

    // ------------------------------------------------------------ internals

    /** True when {@code at} lies inside some well-formed window {@code [start, end)}. */
    private static boolean insideAny(Instant at, List<ExclusionWindow> windows) {
        for (ExclusionWindow window : windows) {
            if (window != null && window.start() != null && window.end() != null
                    && !at.isBefore(window.start()) && at.isBefore(window.end())) {
                return true;
            }
        }
        return false;
    }

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
