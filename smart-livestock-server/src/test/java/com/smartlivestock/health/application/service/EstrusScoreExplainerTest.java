package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.service.EstrusScoreExplainer.EstrusScoreExplanation;
import com.smartlivestock.health.domain.model.EstrusScore;
import com.smartlivestock.health.domain.service.EstrusAnalysisService;
import com.smartlivestock.health.domain.service.EstrusAnalysisService.ComponentBreakdown;
import com.smartlivestock.health.infrastructure.config.EstrusScoringProperties;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

/**
 * Unit tests for the estrus score explainer (NIX-390 Task 1): dispatch on
 * featureVersion and exact recomputation of the component breakdowns.
 * Pure construction, no mocks, no Spring context (same style as
 * {@code EstrusAnalysisServiceTest}). The default {@link EstrusScoringProperties}
 * ladders equal {@code EstrusAnalysisService.DEFAULT_LADDER} (3.0/100, 2.0/100,
 * 1.5/45).
 */
class EstrusScoreExplainerTest {

    /** The real scoring kernels — each case cross-checks that the breakdown's
     *  implied score equals what the kernel actually scored on the same inputs. */
    private static final EstrusAnalysisService KERNEL = new EstrusAnalysisService();

    private final EstrusScoreExplainer explainer = new EstrusScoreExplainer(
            KERNEL, new EstrusScoringProperties());

    // ── 1. LEGACY known case: the dev-measured row recomputed by hand ──

    @Test
    void legacy_knownRow_breakdownAndWeightedSumRecompute() {
        // Hand computation against the legacy curves:
        //   step 88:      20 + (88-50)/100*40        = 35.2
        //   temp 0.18:    0.18/0.2*10                = 9.0
        //   dist 40.30m:  40.30/500*15               = 1.209
        //   weighted sum: 35.2*0.4 + 9*0.3 + 1.209*0.3 = 14.08+2.7+0.3627 = 17.1427
        //   score:        round(17.1427) = 17  (dev-measured anchor row)
        EstrusScore row = legacyRow(88, "0.18", "40.30");

        EstrusScoreExplanation explanation = explainer.explain(row);

        assertThat(explanation).isNotNull();
        ComponentBreakdown b = explanation.breakdown();
        assertThat(b.activityScore()).isCloseTo(35.2, within(1e-6));
        assertThat(b.temperatureScore()).isCloseTo(9.0, within(1e-6));
        assertThat(b.distanceScore()).isCloseTo(1.209, within(1e-6));
        assertThat(b.weightActivity()).isCloseTo(0.4, within(1e-9));
        assertThat(b.weightTemperature()).isCloseTo(0.3, within(1e-9));
        assertThat(b.weightDistance()).isCloseTo(0.3, within(1e-9));
        assertThat(roundedScore(b)).isEqualTo(17);
        assertThat(KERNEL.calculateScore(88, bd("0.18"), bd("40.30"))).isEqualTo(17);
        // LEGACY rows carry no level ratios for display.
        assertThat(explanation.activityRatio()).isNull();
        assertThat(explanation.distanceRatio()).isNull();
        assertThat(explanation.distanceParticipated()).isTrue();
        assertThat(explanation.temperatureParticipated()).isTrue();
    }

    // ── 2. LEGACY null temp/distance: components 0, weights unchanged ──

    @Test
    void legacy_nullTempAndDistance_componentsZeroWeightsKept() {
        // calculateScore semantics: a null input scores 0 through its curve but
        // keeps its weight — the total is carried by activity alone (here
        // step 400 -> 100 top band: round(100*0.4) = 40).
        EstrusScore row = legacyRow(400, null, null);

        EstrusScoreExplanation explanation = explainer.explain(row);

        assertThat(explanation).isNotNull();
        ComponentBreakdown b = explanation.breakdown();
        assertThat(b.activityScore()).isCloseTo(100.0, within(1e-6));
        assertThat(b.temperatureScore()).isZero();
        assertThat(b.distanceScore()).isZero();
        assertThat(b.weightActivity()).isCloseTo(0.4, within(1e-9));
        assertThat(b.weightTemperature()).isCloseTo(0.3, within(1e-9));
        assertThat(b.weightDistance()).isCloseTo(0.3, within(1e-9));
        assertThat(roundedScore(b)).isEqualTo(40);
        assertThat(KERNEL.calculateScore(400, null, null)).isEqualTo(40);
        assertThat(explanation.distanceParticipated()).isFalse();
        assertThat(explanation.temperatureParticipated()).isFalse();
    }

    // ── 3. NORMALIZED known case A: negative temp clamped, distance absent ──

