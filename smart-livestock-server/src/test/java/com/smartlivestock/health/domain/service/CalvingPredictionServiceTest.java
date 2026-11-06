package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.domain.service.CalvingPredictionService.ActivitySample;
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

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for the calving-risk kernel (NIX-381 Task 2). Pure construction,
 * no mocks, no Spring context.
 *
 * <p>Hand-computed expectations use the default properties: temperature
 * ladder 0.30 / 0.20 / 0.12 °C → 100 / 70 / 45, activity ladder
 * 1.5 / 1.3 / 1.15 → 100 / 70 / 45, weights 0.45 / 0.35 / 0.20, prior bands
 * [270, 293] normal and &lt; 250 suppressed (×0.5), rebound bonus +10.
 * Series are 30-minute grids anchored on a fixed {@code NOW}.</p>
 */
class CalvingPredictionServiceTest {

    private static final CalvingPredictionService SERVICE = new CalvingPredictionService();
    private static final Instant NOW = Instant.parse("2026-11-06T12:00:00Z");
    private static final Duration STEP = Duration.ofMinutes(30);

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
        // null: temperature drops out, activity 1.5 -> 100 carries alone -> 100
        assertThat(SERVICE.score(null, bd("1.5"), null, false, p)).isEqualTo(100);
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

    // ------------------------------------------------------------ onset

    @Test
    void detectOnset_twoConsecutiveDropPairs_returnsTimeOfFirstPair() {
        // pairs: 0.00 x | 0.18 ok | 0.15 ok (inclusive) -> run of 2 starting at 4.5h ago.
        // A later run (0.27, 0.20) exists; the first run wins. Were 0.15 exclusive,
        // the first run would break and the answer would be 3.0h ago instead.
        assertThat(SERVICE.detectOnset(onsetSeries(), NOW, defaults())).contains(hoursAgo(4.5));
    }

    @Test
    void detectOnset_isolatedSingleDropPairs_doNotTrigger() {
        List<TempSample> samples = List.of(
                new TempSample(hoursAgo(5.0), bd("38.80")),
                new TempSample(hoursAgo(4.5), bd("38.60")),   // 0.20 ok
                new TempSample(hoursAgo(4.0), bd("38.58")),   // 0.02 breaks the run
                new TempSample(hoursAgo(3.5), bd("38.58")),
                new TempSample(hoursAgo(3.0), bd("38.40")),   // 0.18 ok
                new TempSample(hoursAgo(2.5), bd("38.40")),   // 0.00 breaks the run
                new TempSample(hoursAgo(2.0), bd("38.41")));
        assertThat(SERVICE.detectOnset(samples, NOW, defaults())).isEmpty();
    }

    @Test
    void detectOnset_noDecline_returnsEmpty() {
        CalvingPredictionProperties p = defaults();
        assertThat(SERVICE.detectOnset(tempSeries(5, 10, "38.60"), NOW, p)).isEmpty();
        List<TempSample> rising = new ArrayList<>();
        for (int i = 0; i < 10; i++) {
            rising.add(new TempSample(hoursAgo(5).plus(STEP.multipliedBy(i)),
                    bd("38.00").add(bd("0.20").multiply(BigDecimal.valueOf(i)))));
        }
        assertThat(SERVICE.detectOnset(rising, NOW, p)).isEmpty();
        assertThat(SERVICE.detectOnset(List.of(), NOW, p)).isEmpty();
        assertThat(SERVICE.detectOnset(null, NOW, p)).isEmpty();
    }

    @Test
    void detectOnset_ignoresInputOrderAndSamplesAtOrAfterNow() {
        CalvingPredictionProperties p = defaults();
        List<TempSample> shuffled = new ArrayList<>(onsetSeries());
        Collections.shuffle(shuffled, new Random(20261106L));
        assertThat(SERVICE.detectOnset(shuffled, NOW, p)).contains(hoursAgo(4.5));

        // the only qualifying run needs the samples at now and after now -> no look-ahead
        List<TempSample> future = List.of(
                new TempSample(hoursAgo(1.0), bd("38.60")),
                new TempSample(hoursAgo(0.5), bd("38.60")),
                new TempSample(NOW, bd("38.40")),
                new TempSample(hoursLater(0.5), bd("38.20")));
        assertThat(SERVICE.detectOnset(future, NOW, p)).isEmpty();
    }

