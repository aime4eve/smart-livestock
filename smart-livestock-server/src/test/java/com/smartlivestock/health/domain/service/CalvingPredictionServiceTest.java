package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.domain.service.CalvingPredictionService.ActivitySample;
import com.smartlivestock.health.domain.service.CalvingPredictionService.ExclusionWindow;
import com.smartlivestock.health.domain.service.CalvingPredictionService.PriorState;
import com.smartlivestock.health.domain.service.CalvingPredictionService.TempSample;
import com.smartlivestock.health.domain.service.CalvingPredictionService.WindowEstimate;
import com.smartlivestock.health.infrastructure.config.CalvingPredictionProperties;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.Random;
import java.util.function.IntFunction;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for the calving-risk kernel (NIX-381 Task 2). Pure construction,
 * no mocks, no Spring context.
 *
 * <p>Hand-computed expectations use the default properties: temperature
 * ladder 0.30 / 0.20 / 0.12 °C → 100 / 70 / 45, activity ladder
 * 1.5 / 1.3 / 1.15 → 100 / 70 / 45, weights 0.45 / 0.35 / 0.20, prior bands
 * [270, 293] normal and &lt; 250 suppressed (×0.5), rebound bonus +10,
 * no-temperature cap 60, onset window {@code [onset + 2h, onset + 30h]}.
 * Series are 30-minute grids anchored on a fixed {@code NOW}. Onset cases
 * (level-based, review 2b) run on a 60h grid over a flat 38.80 reference
 * with the 0.15 °C threshold and 2 consecutive evaluation points; the prior
 * window is {@code [283 − 3 − g, 283 + 7 − g]} days from now.</p>
 */
class CalvingPredictionServiceTest {

    private static final CalvingPredictionService SERVICE = new CalvingPredictionService();
    private static final Instant NOW = Instant.parse("2026-11-06T12:00:00Z");
    private static final Duration STEP = Duration.ofMinutes(30);
    /** Reference level of the onset grids. */
    private static final BigDecimal BASE = new BigDecimal("38.80");
    /** Onset block level: 0.16 below BASE, clear of the inclusive 0.15 onset threshold. */
    private static final BigDecimal LOW = new BigDecimal("38.64");

    // ------------------------------------------------------------ temperature ladder

    @Test
    void tempDropScore_mapsFourRungsAtExactBoundaries() {
        CalvingPredictionProperties p = defaults();
        assertThat(SERVICE.tempDropScore(bd("0.30"), p)).isEqualTo(100);
        assertThat(SERVICE.tempDropScore(bd("1.50"), p)).isEqualTo(100);
        assertThat(SERVICE.tempDropScore(bd("0.29"), p)).isEqualTo(70);
        assertThat(SERVICE.tempDropScore(bd("0.20"), p)).isEqualTo(70);
        assertThat(SERVICE.tempDropScore(bd("0.19"), p)).isEqualTo(45);
        assertThat(SERVICE.tempDropScore(bd("0.12"), p)).isEqualTo(45);
        assertThat(SERVICE.tempDropScore(bd("0.11"), p)).isZero();
        assertThat(SERVICE.tempDropScore(bd("0.00"), p)).isZero();
    }

    @Test
    void tempDropScore_negativeDropFromReboundClampsToZero() {
        CalvingPredictionProperties p = defaults();
        assertThat(SERVICE.tempDropScore(bd("-0.05"), p)).isZero();
        assertThat(SERVICE.tempDropScore(bd("-2.00"), p)).isZero();
    }

    @Test
    void score_nullTempDropIsUnavailable_whileNegativeTempDropKeepsItsWeight() {
        CalvingPredictionProperties p = defaults();
        // null: temperature drops out, activity 1.15 -> 45 carries alone -> 45 (below the
        // no-temperature cap 60; a kept weight would give 45*0.35 / 0.80 = 19.7 -> 20)
        assertThat(SERVICE.score(null, bd("1.15"), null, false, p)).isEqualTo(45);
        // negative: available scoring 0 -> (0*0.45 + 100*0.35) / 0.80 = 43.75 -> 44
        assertThat(SERVICE.score(bd("-0.50"), bd("1.5"), null, false, p)).isEqualTo(44);
        // nothing available at all -> 0
        assertThat(SERVICE.score(null, null, null, false, p)).isZero();
    }

    // ------------------------------------------------------------ same-phase pooling

    @Test
    void computeTempDrop_samePhaseWindowsCountWithEqualWeight() {
        List<TempSample> samples = new ArrayList<>();
        // current [now-6h, now): 12 samples alternating 38.40 / 38.60 -> mean 38.50
        for (int i = 0; i < 12; i++) {
            samples.add(new TempSample(hoursAgo(6).plus(STEP.multipliedBy(i)), bd(i % 2 == 0 ? "38.40" : "38.60")));
        }
        // 24h reference [now-30h, now-24h): 12 samples -> 38.80
        samples.addAll(tempSeries(30, 12, "38.80"));
        // 48h reference [now-54h, now-48h): only 4 samples (guard is 4) -> 38.60
        samples.addAll(tempSeries(54, 4, "38.60"));
        // half-open boundary probes: none of them may enter any window
        samples.add(new TempSample(NOW, bd("30.00")));
        samples.add(new TempSample(hoursAgo(24), bd("30.00")));
        samples.add(new TempSample(hoursAgo(48), bd("30.00")));
        samples.add(new TempSample(hoursAgo(12), bd("30.00")));

        // equal weight per window: (38.80 + 38.60) / 2 = 38.70 -> 38.70 - 38.50 = 0.20
        // (pooling the 16 raw reference samples would give 38.75 -> 0.25)
        BigDecimal drop = SERVICE.computeTempDrop(samples, NOW, defaults());
        assertThat(drop).isEqualByComparingTo("0.20");
        assertThat(drop.scale()).isEqualTo(2);
    }

