package com.smartlivestock.health.infrastructure.config;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.within;

/**
 * Fail-fast rules of {@link CalvingPredictionProperties#validate()} (NIX-381
 * Task 2). The defaults must always pass: validate() runs at bean init, so a
 * rejected default would stop every application context from starting.
 * Pure construction, no Spring context.
 */
class CalvingPredictionPropertiesTest {

    @Test
    void defaults_matchPlan7dWorkingPointAndPassValidation() {
        CalvingPredictionProperties p = new CalvingPredictionProperties();
        assertThatCode(p::validate).doesNotThrowAnyException();

        assertThat(p.isEnabled()).isTrue();
        assertThat(p.getPollMs()).isEqualTo(3_600_000L);
        assertThat(p.getActiveWindowMinutes()).isEqualTo(1440);
        assertThat(p.getMaxPerPoll()).isEqualTo(200);
        assertThat(p.getRefWindowOffsetHours()).containsExactly(24L, 48L);
        assertThat(p.getRefActivityWindowOffsetHours()).containsExactly(24L, 48L);
        assertThat(p.getTempDropHighCelsius()).isEqualByComparingTo("0.30");
        assertThat(p.getActivityRatioLow()).isEqualByComparingTo("1.15");
        assertThat(p.getWeightTempDrop() + p.getWeightActivity() + p.getWeightPrior())
                .isCloseTo(1.0, within(1e-9));
        // plan 7d working point (seed 20261105, run 31): 24h window, activity-heavier
        // weights, rebound off (32.5% non-prepartum hit rate measured)
        assertThat(p.getCurrentTempWindowHours()).isEqualTo(24L);
        assertThat(p.getWeightTempDrop()).isEqualTo(0.35);
        assertThat(p.getWeightActivity()).isEqualTo(0.45);
        assertThat(p.getWeightPrior()).isEqualTo(0.20);
        assertThat(p.isReboundDetectionEnabled()).isFalse();
        assertThat(p.getMinPlausibleTempCelsius()).isEqualByComparingTo("35.0");
        assertThat(p.getMaxPlausibleTempCelsius()).isEqualByComparingTo("43.0");
        assertThat(p.getPersistThreshold()).isEqualTo(50);
        assertThat(p.getAlertThreshold()).isEqualTo(70);
        assertThat(p.getReleaseThreshold()).isEqualTo(55);
        // review 2c: no-temperature cap below the alert line; onset window counted from detection
        assertThat(p.getSingleChannelCapNoTemp()).isEqualTo(60);
        assertThat(p.getOnsetWindowStartHours()).isEqualTo(2L);
        assertThat(p.getOnsetWindowEndHours()).isEqualTo(30L);
        // review 2d: stale-window lag + orchestration tunables shared with Task 3/4
        assertThat(p.getStaleWindowMaxLagHours()).isEqualTo(24);
        assertThat(p.getDrinkingExclusionBufferMinutes()).isEqualTo(120);
        assertThat(p.getAlertPersistencePoints()).isEqualTo(2);
    }

