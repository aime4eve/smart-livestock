package com.smartlivestock.health.infrastructure.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;

import java.math.BigDecimal;
import java.util.List;

/**
 * Tunables for the calving-risk prediction pipeline (NIX-381, plan
 * 2026-11-06 "CalvingPredictionService"); all are overridable via
 * {@code smartlivestock.calving.*}. The default temperature window, composite
 * weights and rebound switch were finalized by the 2026-11-06 dev simulation
 * calibration (seed 20261105, run 31, plan 7d) — a simulated working point that
 * trades detection without a breeding record for fewer false alarms, not a
 * real-data result. The other ladders and windows remain the initial draft.
 *
 * <p>Consumers: the pure kernel {@code CalvingPredictionService} reads the
 * channel windows, ladders, breeding prior, weights, rebound and
 * window-estimate fields. The scheduling switches and the
 * persist / alert / release thresholds are consumed by the scheduler and the
 * application service (Task 3); they are only defined and validated here.</p>
 */
@Component
@ConfigurationProperties(prefix = "smartlivestock.calving")
@Getter
@Setter
public class CalvingPredictionProperties {

    // ------------------------------------------------ scheduling (Task 3)

    /** Master switch for the calving prediction scheduler. */
    private boolean enabled = true;
    /** Scheduler fixed delay in milliseconds (default 1h). */
    private long pollMs = 3_600_000;
    /** Livestock with temperature telemetry within this many minutes are evaluated. */
    private int activeWindowMinutes = 1440;
    /** Max livestock evaluated per scheduler poll. */
    private int maxPerPoll = 200;

    // ------------------------------------------- temperature drop channel

    /** Current temperature window length in hours: {@code [t0 - h, t0)}. 24h (the Burfeind 2011
     *  24h drop) because a 6h mean has an SNR of about 1 under the simulated noise. Finalized by
     *  the 2026-11-06 dev simulation calibration (seed 20261105, run 31, plan 7d). */
    private long currentTempWindowHours = 24;
    /** Same-phase reference window offsets in hours, measured back from the temperature
     *  observation window end (t0), so the circadian envelope cancels; each must be a
     *  positive multiple of 24. */
    private List<Long> refWindowOffsetHours = List.of(24L, 48L);
    /** Samples required inside the current temperature window (8 of 48 at the default
     *  24h window and 30-minute granularity). */
    private int minCurrentTempSamples = 8;
    /** Samples required per reference temperature window for it to count; also guards each rebound block. */
    private int minRefTempSamples = 4;
    /** How far back (hours, max 48) the stale-window selection may search for the newest
     *  clean temperature window: the prepartum decline lasts >= 24h, so the last clean
     *  (typically night) window stays readable through a drinking-excluded day. */
    private int staleWindowMaxLagHours = 24;
    /** Physiological gate lower bound (inclusive), applied before the drinking exclusion. Same
     *  value as {@code BaselineLearningCalculator.MIN_PLAUSIBLE_TEMP}; detached-sensor readings
     *  (a 25–35 °C environmental swing in the simulation) fall below it. */
    private BigDecimal minPlausibleTempCelsius = new BigDecimal("35.0");
    /** Physiological gate upper bound (inclusive). Same value as
     *  {@code BaselineLearningCalculator.MAX_PLAUSIBLE_TEMP}. */
    private BigDecimal maxPlausibleTempCelsius = new BigDecimal("43.0");

    /** Temperature drop (°C) rung for the high score (Burfeind 2011 24h drop). */
    private BigDecimal tempDropHighCelsius = new BigDecimal("0.30");
    /** Score at/above the high temperature rung. */
    private int tempHighScore = 100;
    /** Temperature drop (°C) rung for the mid score. */
    private BigDecimal tempDropMidCelsius = new BigDecimal("0.20");
    /** Score at/above the mid temperature rung. */
    private int tempMidScore = 70;
    /** Temperature drop (°C) rung for the low score; below it the channel scores 0. */
    private BigDecimal tempDropLowCelsius = new BigDecimal("0.12");
    /** Score at/above the low temperature rung. */
    private int tempLowScore = 45;

    // ------------------------------------------------- activity channel

    /** Current activity window length in hours: {@code [now - h, now)}. */
    private long currentActivityWindowHours = 8;
    /** Same-phase reference window offsets in hours; each must be a positive multiple of 24. */
    private List<Long> refActivityWindowOffsetHours = List.of(24L, 48L);
    /** Non-null activity samples required inside the current activity window. */
    private int minCurrentActivitySamples = 4;
    /** Non-null activity samples required per reference activity window for it to count. */
    private int minRefActivitySamples = 4;

