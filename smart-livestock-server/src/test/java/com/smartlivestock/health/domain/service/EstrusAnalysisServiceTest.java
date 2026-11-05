package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.domain.service.EstrusAnalysisService.EstrusFeatureLadder;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

/**
 * Unit tests for the normalized estrus scoring kernel (NIX-380 Task 1) plus
 * behavior-lock regression cases for the legacy
 * {@link EstrusAnalysisService#calculateScore(int, BigDecimal, BigDecimal)}.
 * Pure construction, no mocks, no Spring context.
 *
 * <p>Hand-computed expectations use the legacy temperature curve
 * ({@code scoreTempDelta}: 0.55 °C → 42) and the default ladder rungs
 * (1.5 → 45, 2.0 → 95, 3.0 → 100) with weights 0.4 / 0.3 / 0.3 normalized
 * over the available components only.</p>
 */
class EstrusAnalysisServiceTest {

    private static final EstrusAnalysisService SERVICE = new EstrusAnalysisService();

    private static final EstrusFeatureLadder DEFAULT = EstrusAnalysisService.DEFAULT_LADDER;
    /** Custom ladder with shifted rungs (4.0/90, 2.5/60, 1.8/30) to prove the ladder is caller-controlled. */
    private static final EstrusFeatureLadder CUSTOM = new EstrusFeatureLadder(4.0, 90, 2.5, 60, 1.8, 30);

    // ------------------------------------------------------------- ladder boundaries

    @Test
    void ladderScore_mapsDefaultLadderBoundaries() {
        // Below 1.0: no rise vs baseline.
        assertThat(EstrusAnalysisService.ladderScore(0.99, DEFAULT)).isZero();
        // Linear band [1.0, 1.5): 45 * (r - 1.0) / 0.5; at 1.0 the interpolation starts at 0.
        assertThat(EstrusAnalysisService.ladderScore(1.0, DEFAULT)).isZero();
        assertThat(EstrusAnalysisService.ladderScore(1.49, DEFAULT)).isCloseTo(44.1, within(1e-6));
        // Mid rung [1.5, 2.0) -> 45.
        assertThat(EstrusAnalysisService.ladderScore(1.5, DEFAULT)).isEqualTo(45.0);
        assertThat(EstrusAnalysisService.ladderScore(1.99, DEFAULT)).isEqualTo(45.0);
        // High rung [2.0, 3.0) -> 100 (scored 95 before the NIX-380 forensics fix;
        // a sustained >=2x same-phase rise is a maximal standing-heat signal).
        assertThat(EstrusAnalysisService.ladderScore(2.0, DEFAULT)).isEqualTo(100.0);
        assertThat(EstrusAnalysisService.ladderScore(2.99, DEFAULT)).isEqualTo(100.0);
        // Very-high rung [3.0, inf) -> 100, saturating above it.
        assertThat(EstrusAnalysisService.ladderScore(3.0, DEFAULT)).isEqualTo(100.0);
        assertThat(EstrusAnalysisService.ladderScore(3.5, DEFAULT)).isEqualTo(100.0);
    }

    @Test
    void ladderScore_honorsCustomLadder() {
        assertThat(EstrusAnalysisService.ladderScore(4.0, CUSTOM)).isEqualTo(90.0);
        assertThat(EstrusAnalysisService.ladderScore(2.5, CUSTOM)).isEqualTo(60.0);
        assertThat(EstrusAnalysisService.ladderScore(1.8, CUSTOM)).isEqualTo(30.0);
        // Linear band: 30 * (1.7 - 1.0) / (1.8 - 1.0) = 30 * 0.875 = 26.25.
        assertThat(EstrusAnalysisService.ladderScore(1.7, CUSTOM)).isCloseTo(26.25, within(1e-6));
        assertThat(EstrusAnalysisService.ladderScore(0.99, CUSTOM)).isZero();
    }

    // ------------------------------------------------------- weight normalization

    @Test
    void normalized_activityPlusTemp_weightsNormalizeOverAvailableComponents() {
        // activity 1.5 -> 45 (mid rung), temp 0.2 -> 10 (legacy curve), distance unavailable.
        // raw = (45*0.4 + 10*0.3) / 0.7 = 21 / 0.7 = 30
        assertThat(SERVICE.calculateScoreNormalized(bd("1.5"), bd("0.2"), null, DEFAULT, DEFAULT))
                .isEqualTo(30);
    }