    @Test
    void computeTempDrop_roundsHalfUpToTwoDecimals() {
        List<TempSample> samples = new ArrayList<>(tempSeries(6, 11, "38.50"));
        samples.add(new TempSample(hoursAgo(0.5), bd("38.44")));
        samples.addAll(tempSeries(30, 12, "38.80"));
        samples.addAll(tempSeries(54, 12, "38.80"));

        // current = (11 * 38.50 + 38.44) / 12 = 461.94 / 12 = 38.495; ref = 38.80
        // drop = 0.305 -> HALF_UP 0.31 (HALF_EVEN would give 0.30)
        assertThat(SERVICE.computeTempDrop(samples, NOW, defaults())).isEqualByComparingTo("0.31");
    }

    @Test
    void computeTempDrop_underSampledReferenceWindowIsSkipped() {
        List<TempSample> samples = concat(
                tempSeries(6, 12, "38.50"),
                tempSeries(30, 12, "38.80"),
                // 3 < 4 samples: skipped, its outlier value never reaches the level
                tempSeries(54, 3, "30.00"));

        // ref = 38.80 (24h window only) -> 38.80 - 38.50 = 0.30
        assertThat(SERVICE.computeTempDrop(samples, NOW, defaults())).isEqualByComparingTo("0.30");
    }

    @Test
    void computeTempDrop_allReferenceWindowsUnderSampled_isUnavailable() {
        List<TempSample> samples = concat(
                tempSeries(6, 12, "38.50"),
                tempSeries(30, 3, "38.80"),
                tempSeries(54, 3, "38.80"));

        assertThat(SERVICE.computeTempDrop(samples, NOW, defaults())).isNull();
    }

    @Test
    void computeTempDrop_currentWindowGuardIsEightSamples() {
        List<TempSample> refs = concat(tempSeries(30, 12, "38.80"), tempSeries(54, 12, "38.80"));

        // 7 samples [now-3.5h, now) -> unavailable
        assertThat(SERVICE.computeTempDrop(concat(tempSeries(3.5, 7, "38.50"), refs), NOW, defaults()))
                .isNull();
        // 8 samples [now-4h, now) -> 38.80 - 38.50 = 0.30
        assertThat(SERVICE.computeTempDrop(concat(tempSeries(4, 8, "38.50"), refs), NOW, defaults()))
                .isEqualByComparingTo("0.30");
        // no samples at all -> unavailable
        assertThat(SERVICE.computeTempDrop(List.of(), NOW, defaults())).isNull();
        assertThat(SERVICE.computeTempDrop(null, NOW, defaults())).isNull();
    }

    // ------------------------------------------------------------ stale-window selection (review 2d)

    @Test
    void computeTempDrop_staleWindowSelectsNewestCleanWindowWithAnchoredReferences() {
        // Daytime evaluation: drinking exclusion left only 3 samples after last
        // night's clean window, which ends at t0 = now-10h.
        List<TempSample> samples = concat(
                tempSeries(15.5, 12, "38.50"),   // clean night window [now-16h, now-10h) -> t0 = now-10h
                // an OLDER clean block inside the lag at another level: newest wins, not oldest
                tempSeries(23, 12, "38.80"),
                // post-t0 scarcity: every newer candidate window holds fewer than 8 samples
                tempSeries(6, 1, "38.50"), tempSeries(3, 1, "38.50"), tempSeries(1, 1, "38.50"),
                // references anchored at t0: [now-40h, now-34h) and [now-64h, now-58h)
                tempSeries(40, 12, "38.90"), tempSeries(64, 12, "38.70"),
                // decoys where now-anchored references would read (4 samples each: they qualify)
                tempSeries(30, 4, "38.00"), tempSeries(54, 4, "38.00"));

        // t0-anchored: ref = (38.90 + 38.70) / 2 = 38.80 -> 38.80 - 38.50 = 0.30
        // (now-anchored references would pool the 38.00 decoys -> -0.50)
        assertThat(SERVICE.computeTempDrop(samples, NOW, defaults())).isEqualByComparingTo("0.30");
    }

    @Test
    void computeTempDrop_referenceAnchoredToObservationWindow_circadianCancels() {
        // 24h-periodic square wave (±0.20 around 38.80), no decline. Continuous from
        // now-64.5h to t0 = now-10h, then only 2 samples -> the night window is read.
        List<TempSample> samples = new ArrayList<>();
        for (double h = 64.5; h >= 10; h -= 0.5) {
            samples.add(new TempSample(hoursAgo(h), circadian(h, "0.20")));
        }
        samples.add(new TempSample(hoursAgo(4), circadian(4, "0.20")));
        samples.add(new TempSample(hoursAgo(1), circadian(1, "0.20")));

        // References 24h / 48h before the OBSERVATION window sample the same phase:
        // ref - current = 0.00 exactly (window [now-16h, now-10h): 4 high + 8 low slots,
        // so are both references). Anchored at now they would read 12 high slots -> 0.27.
        assertThat(SERVICE.computeTempDrop(samples, NOW, defaults())).isEqualByComparingTo("0.00");
    }

    @Test
    void computeTempDrop_staleLagBoundary_inclusiveAtLimitNullBeyond() {
        CalvingPredictionProperties p = defaults();
        // Newest clean candidate exactly at the lag limit: t0 = now-24h (lag 24 <= 24).
        // Its window [now-30h, now-24h) holds 11 samples (the one at t0 is the open end).
        List<TempSample> atLimit = concat(
                tempSeries(29.5, 12, "38.50"),
                tempSeries(54, 12, "38.80"),     // ref [t0-30h, t0-24h) = [now-54h, now-48h)
                tempSeries(78, 12, "38.80"));    // ref [t0-54h, t0-48h) = [now-78h, now-72h)
        assertThat(SERVICE.computeTempDrop(atLimit, NOW, p)).isEqualByComparingTo("0.30");

        // Same block shifted half an hour older: newest candidate now-24.5h is beyond the
        // lag -> no clean window close enough -> null (the no-temperature cap takes over).
        List<TempSample> beyondLimit = concat(
                tempSeries(30, 12, "38.50"),
                tempSeries(54.5, 12, "38.80"),
                tempSeries(78.5, 12, "38.80"));
        assertThat(SERVICE.computeTempDrop(beyondLimit, NOW, p)).isNull();
    }