    /** Activity ratio rung for the high score (simulation P13 / Macmillan 2022 ×1.5). */
    private BigDecimal activityRatioHigh = new BigDecimal("1.5");
    /** Score at/above the high activity rung. */
    private int activityHighScore = 100;
    /** Activity ratio rung for the mid score. */
    private BigDecimal activityRatioMid = new BigDecimal("1.3");
    /** Score at/above the mid activity rung. */
    private int activityMidScore = 70;
    /** Activity ratio rung for the low score; below it the channel scores 0. */
    private BigDecimal activityRatioLow = new BigDecimal("1.15");
    /** Score at/above the low activity rung. */
    private int activityLowScore = 45;

    // --------------------------------------------------- breeding prior

    /** Whether the last BREEDING event feeds the prior component and the window clip. */
    private boolean useBreedingPrior = true;
    /** Nominal gestation length in days (Holstein 283d): anchors the due date of the
     *  prior window; must sit inside the normal prior band. */
    private int gestationDays = 283;
    /** Lower bound (inclusive) of the normal prior band in days pregnant. */
    private int priorNormalMinDays = 270;
    /** Upper bound (inclusive) of the normal prior band; beyond it the prior is neutral. */
    private int priorNormalMaxDays = 293;
    /** Below this many days pregnant the prior suppresses the total score. */
    private int priorSuppressBelowDays = 250;
    /** Multiplier applied to the weighted composite when the prior suppresses. */
    private double priorSuppressionFactor = 0.5;

    // ------------------------------------------------- composite weights

    /** Weight of the temperature drop component. The weights 0.35 / 0.45 / 0.20 were finalized by
     *  the 2026-11-06 dev simulation calibration (seed 20261105, run 31, plan 7d): activity is the
     *  higher-SNR channel and carries more of the alert evidence. */
    private double weightTempDrop = 0.35;
    /** Weight of the activity ratio component (see {@link #weightTempDrop}). */
    private double weightActivity = 0.45;
    /** Weight of the breeding prior component (see {@link #weightTempDrop}). */
    private double weightPrior = 0.20;
    /** Score cap applied when tempDrop is unavailable (null): temperature is the
     *  main evidence channel, so activity and/or prior alone stay at the prompt
     *  level at most and never reach the alert level. Must be below alert-threshold. */
    private int singleChannelCapNoTemp = 60;

    // ------------------------------------------ terminal temperature rebound

    /** Rebound bonus switch, off by default (2026-11-06 dev simulation calibration, seed 20261105,
     *  run 31, plan 7d): the simulation pipeline never generates the rebound shape (P11 models a
     *  linear decline only), so it cannot back this component, and the run measured a 32.5% hit
     *  rate on non-prepartum grid points (plan open question 5). */
    private boolean reboundDetectionEnabled = false;
    /** Lookback span in hours, tiled into contiguous blocks of {@link #reboundWindowHours}. */
    private long reboundLookbackHours = 12;
    /** Minimum net drop (°C) from the first block mean to the lowest block mean. */
    private BigDecimal reboundDropCelsius = new BigDecimal("0.2");
    /** Block length in hours; the lookback must hold at least three whole blocks. */
    private long reboundWindowHours = 3;
    /** Minimum rise (°C) from the lowest block mean to the latest block mean. */
    private BigDecimal reboundRiseCelsius = new BigDecimal("0.12");

    // --------------------------------------- alert thresholds (Task 3)

    /** Evaluations scoring at/above this are persisted to calving_predictions. */
    private int persistThreshold = 50;
    /** Score at/above which a CALVING_WARNING alert is raised. */
    private int alertThreshold = 70;
    /** Score below which an active CALVING_WARNING alert is resolved (hysteresis). */
    private int releaseThreshold = 55;

    // ------------------------------------- onset and window estimate

    /** Minimum drop (°C) of the trailing temperature level below the same-phase
     *  reference level for an evaluation point to count toward the onset run. */
    private BigDecimal onsetDropCelsius = new BigDecimal("0.15");
    /** Consecutive qualifying evaluation points required to mark the onset. */
    private int onsetConsecutiveSamples = 2;
    /** Onset-path window start, in hours after the detected onset. Detection lags
     *  the start of the decline (drop threshold ÷ slope plus half the trailing
     *  window), so the window counts from the detection instant — Burfeind 2011:
     *  calving expected within ~24h of a detected decline. Final values pending
     *  the Task 4 simulation calibration. */
    private long onsetWindowStartHours = 2;
    /** Onset-path window end, in hours after the detected onset (see {@link #onsetWindowStartHours}). */
    private long onsetWindowEndHours = 30;