    @Test
    void normalized_negativeTempClamped_distanceAbsent_weightsRenormalized() {
        // Hand computation:
        //   step 200 -> ratio 3.0 -> very-high rung -> activity 100
        //   temp -0.48 -> curve -24, clamped to 0 (0b74fab2 semantics)
        //   distanceRatio null -> component absent (weight 0)
        //   participating weight sum 0.4+0.3 = 0.7 -> weights 4/7 and 3/7
        //   weighted sum: 100*4/7 + 0*3/7 = 57.142857 -> round = 57
        EstrusScore row = normalizedRow(200, "-0.48", null);

        EstrusScoreExplanation explanation = explainer.explain(row);

        assertThat(explanation).isNotNull();
        ComponentBreakdown b = explanation.breakdown();
        assertThat(b.activityScore()).isCloseTo(100.0, within(1e-6));
        assertThat(b.temperatureScore()).isZero();
        assertThat(b.distanceScore()).isZero();
        assertThat(b.weightActivity()).isCloseTo(4.0 / 7.0, within(1e-9));
        assertThat(b.weightTemperature()).isCloseTo(3.0 / 7.0, within(1e-9));
        assertThat(b.weightDistance()).isZero();
        assertThat(roundedScore(b)).isEqualTo(57);
        assertThat(KERNEL.calculateScoreNormalized(bd("3.0"), bd("-0.48"), null,
                EstrusAnalysisService.DEFAULT_LADDER, EstrusAnalysisService.DEFAULT_LADDER)).isEqualTo(57);
        assertThat(explanation.activityRatio()).isEqualByComparingTo("3.00");
        assertThat(explanation.distanceRatio()).isNull();
        assertThat(explanation.distanceParticipated()).isFalse();
        assertThat(explanation.temperatureParticipated()).isTrue();
    }

    // ── 4. NORMALIZED known case B: all three components present ──

    @Test
    void normalized_allComponentsPresent_fullWeights() {
        // Hand computation:
        //   step 200 -> ratio 3.0 -> activity 100
        //   temp 0.55 -> 42 (0.55 in the (0.5,1.0] band: 40 + 0.05/0.5*20 = 42)
        //   distanceRatio 3.0 -> very-high rung -> 100
        //   weights stay 0.4/0.3/0.3 (all participated)
        //   weighted sum: 40 + 12.6 + 30 = 82.6 -> round = 83
        EstrusScore row = normalizedRow(200, "0.55", "3.000");

        EstrusScoreExplanation explanation = explainer.explain(row);

        assertThat(explanation).isNotNull();
        ComponentBreakdown b = explanation.breakdown();
        assertThat(b.activityScore()).isCloseTo(100.0, within(1e-6));
        assertThat(b.temperatureScore()).isCloseTo(42.0, within(1e-6));
        assertThat(b.distanceScore()).isCloseTo(100.0, within(1e-6));
        assertThat(b.weightActivity()).isCloseTo(0.4, within(1e-9));
        assertThat(b.weightTemperature()).isCloseTo(0.3, within(1e-9));
        assertThat(b.weightDistance()).isCloseTo(0.3, within(1e-9));
        assertThat(roundedScore(b)).isEqualTo(83);
        assertThat(KERNEL.calculateScoreNormalized(bd("3.0"), bd("0.55"), bd("3.000"),
                EstrusAnalysisService.DEFAULT_LADDER, EstrusAnalysisService.DEFAULT_LADDER)).isEqualTo(83);
        assertThat(explanation.activityRatio()).isEqualByComparingTo("3.00");
        assertThat(explanation.distanceRatio()).isEqualByComparingTo("3.000");
        assertThat(explanation.distanceParticipated()).isTrue();
        assertThat(explanation.temperatureParticipated()).isTrue();
    }

    // ── 5. Unknown / missing featureVersion -> no explanation ──

    @Test
    void nullFeatureVersion_returnsNull() {
        assertThat(explainer.explain(legacyRow(88, "0.18", "40.30"))).isNotNull(); // sanity
        assertThat(explainer.explain(rowWithoutFeatureVersion())).isNull();
    }

    // ── helpers ────────────────────────────────────────────────

    private static BigDecimal bd(String value) {
        return new BigDecimal(value);
    }

    private static EstrusScore legacyRow(Integer step, String tempDelta, String distanceDelta) {
        EstrusScore row = new EstrusScore();
        row.setFeatureVersion("LEGACY");
        row.setStepIncreasePercent(step);
        row.setTempDelta(tempDelta == null ? null : new BigDecimal(tempDelta));
        row.setDistanceDelta(distanceDelta == null ? null : new BigDecimal(distanceDelta));
        return row;
    }

    private static EstrusScore normalizedRow(Integer step, String tempDelta, String distanceRatio) {
        EstrusScore row = new EstrusScore();
        row.setFeatureVersion("NORMALIZED-V2");
        row.setStepIncreasePercent(step);
        row.setTempDelta(tempDelta == null ? null : new BigDecimal(tempDelta));
        row.setDistanceRatio(distanceRatio == null ? null : new BigDecimal(distanceRatio));
        return row;
    }

    /** A pre-NIX-390 row: featureVersion never stamped. */
    private static EstrusScore rowWithoutFeatureVersion() {
        EstrusScore row = new EstrusScore();
        row.setStepIncreasePercent(88);
        row.setTempDelta(new BigDecimal("0.18"));
        row.setDistanceDelta(new BigDecimal("40.30"));
        return row;
    }

    /** Score implied by a breakdown, computed exactly like the two kernels:
     *  clamp the weighted sum to [0,100] then round half-up. */
    private static long roundedScore(ComponentBreakdown b) {
        double raw = b.activityScore() * b.weightActivity()
                + b.temperatureScore() * b.weightTemperature()
                + b.distanceScore() * b.weightDistance();
        return Math.round(Math.max(0, Math.min(100, raw)));
    }
}
