package com.smartlivestock.iot.application;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * F4/F5 presence scenario decision logic (NIX-219 P3).
 * Baseline: farm median + MAD multiplier, gated by an absolute minimum distance —
 * two animals never wander far apart (WiMOB 2019), so the absolute floor keeps
 * tiny herds from producing noise alerts.
 */
class LivestockPresenceServiceTest {

    private static final double MAD_MULT = 3.0;
    private static final double MIN_DIST = 1500.0;

    @Test
    void compactHerd_withoutStraggler_flagsNothing() {
        // median=300, MAD=60 → bound=480; all distances below and under the 1500m floor.
        List<Double> herd = List.of(180.0, 240.0, 300.0, 360.0, 420.0);
        double median = median(herd);
        double mad = median(herd.stream().map(d -> Math.abs(d - median)).sorted().toList());
        assertThat(LivestockPresenceService.isOutlier(420, median, mad, MAD_MULT, MIN_DIST)).isFalse();
    }

    @Test
    void straggler_beyondBaselineAndFloor_isFlagged() {
        // median=300, MAD=60 → bound=480; 2500m is far beyond both.
        List<Double> herd = List.of(180.0, 240.0, 300.0, 360.0, 2500.0);
        double median = median(herd);
        double mad = median(herd.stream().map(d -> Math.abs(d - median)).sorted().toList());
        assertThat(LivestockPresenceService.isOutlier(2500, median, mad, MAD_MULT, MIN_DIST)).isTrue();
    }

    @Test
    void farButCompactHerd_isNotFlagged() {
        // Whole herd relocated to ~2km (median 2000): no one is an outlier relative
        // to the group — e.g. seasonal grazing rotation, not theft.
        List<Double> herd = List.of(1800.0, 1900.0, 2000.0, 2100.0, 2200.0);
        double median = median(herd);
        double mad = median(herd.stream().map(d -> Math.abs(d - median)).sorted().toList());
        assertThat(LivestockPresenceService.isOutlier(2200, median, mad, MAD_MULT, MIN_DIST)).isFalse();
    }

    @Test
    void nearButOutsideBaseline_isNotFlagged() {
        // 600m exceeds the baseline bound but is below the absolute floor:
        // baseline-only outliers are noise, not a theft signal.
        List<Double> herd = List.of(180.0, 240.0, 300.0, 360.0, 420.0);
        double median = median(herd);
        double mad = median(herd.stream().map(d -> Math.abs(d - median)).sorted().toList());
        assertThat(LivestockPresenceService.isOutlier(600, median, mad, MAD_MULT, MIN_DIST)).isFalse();
    }

    @Test
    void zeroMad_allIdentical_stillFlagsTrueStraggler() {
        // All animals at exactly 200m (MAD=0): a single 2km device must flag.
        List<Double> herd = List.of(200.0, 200.0, 2000.0);
        double median = median(herd);
        double mad = median(herd.stream().map(d -> Math.abs(d - median)).sorted().toList());
        assertThat(LivestockPresenceService.isOutlier(2000, median, mad, MAD_MULT, MIN_DIST)).isTrue();
        assertThat(LivestockPresenceService.isOutlier(200, median, mad, MAD_MULT, MIN_DIST)).isFalse();
    }

    private static double median(List<Double> values) {
        List<Double> sorted = new java.util.ArrayList<>(values);
        java.util.Collections.sort(sorted);
        int n = sorted.size();
        return n % 2 == 1
                ? sorted.get(n / 2)
                : (sorted.get(n / 2 - 1) + sorted.get(n / 2)) / 2.0;
    }
}