    // ------------------------------------------------------------ activity channel

    @Test
    void computeActivityRatio_samePhaseWindowsCountWithEqualWeight() {
        List<ActivitySample> samples = concat(
                // current [now-8h, now): 16 samples -> 60
                actSeries(8, 16, "60"),
                // 24h reference [now-32h, now-24h): 16 samples -> 40
                actSeries(32, 16, "40"),
                // 48h reference [now-56h, now-48h): 4 samples -> 48
                actSeries(56, 4, "48"));

        // ref = (40 + 48) / 2 = 44 -> 60 / 44 = 1.3636 -> 1.36
        // (pooling the 20 raw reference samples would give 41.6 -> 1.44)
        BigDecimal ratio = SERVICE.computeActivityRatio(samples, NOW, defaults());
        assertThat(ratio).isEqualByComparingTo("1.36");
        assertThat(ratio.scale()).isEqualTo(2);
    }

    @Test
    void computeActivityRatio_nullActivityIndexSamplesAreSkipped() {
        List<ActivitySample> refs = concat(actSeries(32, 16, "40"), actSeries(56, 16, "40"));

        // 4 valid samples (i = 0, 4, 8, 12) among 12 null-index rows
        List<ActivitySample> fourValid = new ArrayList<>(refs);
        // 3 valid samples (i = 0, 4, 8): below the guard of 4
        List<ActivitySample> threeValid = new ArrayList<>(refs);
        for (int i = 0; i < 16; i++) {
            Instant at = hoursAgo(8).plus(STEP.multipliedBy(i));
            fourValid.add(new ActivitySample(at, i % 4 == 0 ? bd("60") : null));
            threeValid.add(new ActivitySample(at, i % 4 == 0 && i < 12 ? bd("60") : null));
        }

        // nulls neither count toward the guard nor drag the mean: 60 / 40 = 1.50
        assertThat(SERVICE.computeActivityRatio(fourValid, NOW, defaults())).isEqualByComparingTo("1.50");
        assertThat(SERVICE.computeActivityRatio(threeValid, NOW, defaults())).isNull();
    }

    @Test
    void computeActivityRatio_insufficientOrZeroReference_isUnavailable() {
        CalvingPredictionProperties p = defaults();
        // current window holds 3 < 4 samples
        assertThat(SERVICE.computeActivityRatio(
                concat(actSeries(8, 3, "60"), actSeries(32, 16, "40"), actSeries(56, 16, "40")), NOW, p))
                .isNull();
        // both reference windows hold 3 < 4 samples
        assertThat(SERVICE.computeActivityRatio(
                concat(actSeries(8, 16, "60"), actSeries(32, 3, "40"), actSeries(56, 3, "40")), NOW, p))
                .isNull();
        // reference level 0: ratio undefined
        assertThat(SERVICE.computeActivityRatio(
                concat(actSeries(8, 16, "60"), actSeries(32, 16, "0"), actSeries(56, 16, "0")), NOW, p))
                .isNull();
    }

    @Test
    void activityRatioScore_mapsThreeRungsAtExactBoundaries() {
        CalvingPredictionProperties p = defaults();
        assertThat(SERVICE.activityRatioScore(bd("1.50"), p)).isEqualTo(100);
        assertThat(SERVICE.activityRatioScore(bd("2.40"), p)).isEqualTo(100);
        assertThat(SERVICE.activityRatioScore(bd("1.49"), p)).isEqualTo(70);
        assertThat(SERVICE.activityRatioScore(bd("1.30"), p)).isEqualTo(70);
        assertThat(SERVICE.activityRatioScore(bd("1.29"), p)).isEqualTo(45);
        assertThat(SERVICE.activityRatioScore(bd("1.15"), p)).isEqualTo(45);
        assertThat(SERVICE.activityRatioScore(bd("1.14"), p)).isZero();
        assertThat(SERVICE.activityRatioScore(bd("0.80"), p)).isZero();
    }

    @Test
    void score_nullActivityRatioIsUnavailable() {
        CalvingPredictionProperties p = defaults();
        // null: temperature 0.30 -> 100 carries alone -> 100
        assertThat(SERVICE.score(bd("0.30"), null, null, false, p)).isEqualTo(100);
        // ratio 1.00 is available and scores 0: (100*0.45 + 0*0.35) / 0.80 = 56.25 -> 56
        assertThat(SERVICE.score(bd("0.30"), bd("1.00"), null, false, p)).isEqualTo(56);
    }

    // ------------------------------------------------------------ breeding prior

    @Test
    void classifyPrior_bandBoundaries() {
        CalvingPredictionProperties p = defaults();
        assertThat(SERVICE.classifyPrior(270, p)).isEqualTo(PriorState.NORMAL);
        assertThat(SERVICE.classifyPrior(283, p)).isEqualTo(PriorState.NORMAL);
        assertThat(SERVICE.classifyPrior(293, p)).isEqualTo(PriorState.NORMAL);
        assertThat(SERVICE.classifyPrior(294, p)).isEqualTo(PriorState.NEUTRAL);
        assertThat(SERVICE.classifyPrior(269, p)).isEqualTo(PriorState.NEUTRAL);
        assertThat(SERVICE.classifyPrior(250, p)).isEqualTo(PriorState.NEUTRAL);
        assertThat(SERVICE.classifyPrior(249, p)).isEqualTo(PriorState.SUPPRESSED);
        assertThat(SERVICE.classifyPrior(0, p)).isEqualTo(PriorState.SUPPRESSED);
        assertThat(SERVICE.classifyPrior(null, p)).isEqualTo(PriorState.NEUTRAL);
    }