    // ----------------------- orchestration tunables (Task 3/4 consumers, defined here)

    /** Drinking exclusion window = [event_start, event_end + this buffer]. The kernel
     *  never fetches events: the caller applies the buffer — this field is the shared
     *  production/replay definition of the exclusion span. */
    private int drinkingExclusionBufferMinutes = 120;
    /** Consecutive evaluations scoring >= alert-threshold before an alert is raised: 1 or 2.
     *  The only state is the single calving_risk_score column (one previous score), so 2 is the
     *  semantic limit; validate() rejects more because larger values used to behave as 2 silently
     *  (plan 7d). The first crossing only lands the score (review 2c); release below
     *  release-threshold stays immediate. */
    private int alertPersistencePoints = 2;
    /** Activity-path window start, in hours after now. */
    private long activityWindowStartHours = 2;
    /** Activity-path window end, in hours after now. */
    private long activityWindowEndHours = 16;
    /** Prior window start: this many days before the due date
     *  (due date = last BREEDING + {@link #gestationDays}). */
    private int gestationWindowBeforeDays = 3;
    /** Prior window end: this many days after the due date. */
    private int gestationWindowAfterDays = 7;

    @PostConstruct
    void validate() {
        // Scheduling knobs (a zero fixed delay would spin the scheduler).
        requirePositive("poll-ms", pollMs);
        requirePositive("active-window-minutes", activeWindowMinutes);
        requirePositive("max-per-poll", maxPerPoll);

        // Channel windows: positive widths, same-phase reference offsets.
        requirePositive("current-temp-window-hours", currentTempWindowHours);
        requireSamePhaseOffsets("ref-window-offset-hours", refWindowOffsetHours);
        requirePositive("current-activity-window-hours", currentActivityWindowHours);
        requireSamePhaseOffsets("ref-activity-window-offset-hours", refActivityWindowOffsetHours);

        // Physiological gate: a non-empty inclusive band.
        if (minPlausibleTempCelsius.compareTo(maxPlausibleTempCelsius) >= 0) {
            throw invalid("min-plausible-temp-celsius", "must be below max-plausible-temp-celsius",
                    minPlausibleTempCelsius + "/" + maxPlausibleTempCelsius);
        }

        // Ladders: strictly monotonic rungs. The low temperature rung must be
        // positive so a zero or negative drop never scores; the low activity
        // rung must exceed 1.0 so "no change vs reference" never scores.
        if (!(tempDropHighCelsius.compareTo(tempDropMidCelsius) > 0
                && tempDropMidCelsius.compareTo(tempDropLowCelsius) > 0
                && tempDropLowCelsius.signum() > 0)) {
            throw invalid("temp-drop ladder", "rungs must satisfy high > mid > low > 0",
                    tempDropHighCelsius + "/" + tempDropMidCelsius + "/" + tempDropLowCelsius);
        }
        if (!(activityRatioHigh.compareTo(activityRatioMid) > 0
                && activityRatioMid.compareTo(activityRatioLow) > 0
                && activityRatioLow.compareTo(BigDecimal.ONE) > 0)) {
            throw invalid("activity-ratio ladder", "rungs must satisfy high > mid > low > 1.0",
                    activityRatioHigh + "/" + activityRatioMid + "/" + activityRatioLow);
        }

        // Breeding prior: band ordering drives the prior classification.
        if (!(priorSuppressBelowDays <= priorNormalMinDays
                && priorNormalMinDays <= gestationDays
                && gestationDays <= priorNormalMaxDays)) {
            throw invalid("prior bands",
                    "must satisfy prior-suppress-below-days <= prior-normal-min-days <= gestation-days <= prior-normal-max-days",
                    priorSuppressBelowDays + "/" + priorNormalMinDays + "/" + gestationDays + "/" + priorNormalMaxDays);
        }
        if (priorSuppressionFactor < 0 || priorSuppressionFactor > 1) {
            throw invalid("prior-suppression-factor", "must be within [0, 1]", priorSuppressionFactor);
        }

        // Weights: non-negative with a positive sum (normalization denominator).
        if (weightTempDrop < 0 || weightActivity < 0 || weightPrior < 0) {
            throw invalid("weights", "must be non-negative",
                    weightTempDrop + "/" + weightActivity + "/" + weightPrior);
        }
        if (weightTempDrop + weightActivity + weightPrior <= 0) {
            throw invalid("weights", "must have a positive sum",
                    weightTempDrop + "/" + weightActivity + "/" + weightPrior);
        }

        // Rebound: the lookback tiles into >= 3 whole blocks so a trough block
        // can sit strictly between the first and the latest block.
        requirePositive("rebound-window-hours", reboundWindowHours);
        if (reboundLookbackHours % reboundWindowHours != 0
                || reboundLookbackHours / reboundWindowHours < 3) {
            throw invalid("rebound-lookback-hours",
                    "must be a whole multiple (>= 3) of rebound-window-hours " + reboundWindowHours,
                    reboundLookbackHours);
        }
        if (reboundDropCelsius.signum() <= 0 || reboundRiseCelsius.signum() <= 0) {
            throw invalid("rebound thresholds", "drop and rise must be positive",
                    reboundDropCelsius + "/" + reboundRiseCelsius);
        }

        // Alert thresholds: score range plus hysteresis ordering.
        requireScore("persist-threshold", persistThreshold);
        requireScore("alert-threshold", alertThreshold);
        requireScore("release-threshold", releaseThreshold);
        if (releaseThreshold >= alertThreshold) {
            throw invalid("release-threshold", "must be below alert-threshold " + alertThreshold,
                    releaseThreshold);
        }
        // Without temperature evidence a score must never reach the alert level.
        requireScore("single-channel-cap-no-temp", singleChannelCapNoTemp);
        if (singleChannelCapNoTemp >= alertThreshold) {
            throw invalid("single-channel-cap-no-temp", "must be below alert-threshold " + alertThreshold,
                    singleChannelCapNoTemp);
        }

        // Orchestration tunables shared with Task 3/4 (exclusion span, alert persistence).
        if (staleWindowMaxLagHours <= 0 || staleWindowMaxLagHours > 48) {
            throw invalid("stale-window-max-lag-hours", "must be within 1-48", staleWindowMaxLagHours);
        }
        if (drinkingExclusionBufferMinutes < 0) {
            throw invalid("drinking-exclusion-buffer-minutes", "must be >= 0", drinkingExclusionBufferMinutes);
        }
        if (alertPersistencePoints < 1 || alertPersistencePoints > 2) {
            throw invalid("alert-persistence-points",
                    "must be 1 or 2 (the single calving_risk_score column holds one previous score, "
                            + "so 2 is the semantic limit)",
                    alertPersistencePoints);
        }

        // Onset and window estimate.
        if (onsetDropCelsius.signum() <= 0) {
            throw invalid("onset-drop-celsius", "must be positive", onsetDropCelsius);
        }
        requirePositive("onset-consecutive-samples", onsetConsecutiveSamples);
        if (onsetWindowStartHours < 0 || onsetWindowStartHours >= onsetWindowEndHours) {
            throw invalid("onset window", "must satisfy 0 <= onset-window-start-hours < onset-window-end-hours",
                    onsetWindowStartHours + "/" + onsetWindowEndHours);
        }
        if (activityWindowStartHours < 0 || activityWindowStartHours >= activityWindowEndHours) {
            throw invalid("activity window",
                    "must satisfy 0 <= activity-window-start-hours < activity-window-end-hours",
                    activityWindowStartHours + "/" + activityWindowEndHours);
        }
        if (gestationWindowBeforeDays < 0 || gestationWindowAfterDays < 0) {
            throw invalid("gestation window", "days must be non-negative",
                    gestationWindowBeforeDays + "/" + gestationWindowAfterDays);
        }
    }

    private static void requirePositive(String key, long value) {
        if (value <= 0) {
            throw invalid(key, "must be > 0", value);
        }
    }

    private static void requireScore(String key, int value) {
        if (value < 0 || value > 100) {
            throw invalid(key, "must be within [0, 100]", value);
        }
    }

    /** Same-phase invariant: each reference window sits an exact 24h multiple
     *  before the current one, so the circadian envelope cancels out. */
    private static void requireSamePhaseOffsets(String key, List<Long> offsets) {
        if (offsets == null || offsets.isEmpty()) {
            throw invalid(key, "must not be empty", offsets);
        }
        for (Long offset : offsets) {
            if (offset == null || offset <= 0 || offset % 24 != 0) {
                throw invalid(key, "entries must be positive multiples of 24", offsets);
            }
        }
    }

    private static IllegalStateException invalid(String key, String rule, Object got) {
        return new IllegalStateException("smartlivestock.calving." + key + " " + rule + ", got " + got);
    }
}