    // ------------------------------------------------------------ window estimate

    @Test
    void estimateWindow_onsetPath_offsetsFromOnsetAndWinsOverActivity() {
        CalvingPredictionProperties p = defaults();
        Optional<Instant> onset = Optional.of(hoursAgo(6));

        // [onset + 24h, onset + 48h] = [now + 18h, now + 42h], midpoint now + 30h
        WindowEstimate w = SERVICE.estimateWindow(NOW, onset, false, null, p);
        assertWindow(w, hoursLater(18), hoursLater(42), false);
        assertThat(w.midpoint()).isEqualTo(hoursLater(30));
        // an activity rise does not override the onset path
        assertWindow(SERVICE.estimateWindow(NOW, onset, true, null, p), hoursLater(18), hoursLater(42), false);
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
    void estimateWindow_priorClipsSignsWindowToNowAndHorizon() {
        CalvingPredictionProperties p = defaults();
        // onset 30h ago -> signs [now - 6h, now + 18h]; prior known -> start clipped to now
        Optional<Instant> onset = Optional.of(hoursAgo(30));
        assertWindow(SERVICE.estimateWindow(NOW, onset, false, 280, p), NOW, hoursLater(18), false);
        // no gestation -> unclipped signs window
        assertWindow(SERVICE.estimateWindow(NOW, onset, false, null, p), hoursAgo(6), hoursLater(18), false);
        // prior switched off -> unclipped as well
        p.setUseBreedingPrior(false);
        assertWindow(SERVICE.estimateWindow(NOW, onset, false, 280, p), hoursAgo(6), hoursLater(18), false);

        // horizon side: after-days 1 -> horizon now + 24h; onset 1h ago -> signs
        // [now + 23h, now + 47h] -> clipped end -> [now + 23h, now + 24h]
        CalvingPredictionProperties shortHorizon = defaults();
        shortHorizon.setGestationWindowAfterDays(1);
        assertWindow(SERVICE.estimateWindow(NOW, Optional.of(hoursAgo(1)), false, 280, shortHorizon),
                hoursLater(23), hoursLater(24), false);
    }

    @Test
    void estimateWindow_priorContradiction_keepsSignsWindowAndFlagsConflict() {
        // onset 50h ago -> signs [now - 26h, now - 2h]; clip [now, now - 2h] is empty
        assertWindow(SERVICE.estimateWindow(NOW, Optional.of(hoursAgo(50)), false, 280, defaults()),
                hoursAgo(26), hoursAgo(2), true);

        // after-days 0 -> horizon = now; activity signs [now + 2h, now + 16h] lie
        // entirely beyond it -> empty clip -> signs window kept and flagged
        CalvingPredictionProperties zeroHorizon = defaults();
        zeroHorizon.setGestationWindowAfterDays(0);
        assertWindow(SERVICE.estimateWindow(NOW, Optional.empty(), true, 280, zeroHorizon),
                hoursLater(2), hoursLater(16), true);
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

    private static List<TempSample> onsetSeries() {
        return List.of(
                new TempSample(hoursAgo(5.0), bd("38.80")),
                new TempSample(hoursAgo(4.5), bd("38.80")),
                new TempSample(hoursAgo(4.0), bd("38.62")),
                new TempSample(hoursAgo(3.5), bd("38.47")),
                new TempSample(hoursAgo(3.0), bd("38.47")),
                new TempSample(hoursAgo(2.5), bd("38.20")),
                new TempSample(hoursAgo(2.0), bd("38.00")));
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