    @Test
    void score_priorNormal_handComputedFullWeightOracle() {
        // tempDrop 0.25 -> 70, activityRatio 1.4 -> 70, gestation 275 -> 100
        // (70*0.45 + 70*0.35 + 100*0.20) / 1.00 = 31.5 + 24.5 + 20 = 76
        assertThat(SERVICE.score(bd("0.25"), bd("1.4"), 275, false, defaults())).isEqualTo(76);
    }

    @Test
    void score_priorSuppressed_scoresZeroAndHalvesTheComposite() {
        // gestation 240 < 250: prior available at 0 -> (31.5 + 24.5 + 0) / 1.00 = 56 -> x0.5 = 28
        assertThat(SERVICE.score(bd("0.25"), bd("1.4"), 240, false, defaults())).isEqualTo(28);
    }

    @Test
    void score_priorNeutral_renormalizesTempAndActivityWeights() {
        CalvingPredictionProperties p = defaults();
        // tempDrop 0.30 -> 100, activityRatio 1.15 -> 45; prior drops out:
        // 0.45/0.80 = 0.5625, 0.35/0.80 = 0.4375 -> 100*0.5625 + 45*0.4375 = 75.9375 -> 76
        assertThat(SERVICE.score(bd("0.30"), bd("1.15"), null, false, p)).isEqualTo(76);  // no BREEDING event
        assertThat(SERVICE.score(bd("0.30"), bd("1.15"), 300, false, p)).isEqualTo(76);   // overdue
        assertThat(SERVICE.score(bd("0.30"), bd("1.15"), 260, false, p)).isEqualTo(76);   // [250, 270) gap
        // contrast: a NORMAL prior keeps the full denominator -> 45 + 15.75 + 20 = 80.75 -> 81
        assertThat(SERVICE.score(bd("0.30"), bd("1.15"), 280, false, p)).isEqualTo(81);
    }

    @Test
    void score_priorSwitchedOff_ignoresGestationEntirely() {
        CalvingPredictionProperties p = defaults();
        p.setUseBreedingPrior(false);
        assertThat(SERVICE.classifyPrior(275, p)).isEqualTo(PriorState.NEUTRAL);
        assertThat(SERVICE.classifyPrior(240, p)).isEqualTo(PriorState.NEUTRAL);
        // neither the full score nor the suppression applies -> renormalized 76
        assertThat(SERVICE.score(bd("0.30"), bd("1.15"), 240, false, p)).isEqualTo(76);
        assertThat(SERVICE.score(bd("0.30"), bd("1.15"), 275, false, p)).isEqualTo(76);
    }

    // ------------------------------------------------------------ single-channel cap (no temperature)

    @Test
    void score_noTemperature_activityOnlyIsCappedAtPromptLevel() {
        CalvingPredictionProperties p = defaults();
        assertThat(p.getSingleChannelCapNoTemp()).isEqualTo(60);
        // activity 1.5 -> 100 alone -> capped to 60 (prompt level, below the 70 alert line)
        assertThat(SERVICE.score(null, bd("1.5"), null, false, p)).isEqualTo(60);
        // activity + NORMAL prior: (100*0.35 + 100*0.20) / 0.55 = 100 -> 60
        assertThat(SERVICE.score(null, bd("1.5"), 280, false, p)).isEqualTo(60);
        // the cap is the final clamp: the rebound bonus cannot lift past it (110 -> 100 -> 60)
        assertThat(SERVICE.score(null, bd("1.5"), 280, true, p)).isEqualTo(60);
        // configured cap honored
        p.setSingleChannelCapNoTemp(40);
        assertThat(SERVICE.score(null, bd("1.5"), null, false, p)).isEqualTo(40);
    }

    @Test
    void score_temperatureAvailable_twoChannelScoresAreNotCapped() {
        CalvingPredictionProperties p = defaults();
        // temperature + NORMAL prior, activity unavailable: (100*0.45 + 100*0.20) / 0.65 = 100
        assertThat(SERVICE.score(bd("0.30"), null, 280, false, p)).isEqualTo(100);
        // a zero drop is available evidence, not a missing channel:
        // (0*0.45 + 100*0.35 + 100*0.20) / 1.00 = 55, + rebound 10 = 65 > 60 -> stays 65
        assertThat(SERVICE.score(bd("0.00"), bd("1.5"), 280, true, p)).isEqualTo(65);
    }

    @Test
    void score_noTemperatureWithSuppressedPrior_suppressionThenCap() {
        CalvingPredictionProperties p = defaults();
        // activity 1.5 -> 100, prior SUPPRESSED (g = 240) counted at 0:
        // (100*0.35 + 0*0.20) / 0.55 = 63.64 -> x0.5 = 31.82 -> 32; min(32, 60) never raises a score
        assertThat(SERVICE.score(null, bd("1.5"), 240, false, p)).isEqualTo(32);
        // plus rebound: 31.82 + 10 = 41.82 -> 42, still under the cap
        assertThat(SERVICE.score(null, bd("1.5"), 240, true, p)).isEqualTo(42);
        // a no-op suppression factor 1.0 leaves 63.64 -> 64 -> the cap binds -> 60
        p.setPriorSuppressionFactor(1.0);
        assertThat(SERVICE.score(null, bd("1.5"), 240, false, p)).isEqualTo(60);
    }

    // ------------------------------------------------------------ rebound bonus and clamp

    @Test
    void score_reboundAddsFixedBonusOnlyWhileTheSwitchIsOn() {
        CalvingPredictionProperties p = defaults();
        assertThat(CalvingPredictionService.REBOUND_BONUS).isEqualTo(10);
        // 76 + 10 = 86
        assertThat(SERVICE.score(bd("0.25"), bd("1.4"), 275, true, p)).isEqualTo(86);
        // the bonus lands after the suppression: 28 + 10 = 38
        assertThat(SERVICE.score(bd("0.25"), bd("1.4"), 240, true, p)).isEqualTo(38);
        // switch off: a caller-supplied rebound flag cannot leak the bonus
        p.setReboundDetectionEnabled(false);
        assertThat(SERVICE.score(bd("0.25"), bd("1.4"), 275, true, p)).isEqualTo(76);
    }