    @Test
    void validate_rejectsNonMonotonicLadders() {
        CalvingPredictionProperties temp = new CalvingPredictionProperties();
        temp.setTempDropMidCelsius(new BigDecimal("0.30"));   // mid == high
        assertThatThrownBy(temp::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("temp-drop ladder");

        CalvingPredictionProperties activity = new CalvingPredictionProperties();
        activity.setActivityRatioLow(BigDecimal.ONE);          // "no change" must never score
        assertThatThrownBy(activity::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("activity-ratio ladder");
    }

    @Test
    void validate_rejectsNegativeWeight() {
        CalvingPredictionProperties p = new CalvingPredictionProperties();
        p.setWeightPrior(-0.1);
        assertThatThrownBy(p::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("weights");
    }

    @Test
    void validate_rejectsBadStaleLagBufferAndPersistence() {
        CalvingPredictionProperties lagZero = new CalvingPredictionProperties();
        lagZero.setStaleWindowMaxLagHours(0);
        assertThatThrownBy(lagZero::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("stale-window-max-lag-hours");
        CalvingPredictionProperties lagTooLong = new CalvingPredictionProperties();
        lagTooLong.setStaleWindowMaxLagHours(49);
        assertThatThrownBy(lagTooLong::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("stale-window-max-lag-hours");
        CalvingPredictionProperties lagAtMax = new CalvingPredictionProperties();
        lagAtMax.setStaleWindowMaxLagHours(48);
        assertThatCode(lagAtMax::validate).doesNotThrowAnyException();

        CalvingPredictionProperties negativeBuffer = new CalvingPredictionProperties();
        negativeBuffer.setDrinkingExclusionBufferMinutes(-1);
        assertThatThrownBy(negativeBuffer::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("drinking-exclusion-buffer-minutes");
        CalvingPredictionProperties zeroBuffer = new CalvingPredictionProperties();
        zeroBuffer.setDrinkingExclusionBufferMinutes(0);
        assertThatCode(zeroBuffer::validate).doesNotThrowAnyException();

        CalvingPredictionProperties zeroPersistence = new CalvingPredictionProperties();
        zeroPersistence.setAlertPersistencePoints(0);
        assertThatThrownBy(zeroPersistence::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("alert-persistence-points");
    }

    @Test
    void validate_alertPersistencePointsLimitedToOneOrTwo() {
        // >2 used to fall back to 2 silently (single-column prev state) — a
        // configuration trap the plan 7d calibration run stepped into.
        CalvingPredictionProperties three = new CalvingPredictionProperties();
        three.setAlertPersistencePoints(3);
        assertThatThrownBy(three::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("alert-persistence-points")
                .hasMessageContaining("2 is the semantic limit");
        CalvingPredictionProperties one = new CalvingPredictionProperties();
        one.setAlertPersistencePoints(1);
        assertThatCode(one::validate).doesNotThrowAnyException();
        CalvingPredictionProperties two = new CalvingPredictionProperties();
        two.setAlertPersistencePoints(2);
        assertThatCode(two::validate).doesNotThrowAnyException();
    }

    @Test
    void validate_rejectsEmptyOrInvertedPlausibilityBand() {
        CalvingPredictionProperties inverted = new CalvingPredictionProperties();
        inverted.setMinPlausibleTempCelsius(new BigDecimal("43.0"));
        inverted.setMaxPlausibleTempCelsius(new BigDecimal("35.0"));
        assertThatThrownBy(inverted::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("min-plausible-temp-celsius");

        CalvingPredictionProperties equal = new CalvingPredictionProperties();
        equal.setMinPlausibleTempCelsius(new BigDecimal("38.0"));
        equal.setMaxPlausibleTempCelsius(new BigDecimal("38.0"));
        assertThatThrownBy(equal::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("min-plausible-temp-celsius");

        CalvingPredictionProperties narrow = new CalvingPredictionProperties();
        narrow.setMinPlausibleTempCelsius(new BigDecimal("37.0"));
        narrow.setMaxPlausibleTempCelsius(new BigDecimal("39.0"));
        assertThatCode(narrow::validate).doesNotThrowAnyException();
    }

    @Test
    void validate_rejectsSingleChannelCapAtOrAboveAlertThreshold() {
        CalvingPredictionProperties atAlert = new CalvingPredictionProperties();
        atAlert.setSingleChannelCapNoTemp(70);                 // == alert-threshold
        assertThatThrownBy(atAlert::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("single-channel-cap-no-temp");

        CalvingPredictionProperties justBelow = new CalvingPredictionProperties();
        justBelow.setSingleChannelCapNoTemp(69);
        assertThatCode(justBelow::validate).doesNotThrowAnyException();
    }

    @Test
    void validate_rejectsReleaseThresholdNotBelowAlertThreshold() {
        CalvingPredictionProperties p = new CalvingPredictionProperties();
        p.setReleaseThreshold(70);
        assertThatThrownBy(p::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("release-threshold");
    }

    @Test
    void validate_rejectsInvertedOnsetAndActivityWindows() {
        CalvingPredictionProperties onset = new CalvingPredictionProperties();
        onset.setOnsetWindowStartHours(30);                    // start == end
        assertThatThrownBy(onset::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("onset window");

        CalvingPredictionProperties activity = new CalvingPredictionProperties();
        activity.setActivityWindowStartHours(20);              // start > end 16
        assertThatThrownBy(activity::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("activity window");
    }

    @Test
    void validate_rejectsReferenceOffsetsBreakingSamePhase() {
        CalvingPredictionProperties offPhase = new CalvingPredictionProperties();
        offPhase.setRefWindowOffsetHours(List.of(24L, 36L));
        assertThatThrownBy(offPhase::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("ref-window-offset-hours");

        CalvingPredictionProperties empty = new CalvingPredictionProperties();
        empty.setRefActivityWindowOffsetHours(List.of());
        assertThatThrownBy(empty::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("ref-activity-window-offset-hours");
    }

    @Test
    void validate_rejectsReboundLookbackWithoutThreeWholeBlocks() {
        CalvingPredictionProperties twoBlocks = new CalvingPredictionProperties();
        twoBlocks.setReboundLookbackHours(6);
        assertThatThrownBy(twoBlocks::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("rebound-lookback-hours");

        CalvingPredictionProperties ragged = new CalvingPredictionProperties();
        ragged.setReboundLookbackHours(10);
        assertThatThrownBy(ragged::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("rebound-lookback-hours");
    }

    @Test
    void validate_rejectsPriorBandsOutOfOrder() {
        CalvingPredictionProperties p = new CalvingPredictionProperties();
        p.setPriorSuppressBelowDays(275);                      // above prior-normal-min-days 270
        assertThatThrownBy(p::validate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("prior bands");
    }
}
