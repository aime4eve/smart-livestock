package com.smartlivestock.ranch.domain.service;

import com.smartlivestock.ranch.domain.port.HealthQueryPort.LivestockHealthState;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * NIX-198: the derivation rules moved here from RanchOverviewApplicationService
 * so the detail page and the list surfaces speak the same vocabulary as the
 * map markers. Pins the full rule matrix plus the null-snapshot contract.
 */
class HealthStatusDeriverTest {

    private LivestockHealthState state(String tempStatus, String motilityStatus,
            int estrusScore, Integer calvingRiskScore) {
        return new LivestockHealthState(1L, tempStatus, motilityStatus,
                estrusScore, null, null, null, calvingRiskScore);
    }

    @Test
    void nullSnapshotIsNeverAlarming() {
        assertThat(HealthStatusDeriver.deriveHealthStatus(null)).isEqualTo("NORMAL");
        assertThat(HealthStatusDeriver.derivePrimaryAlert(null)).isEmpty();
    }

    @Test
    void criticalTemperatureWinsOverEverything() {
        LivestockHealthState state = state("CRITICAL", "ABNORMAL", 90, 90);
        assertThat(HealthStatusDeriver.deriveHealthStatus(state)).isEqualTo("CRITICAL");
        assertThat(HealthStatusDeriver.derivePrimaryAlert(state)).isEqualTo("FEVER");
    }

    @Test
    void feverAndElevatedAndAbnormalMotilityAreWarnings() {
        assertThat(HealthStatusDeriver.deriveHealthStatus(
                state("FEVER", "NORMAL", 0, null))).isEqualTo("WARNING");
        assertThat(HealthStatusDeriver.deriveHealthStatus(
                state("ELEVATED", "NORMAL", 0, null))).isEqualTo("WARNING");
        assertThat(HealthStatusDeriver.deriveHealthStatus(
                state("NORMAL", "ABNORMAL", 0, null))).isEqualTo("WARNING");
        assertThat(HealthStatusDeriver.derivePrimaryAlert(
                state("NORMAL", "ABNORMAL", 0, null))).isEqualTo("DIGESTIVE");
    }

    @Test
    void estrusScoreAtOrAbove70IsWarning() {
        assertThat(HealthStatusDeriver.deriveHealthStatus(
                state("NORMAL", "NORMAL", 70, null))).isEqualTo("WARNING");
        assertThat(HealthStatusDeriver.deriveHealthStatus(
                state("NORMAL", "NORMAL", 69, null))).isEqualTo("NORMAL");
        assertThat(HealthStatusDeriver.derivePrimaryAlert(
                state("NORMAL", "NORMAL", 70, null))).isEqualTo("ESTRUS");
    }

    @Test
    void calvingRiskAtOrAboveThresholdIsWarning() {
        assertThat(HealthStatusDeriver.deriveHealthStatus(
                state("NORMAL", "NORMAL", 0, 70))).isEqualTo("WARNING");
        assertThat(HealthStatusDeriver.deriveHealthStatus(
                state("NORMAL", "NORMAL", 0, 69))).isEqualTo("NORMAL");
        // null score = never scored / released (NIX-381) — not alarming.
        assertThat(HealthStatusDeriver.deriveHealthStatus(
                state("NORMAL", "NORMAL", 0, null))).isEqualTo("NORMAL");
        assertThat(HealthStatusDeriver.derivePrimaryAlert(
                state("NORMAL", "NORMAL", 0, 70))).isEqualTo("CALVING");
    }

    @Test
    void allClearIsNormalWithNoPrimaryAlert() {
        LivestockHealthState state = state("NORMAL", "NORMAL", 0, null);
        assertThat(HealthStatusDeriver.deriveHealthStatus(state)).isEqualTo("NORMAL");
        assertThat(HealthStatusDeriver.derivePrimaryAlert(state)).isEmpty();
    }

    @Test
    void calvingThresholdConstantIsShared() {
        assertThat(HealthStatusDeriver.CALVING_WARNING_SCORE).isEqualTo(70);
    }
}