    @Test
    void score_allChannelsMaxedPlusRebound_clampsAt100() {
        // (100*0.45 + 100*0.35 + 100*0.20) / 1.00 = 100, + 10 = 110 -> 100
        assertThat(SERVICE.score(bd("0.50"), bd("2.00"), 280, true, defaults())).isEqualTo(100);
    }

    @Test
    void score_allChannelsZero_isZero() {
        CalvingPredictionProperties p = defaults();
        assertThat(SERVICE.score(bd("0.00"), bd("1.00"), 260, false, p)).isZero();
        assertThat(SERVICE.score(bd("-1.00"), bd("0.50"), null, false, p)).isZero();
    }

    // ------------------------------------------------------------ rebound detection

    @Test
    void isReboundDetected_dropThenRiseAcrossBlocks_detected() {
        // blocks of 3h: first 38.80, 38.70, lowest 38.55, latest 38.70
        // drop = 38.80 - 38.55 = 0.25 >= 0.2; rise = 38.70 - 38.55 = 0.15 >= 0.12
        assertThat(SERVICE.isReboundDetected(reboundSeries("38.80", "38.70", "38.55", "38.70"), NOW, defaults()))
                .isTrue();
    }

    @Test
    void isReboundDetected_switchOff_alwaysFalse() {
        CalvingPredictionProperties p = defaults();
        p.setReboundDetectionEnabled(false);
        assertThat(SERVICE.isReboundDetected(reboundSeries("38.80", "38.70", "38.55", "38.70"), NOW, p))
                .isFalse();
    }

    @Test
    void isReboundDetected_riseBelowThreshold_false() {
        CalvingPredictionProperties p = defaults();
        // rise 38.67 - 38.55 = 0.12: inclusive threshold -> detected
        assertThat(SERVICE.isReboundDetected(reboundSeries("38.80", "38.70", "38.55", "38.67"), NOW, p))
                .isTrue();
        // rise 38.66 - 38.55 = 0.11 < 0.12 -> not detected
        assertThat(SERVICE.isReboundDetected(reboundSeries("38.80", "38.70", "38.55", "38.66"), NOW, p))
                .isFalse();
        // drop 38.70 - 38.55 = 0.15 < 0.2 -> not detected despite the rise
        assertThat(SERVICE.isReboundDetected(reboundSeries("38.70", "38.70", "38.55", "38.70"), NOW, p))
                .isFalse();
        // plain linear decline (the simulated prepartum shape): the latest block is the lowest -> no rise
        assertThat(SERVICE.isReboundDetected(reboundSeries("38.90", "38.80", "38.70", "38.60"), NOW, p))
                .isFalse();
    }

    @Test
    void isReboundDetected_insufficientSamples_false() {
        CalvingPredictionProperties p = defaults();
        // latest block holds 3 < 4 samples
        List<TempSample> shortLatest = concat(
                tempSeries(12, 6, "38.80"), tempSeries(9, 6, "38.70"),
                tempSeries(6, 6, "38.55"), tempSeries(3, 3, "38.70"));
        assertThat(SERVICE.isReboundDetected(shortLatest, NOW, p)).isFalse();
        assertThat(SERVICE.isReboundDetected(List.of(), NOW, p)).isFalse();
        assertThat(SERVICE.isReboundDetected(null, NOW, p)).isFalse();
    }

    // ------------------------------------------------------------ drinking exclusion

    @Test
    void excludeWindows_removesSamplesInsideHalfOpenWindow() {
        List<TempSample> samples = tempSeries(3, 6, "38.80"); // now-3h ... now-0.5h
        // [now-2.5h, now-1.5h): the sample at start is removed, the one at end kept; order preserved
        List<TempSample> kept = CalvingPredictionService.excludeWindows(samples,
                List.of(new ExclusionWindow(hoursAgo(2.5), hoursAgo(1.5))));
        assertThat(kept).extracting(TempSample::at)
                .containsExactly(hoursAgo(3), hoursAgo(1.5), hoursAgo(1), hoursAgo(0.5));
    }

    @Test
    void excludeWindows_nullOrEmptyWindows_returnInputUnchanged() {
        List<TempSample> samples = tempSeries(3, 6, "38.80");
        assertThat(CalvingPredictionService.excludeWindows(samples, null)).isSameAs(samples);
        assertThat(CalvingPredictionService.excludeWindows(samples, List.of())).isSameAs(samples);
    }

    @Test
    void excludeWindows_unorderedAndOverlappingWindows_allApplied() {
        List<TempSample> samples = tempSeries(5, 10, "38.80"); // now-5h ... now-0.5h
        List<ExclusionWindow> windows = new ArrayList<>();
        windows.add(new ExclusionWindow(hoursAgo(1), hoursAgo(0.5)));   // latest first
        windows.add(new ExclusionWindow(hoursAgo(4), hoursAgo(3)));     // overlaps the next window
        windows.add(new ExclusionWindow(hoursAgo(4.5), hoursAgo(3.5)));
        windows.add(new ExclusionWindow(hoursAgo(2), hoursAgo(2)));     // empty: removes nothing
        windows.add(new ExclusionWindow(null, hoursAgo(2.5)));          // malformed: ignored
        windows.add(null);                                              // ignored
        // removed: now-4.5h, now-4h, now-3.5h, now-1h
        assertThat(CalvingPredictionService.excludeWindows(samples, windows)).extracting(TempSample::at)
                .containsExactly(hoursAgo(5), hoursAgo(3), hoursAgo(2.5), hoursAgo(2), hoursAgo(1.5), hoursAgo(0.5));
    }