    @Test
    void normalized_activityPlusDistance_weightsNormalizeOverAvailableComponents() {
        // activity 1.5 -> 45, distance 1.5 -> 45, temp unavailable.
        // raw = (45*0.4 + 45*0.3) / 0.7 = 31.5 / 0.7 = 45
        assertThat(SERVICE.calculateScoreNormalized(bd("1.5"), null, bd("1.5"), DEFAULT, DEFAULT))
                .isEqualTo(45);
    }

    @Test
    void normalized_allThreeComponents_fullWeightSum() {
        // activity 3.0 -> 100 (very-high rung), temp 0.55 -> 42, distance 2.0 -> 100
        // (high rung scored 100 since the NIX-380 forensics fix).
        // raw = 100*0.4 + 42*0.3 + 100*0.3 = 40 + 12.6 + 30 = 82.6 -> 83
        assertThat(SERVICE.calculateScoreNormalized(bd("3.0"), bd("0.55"), bd("2.0"), DEFAULT, DEFAULT))
                .isEqualTo(83);
    }

    @Test
    void normalized_negativeTempDelta_floorsAtZero_notNegativeEvidence() {
        // NIX-380 forensics regression lock: the legacy curve returns
        // d/0.2*10 unbounded below, so a drinking-valley tempDelta of -2.0
        // scored -100 and dragged whole positions to 0. A cooler-than-baseline
        // reading is NOT evidence against estrus: the component floors at 0
        // while the activity/distance rungs still carry the score.
        // raw = 100*0.4 + 0*0.3 + 100*0.3 = 70
        assertThat(SERVICE.calculateScoreNormalized(bd("2.5"), bd("-2.0"), bd("2.5"), DEFAULT, DEFAULT))
                .isEqualTo(70);
    }

    @Test
    void normalized_capsuleOnly_activityPlusTempKnownCase() {
        // CAPSULE-only key case: activity ratio 3.0 -> 100, temp delta 0.55 -> 42,
        // distance unavailable (no capsule distance sensor).
        // raw = (100*0.4 + 42*0.3) / 0.7 = 52.6 / 0.7 = 75.14 -> 75
        assertThat(SERVICE.calculateScoreNormalized(bd("3.0"), bd("0.55"), null, DEFAULT, DEFAULT))
                .isEqualTo(75);
    }

    @Test
    void normalized_allNull_returnsZero() {
        assertThat(SERVICE.calculateScoreNormalized(null, null, null, DEFAULT, DEFAULT)).isZero();
    }

    @Test
    void normalized_nullLadderFallsBackToDefault() {
        // Null ladders fall back to DEFAULT_LADDER: identical inputs to the
        // DEFAULT case of normalized_defaultLadderVersusCustomLadder -> same 75.
        assertThat(SERVICE.calculateScoreNormalized(bd("2.5"), bd("0.55"), null, null, null))
                .isEqualTo(75);
    }

    @Test
    void normalized_defaultLadderVersusCustomLadder_sameInputsDifferentScores() {
        // activity 2.5: DEFAULT ladder -> 100 (high rung), CUSTOM ladder -> 60 (high rung).
        // temp 0.55 -> 42 either way; distance unavailable.
        // DEFAULT: (100*0.4 + 42*0.3) / 0.7 = 52.6 / 0.7 = 75.14 -> 75
        assertThat(SERVICE.calculateScoreNormalized(bd("2.5"), bd("0.55"), null, DEFAULT, DEFAULT))
                .isEqualTo(75);
        // CUSTOM: (60*0.4 + 42*0.3) / 0.7 = 36.6 / 0.7 = 52.28 -> 52
        assertThat(SERVICE.calculateScoreNormalized(bd("2.5"), bd("0.55"), null, CUSTOM, CUSTOM))
                .isEqualTo(52);
    }

    // ------------------------------------------------- legacy method regression

    @Test
    void legacy_calculateScore_knownCompositeCase() {
        // step 300 -> 85 (top of 150-300 band), temp 0.55 -> 42,
        // distance 1000 -> 15 + 500/1500*35 = 26.67.
        // raw = 85*0.4 + 42*0.3 + 26.67*0.3 = 34 + 12.6 + 8.0 = 54.6 -> 55
        assertThat(SERVICE.calculateScore(300, bd("0.55"), bd("1000"))).isEqualTo(55);
    }

    @Test
    void legacy_calculateScore_zeroAndNullInputs() {
        assertThat(SERVICE.calculateScore(0, null, null)).isZero();
    }

    @Test
    void legacy_calculateScore_stepOnlyTopBand() {
        // step 400 -> 85 + 15 = 100; temp/distance null score 0.
        // raw = 100*0.4 = 40
        assertThat(SERVICE.calculateScore(400, null, null)).isEqualTo(40);
    }

    private static BigDecimal bd(String value) {
        return new BigDecimal(value);
    }
}