    // ------------------------------------------------------------ onset (level-based)

    @Test
    void detectOnset_gradualDecline_triggersWhenTrailingLevelCrossesThreshold() {
        // Simulation P11 shape: linear decline of 0.004 °C per 30-min step (≈ 0.3 °C
        // over 36h) from now-24h (j = 48); flat 38.80 before, so both same-phase
        // reference windows sit on the flat part -> reference 38.80.
        // Point j_t (t = now - j_t × 30min) averages samples j_t+1 ... j_t+12:
        // drop = 0.004 × (41.5 - j_t) once its window lies inside the decline.
        // j_t = 5 -> 0.146 (no); j_t = 4 -> 0.150 (inclusive: yes); j_t = 3 -> 0.154 (yes)
        // -> onset now-2h, 22h after the decline start (0.15 / 0.008 per h = 18.75h
        // + 3.25h window centroid). Every adjacent step is 0.004 °C, so the removed
        // adjacent-pair rule could never fire on this shape.
        List<TempSample> decline = declineGrid();
        assertThat(SERVICE.detectOnset(decline, NOW, defaults())).contains(hoursAgo(2));

        List<TempSample> shuffled = new ArrayList<>(decline);
        Collections.shuffle(shuffled, new Random(20261106L));
        assertThat(SERVICE.detectOnset(shuffled, NOW, defaults())).contains(hoursAgo(2));
    }

    @Test
    void detectOnset_drinkingValley_noTriggerOnceTheDrinkingWindowIsExcluded() {
        // Flat 38.80 with one drinking valley: -3 °C at now-5h, -1 °C at now-4.5h,
        // back to flat at now-4h (down and up within 1h).
        List<TempSample> raw = grid(j -> j == 10 ? bd("35.80") : j == 9 ? bd("37.80") : BASE);

        // Contrast, raw series: a trailing mean does not reject the valley. Point
        // now-4.5h holds the -3 °C sample (3.0 / 12 = 0.25), point now-4h holds both
        // (4.0 / 12 = 0.33) -> a false onset at now-4.5h.
        assertThat(SERVICE.detectOnset(raw, NOW, defaults())).contains(hoursAgo(4.5));

        // Caller contract: exclude the drinking window [now-5h, now-4h) first -> flat -> no onset.
        List<TempSample> excluded = CalvingPredictionService.excludeWindows(raw,
                List.of(new ExclusionWindow(hoursAgo(5), hoursAgo(4))));
        assertThat(SERVICE.detectOnset(excluded, NOW, defaults())).isEmpty();
    }

    @Test
    void detectOnset_levelLowForFewerThanTwoEvaluationPoints_doesNotTrigger() {
        // A block of k samples at 38.64 (0.16 below the 38.80 reference). Only a
        // window holding the whole block reaches 0.16; one holding 11 of them gives
        // 11 × 0.16 / 12 = 0.147 (no).
        // k = 12 (j = 13..24): one qualifying point (now-6h) -> no onset.
        assertThat(SERVICE.detectOnset(grid(j -> j >= 13 && j <= 24 ? LOW : BASE), NOW, defaults()))
                .isEmpty();
        // k = 13 (j = 12..24): two qualifying points (now-6h, now-5.5h) -> onset at the first.
        assertThat(SERVICE.detectOnset(grid(j -> j >= 12 && j <= 24 ? LOW : BASE), NOW, defaults()))
                .contains(hoursAgo(6));
    }

    @Test
    void detectOnset_noiseAroundFlatLevel_doesNotTrigger() {
        CalvingPredictionProperties p = defaults();
        // Zero-mean period-3 pattern +0.20 / 0.00 / -0.20: two consecutive 0.20
        // adjacent drops every period (the removed pair rule would fire), but every
        // full 12-sample window holds four whole periods -> level = reference.
        // Partial windows at the series start deviate by at most 0.025.
        BigDecimal[] pattern = {bd("0.20"), bd("0.00"), bd("-0.20")};
        assertThat(SERVICE.detectOnset(grid(j -> BASE.add(pattern[(120 - j) % 3])), NOW, p)).isEmpty();

        // Seeded noise bounded to ±0.07: |reference - level| <= 0.14 < 0.15 by construction.
        Random rng = new Random(20261106L);
        assertThat(SERVICE.detectOnset(grid(j -> BASE.add(BigDecimal.valueOf(rng.nextInt(15) - 7L, 2))), NOW, p))
                .isEmpty();
    }

    @Test
    void detectOnset_duplicateTimestampsFormOneEvaluationPoint() {
        // The k = 12 block (one qualifying point at now-6h) plus a second sample
        // stamped now-6h: still one evaluation point; the next point (now-5.5h)
        // holds 13 samples, 11 of them low -> 11 × 0.16 / 13 = 0.135 (no).
        List<TempSample> duplicated = new ArrayList<>(grid(j -> j >= 13 && j <= 24 ? LOW : BASE));
        duplicated.add(new TempSample(hoursAgo(6), BASE));
        assertThat(SERVICE.detectOnset(duplicated, NOW, defaults())).isEmpty();
    }

    @Test
    void detectOnset_ignoresSamplesAtOrAfterNow() {
        // Low block j = 1..13 plus samples stamped now and now+0.5h. Point now-0.5h
        // qualifies (window j = 2..13); the second full-block window belongs to the
        // point at now itself, which is never evaluated -> one point, no onset.
        List<TempSample> samples = new ArrayList<>(grid(j -> j <= 13 ? LOW : BASE));
        samples.add(new TempSample(NOW, BASE));
        samples.add(new TempSample(hoursLater(0.5), LOW));
        assertThat(SERVICE.detectOnset(samples, NOW, defaults())).isEmpty();
    }

    @Test
    void detectOnset_underSampledPointsAreSkipped_runCarriesOverAGap() {
        // Low block j = 25..36 (38.64) gives exactly one qualifying point before a
        // data gap: now-12h (window j = 25..36, 0.16). No samples strictly between
        // now-12h and now-7h; afterwards 38.60 (0.20 below). Points now-7h ... now-3.5h
        // hold 3 to 7 samples in their window -> skipped; now-3h is the next valid
        // point (8 samples, 0.20). Skipped points neither count nor break the run
        // -> onset now-12h (resetting on skipped points would report now-3h).
        List<TempSample> gapped = grid(j -> j >= 37 ? BASE : j >= 25 ? LOW : j == 24 ? BASE : bd("38.60"))
                .stream()
                .filter(s -> !(s.at().isAfter(hoursAgo(12)) && s.at().isBefore(hoursAgo(7))))
                .toList();
        assertThat(SERVICE.detectOnset(gapped, NOW, defaults())).contains(hoursAgo(12));
    }

    @Test
    void detectOnset_circadianOnly_noFalseOnsetWithPerPointReference() {
        // Pure 24h square wave (±0.10 around 38.80), no decline, continuous 60h grid.
        // A now-anchored reference pools two high-phase windows (38.90) and reads the
        // night levels as drops: the oldest-first scan fires a false onset at now-43h,
        // the first night stretch (window 3 high + 9 low slots -> drop 1.5 × 0.10 = 0.15,
        // inclusive; observed in the red run before the fix). Anchored per point, every
        // level is compared with its own phase -> 0.00 at full references; truncated
        // references at the series start leak at most (0.10 + 0.10/3) / 2 = 0.07.
        assertThat(SERVICE.detectOnset(grid(j -> circadian(j * 0.5, "0.10")), NOW, defaults())).isEmpty();
    }

    @Test
    void detectOnset_referenceUnavailableOrNoInput_returnsEmpty() {
        CalvingPredictionProperties p = defaults();
        // The decline of the first onset case cut to the last 20h: no sample in either
        // same-phase reference window -> no reference level -> no onset.
        List<TempSample> recentOnly = declineGrid().stream()
                .filter(s -> s.at().isAfter(hoursAgo(20.5)))
                .toList();
        assertThat(SERVICE.detectOnset(recentOnly, NOW, p)).isEmpty();
        assertThat(SERVICE.detectOnset(List.of(), NOW, p)).isEmpty();
        assertThat(SERVICE.detectOnset(null, NOW, p)).isEmpty();
    }

    // ------------------------------------------------------------ window estimate

    @Test
    void estimateWindow_onsetPath_offsetsFromOnsetAndWinsOverActivity() {
        CalvingPredictionProperties p = defaults();
        Optional<Instant> onset = Optional.of(hoursAgo(6));

        // [onset + 2h, onset + 30h] = [now - 4h, now + 24h], midpoint now + 10h
        WindowEstimate w = SERVICE.estimateWindow(NOW, onset, false, null, p);
        assertWindow(w, hoursAgo(4), hoursLater(24), false);
        assertThat(w.midpoint()).isEqualTo(hoursLater(10));
        // an activity rise does not override the onset path
        assertWindow(SERVICE.estimateWindow(NOW, onset, true, null, p), hoursAgo(4), hoursLater(24), false);
    }

    @Test
    void estimateWindow_defaultOnsetWindowCoversCalvingOfSimulatedDecline() {
        CalvingPredictionProperties p = defaults();
        // declineGrid: decline from now-24h at 0.008 °C/h; a 36h simulated decline ends
        // at calving -> now + 12h. The onset is detected at now-2h (22h lag), so the
        // default window [onset + 2h, onset + 30h] = [now, now + 28h] covers the calving;
        // the former [+24h, +48h] default gave [now + 22h, now + 46h] and missed it.
        Optional<Instant> onset = SERVICE.detectOnset(declineGrid(), NOW, p);
        assertThat(onset).contains(hoursAgo(2));
        WindowEstimate w = SERVICE.estimateWindow(NOW, onset, false, null, p);
        assertWindow(w, NOW, hoursLater(28), false);
        assertThat(hoursLater(12)).isBetween(w.start(), w.end());
    }

    @Test
    void estimateWindow_activityPath_whenNoOnset() {
        // [now + 2h, now + 16h], midpoint now + 9h
        WindowEstimate w = SERVICE.estimateWindow(NOW, Optional.empty(), true, null, defaults());
        assertWindow(w, hoursLater(2), hoursLater(16), false);
        assertThat(w.midpoint()).isEqualTo(hoursLater(9));
    }

    @Test
    void estimateWindow_noOnsetNoActivity_returnsEmptyWindow() {
        CalvingPredictionProperties p = defaults();
        WindowEstimate w = SERVICE.estimateWindow(NOW, Optional.empty(), false, null, p);
        assertWindow(w, null, null, false);
        assertThat(w.isEstimated()).isFalse();
        assertThat(w.midpoint()).isNull();
        // a known gestation alone cannot conjure a window
        assertWindow(SERVICE.estimateWindow(NOW, Optional.empty(), false, 280, p), null, null, false);
    }

    @Test
    void estimateWindow_priorWindowIntersectsSignsWindow() {
        CalvingPredictionProperties p = defaults();
        // prior window = [now + (283 - 3 - g) × 24h, now + (283 + 7 - g) × 24h]
        Optional<Instant> onset = Optional.of(hoursAgo(2)); // signs [now, now + 28h]
        // g = 280: prior [now, now + 240h] holds the signs window -> unchanged
        assertWindow(SERVICE.estimateWindow(NOW, onset, false, 280, p), NOW, hoursLater(28), false);
        // g = 279: prior starts at now + 24h -> start clipped
        assertWindow(SERVICE.estimateWindow(NOW, onset, false, 279, p), hoursLater(24), hoursLater(28), false);
        // g = 289: prior [now - 216h, now + 24h] -> end clipped
        assertWindow(SERVICE.estimateWindow(NOW, onset, false, 289, p), NOW, hoursLater(24), false);
        // onset 10h ago -> signs [now - 8h, now + 20h]; g = 280 prior starts at now -> [now, now + 20h]
        assertWindow(SERVICE.estimateWindow(NOW, Optional.of(hoursAgo(10)), false, 280, p),
                NOW, hoursLater(20), false);

        // gestationWindowBeforeDays is consumed: 2 instead of 3 moves the g = 280 prior start to now + 24h
        CalvingPredictionProperties narrower = defaults();
        narrower.setGestationWindowBeforeDays(2);
        assertWindow(SERVICE.estimateWindow(NOW, onset, false, 280, narrower),
                hoursLater(24), hoursLater(28), false);
    }

    @Test
    void estimateWindow_priorWindowBeforeSigns_keepsSignsWindowAndFlagsConflict() {
        CalvingPredictionProperties p = defaults();
        // g = 291: prior [now - 264h, now - 24h] ends before the activity signs window [now + 2h, now + 16h]
        assertWindow(SERVICE.estimateWindow(NOW, Optional.empty(), true, 291, p),
                hoursLater(2), hoursLater(16), true);
        // onset 50h ago -> signs [now - 48h, now - 20h] end before the g = 280 prior starts (now)
        assertWindow(SERVICE.estimateWindow(NOW, Optional.of(hoursAgo(50)), false, 280, p),
                hoursAgo(48), hoursAgo(20), true);
    }

    @Test
    void estimateWindow_priorWindowEntirelyLaterThanSigns_keepsSignsWindowAndFlagsConflict() {
        CalvingPredictionProperties p = defaults();
        // g = 250: due in 33 days -> prior [now + 720h, now + 960h], after any signs window
        assertWindow(SERVICE.estimateWindow(NOW, Optional.of(hoursAgo(6)), false, 250, p),
                hoursAgo(4), hoursLater(24), true);
        assertWindow(SERVICE.estimateWindow(NOW, Optional.empty(), true, 250, p),
                hoursLater(2), hoursLater(16), true);
    }

    @Test
    void estimateWindow_withoutGestationOrWithPriorOff_returnsSignsWindowUnclipped() {
        CalvingPredictionProperties p = defaults();
        // no gestation: returned as is, even when it starts before now (no clip to now)
        assertWindow(SERVICE.estimateWindow(NOW, Optional.of(hoursAgo(30)), false, null, p),
                hoursAgo(28), NOW, false);
        // prior off: g = 250 would conflict, but is ignored
        p.setUseBreedingPrior(false);
        assertWindow(SERVICE.estimateWindow(NOW, Optional.of(hoursAgo(6)), false, 250, p),
                hoursAgo(4), hoursLater(24), false);
    }

    // ------------------------------------------------------------ helpers

    private static CalvingPredictionProperties defaults() {
        return new CalvingPredictionProperties();
    }

    private static BigDecimal bd(String value) {
        return new BigDecimal(value);
    }

    private static Instant hoursAgo(double hours) {
        return NOW.minusSeconds(Math.round(hours * 3600));
    }

    private static Instant hoursLater(double hours) {
        return NOW.plusSeconds(Math.round(hours * 3600));
    }

    /** {@code count} temperature samples every 30 minutes from {@code fromHoursAgo} on. */
    private static List<TempSample> tempSeries(double fromHoursAgo, int count, String celsius) {
        List<TempSample> out = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            out.add(new TempSample(hoursAgo(fromHoursAgo).plus(STEP.multipliedBy(i)), bd(celsius)));
        }
        return out;
    }

    /** {@code count} activity samples every 30 minutes from {@code fromHoursAgo} on. */
    private static List<ActivitySample> actSeries(double fromHoursAgo, int count, String index) {
        List<ActivitySample> out = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            out.add(new ActivitySample(hoursAgo(fromHoursAgo).plus(STEP.multipliedBy(i)), bd(index)));
        }
        return out;
    }

    /** Four contiguous 3h blocks of 6 samples each over [now - 12h, now). */
    private static List<TempSample> reboundSeries(String first, String second, String third, String latest) {
        return concat(tempSeries(12, 6, first), tempSeries(9, 6, second),
                tempSeries(6, 6, third), tempSeries(3, 6, latest));
    }

    /** One sample every 30 minutes over [now - 60h, now): grid index j = 120 ... 1, sample at now - j × 30min. */
    private static List<TempSample> grid(IntFunction<BigDecimal> valueAt) {
        List<TempSample> out = new ArrayList<>();
        for (int j = 120; j >= 1; j--) {
            out.add(new TempSample(NOW.minus(STEP.multipliedBy(j)), valueAt.apply(j)));
        }
        return out;
    }

    /** Flat BASE, then a linear decline of 0.004 °C per 30-min step from now - 24h (j = 48). */
    /** 24h-periodic square wave phase-locked to NOW: the 48 half-hour slots split into
     *  24 high ({@code BASE + amplitude}) and 24 low ({@code BASE - amplitude}). */
    private static BigDecimal circadian(double hoursAgo, String amplitude) {
        long slot = Math.round(hoursAgo * 2) % 48;
        return slot < 24 ? BASE.add(bd(amplitude)) : BASE.subtract(bd(amplitude));
    }

    private static List<TempSample> declineGrid() {
        return grid(j -> j >= 48 ? BASE : BASE.subtract(bd("0.004").multiply(BigDecimal.valueOf(48 - j))));
    }

    @SafeVarargs
    private static <T> List<T> concat(List<T>... parts) {
        List<T> out = new ArrayList<>();
        for (List<T> part : parts) {
            out.addAll(part);
        }
        return out;
    }

    private static void assertWindow(WindowEstimate w, Instant start, Instant end, boolean priorConflict) {
        assertThat(w.start()).isEqualTo(start);
        assertThat(w.end()).isEqualTo(end);
        assertThat(w.priorConflict()).isEqualTo(priorConflict);
    }
}
