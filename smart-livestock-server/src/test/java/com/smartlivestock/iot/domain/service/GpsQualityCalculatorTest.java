package com.smartlivestock.iot.domain.service;

import com.smartlivestock.iot.domain.model.QualityGrade;
import com.smartlivestock.iot.domain.port.dto.GpsPointWithTelemetry;
import com.smartlivestock.iot.domain.port.dto.GpsQualityStats;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.*;

class GpsQualityCalculatorTest {

    private static final BigDecimal RTK_LAT = new BigDecimal("28.2465940");
    private static final BigDecimal RTK_LNG = new BigDecimal("112.8516104");

    /** Earth radius, matches the calculator constant. */
    private static final double EARTH_RADIUS = 6_371_000.0;
    private static final double METERS_PER_DEG_LAT = Math.PI * EARTH_RADIUS / 180.0;

    private final GpsQualityCalculator calculator = new GpsQualityCalculator();

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    /**
     * Build a GPS point at exactly {@code distanceMeters} due north of RTK truth.
     * For pure-north displacement (dLng = 0) the haversine round-trips exactly
     * to {@code distanceMeters} because the cos-terms cancel.
     */
    private GpsPointWithTelemetry pointNorthOf(double distanceMeters) {
        return pointNorthOf(distanceMeters, null);
    }

    private GpsPointWithTelemetry pointNorthOf(double distanceMeters, Integer stepNumber) {
        double deltaLatDeg = distanceMeters / METERS_PER_DEG_LAT;
        BigDecimal lat = RTK_LAT.add(BigDecimal.valueOf(deltaLatDeg));
        return new GpsPointWithTelemetry(
            lat, RTK_LNG,
            BigDecimal.valueOf(10.0),
            Instant.parse("2026-07-15T10:00:00Z"),
            stepNumber,
            stepNumber != null ? BigDecimal.valueOf(0.8) : null,
            stepNumber != null ? "walking" : "stationary"
        );
    }

    /** Build n copies of a point at the given distance (same coordinates). */
    private List<GpsPointWithTelemetry> nPointsAt(int n, double distanceMeters) {
        List<GpsPointWithTelemetry> list = new ArrayList<>(n);
        for (int i = 0; i < n; i++) {
            list.add(pointNorthOf(distanceMeters));
        }
        return list;
    }

    // ==================================================================
    //  N = 0
    // ==================================================================

    @Nested
    class EmptyInput {

        @Test
        void noPoints_returnsUnavailable() {
            GpsQualityStats stats = calculator.calculate(
                List.of(), RTK_LAT, RTK_LNG, false);

            assertThat(stats.totalPoints()).isEqualTo(0);
            assertThat(stats.suspectPoints()).isEqualTo(0);
            assertThat(stats.effectivePoints()).isEqualTo(0);
            assertThat(stats.meanError()).isEqualTo(0.0);
            assertThat(stats.p50()).isEqualTo(0.0);
            assertThat(stats.p95()).isEqualTo(0.0);
            assertThat(stats.p99()).isNull();
            assertThat(stats.maxError()).isEqualTo(0.0);
            assertThat(stats.jitterDiameter()).isEqualTo(0.0);
            assertThat(stats.outlierCount()).isEqualTo(0);
            assertThat(stats.grade()).isEqualTo(QualityGrade.UNAVAILABLE);
        }
    }

    // ==================================================================
    //  N = 5  (low sample degradation)
    // ==================================================================

    @Nested
    class LowSample {

        @Test
        void n5_p99IsNull_p95DegradesToMax() {
            List<GpsPointWithTelemetry> pts = nPointsAt(5, 10.0);

            GpsQualityStats stats = calculator.calculate(pts, RTK_LAT, RTK_LNG, false);

            assertThat(stats.totalPoints()).isEqualTo(5);
            assertThat(stats.effectivePoints()).isEqualTo(5);
            assertThat(stats.p99()).isNull();          // N < 100
            assertThat(stats.p95()).isCloseTo(10.0, within(1e-6)); // N < 20 → max
            assertThat(stats.p50()).isCloseTo(10.0, within(1e-6)); // N >= 5 → percentile
            assertThat(stats.maxError()).isCloseTo(10.0, within(1e-6));
            assertThat(stats.grade()).isEqualTo(QualityGrade.UNAVAILABLE); // eff < 10
        }

        @Test
        void n5_varyingDistances() {
            // errors: 3, 6, 9, 12, 15 → median = 9
            List<GpsPointWithTelemetry> pts = List.of(
                pointNorthOf(3), pointNorthOf(6), pointNorthOf(9),
                pointNorthOf(12), pointNorthOf(15)
            );
            GpsQualityStats stats = calculator.calculate(pts, RTK_LAT, RTK_LNG, false);

            assertThat(stats.p50()).isCloseTo(9.0, within(1e-6));
            assertThat(stats.p95()).isCloseTo(15.0, within(1e-6)); // max degradation
            assertThat(stats.maxError()).isCloseTo(15.0, within(1e-6));
            assertThat(stats.meanError()).isCloseTo(9.0, within(1e-6));
        }
    }

    // ==================================================================
    //  N = 20  (grade boundaries)
    // ==================================================================

    @Nested
    class GradeBoundaries {

        @Test
        void p95_14_9_excellent() {
            GpsQualityStats s = calculator.calculate(
                nPointsAt(20, 14.9), RTK_LAT, RTK_LNG, false);
            assertThat(s.p95()).isCloseTo(14.9, within(1e-6));
            assertThat(s.grade()).isEqualTo(QualityGrade.EXCELLENT);
        }

        @Test
        void p95_15_0_excellentBoundary() {
            GpsQualityStats s = calculator.calculate(
                nPointsAt(20, 15.0), RTK_LAT, RTK_LNG, false);
            assertThat(s.p95()).isCloseTo(15.0, within(1e-6));
            assertThat(s.grade()).isEqualTo(QualityGrade.EXCELLENT);
        }

        @Test
        void p95_15_1_usable() {
            GpsQualityStats s = calculator.calculate(
                nPointsAt(20, 15.1), RTK_LAT, RTK_LNG, false);
            assertThat(s.p95()).isCloseTo(15.1, within(1e-6));
            assertThat(s.grade()).isEqualTo(QualityGrade.USABLE);
        }

        @Test
        void p95_25_0_usableBoundary() {
            GpsQualityStats s = calculator.calculate(
                nPointsAt(20, 25.0), RTK_LAT, RTK_LNG, false);
            assertThat(s.p95()).isCloseTo(25.0, within(1e-6));
            assertThat(s.grade()).isEqualTo(QualityGrade.USABLE);
        }

        @Test
        void p95_25_1_marginal() {
            GpsQualityStats s = calculator.calculate(
                nPointsAt(20, 25.1), RTK_LAT, RTK_LNG, false);
            assertThat(s.p95()).isCloseTo(25.1, within(1e-6));
            assertThat(s.grade()).isEqualTo(QualityGrade.MARGINAL);
        }

        @Test
        void p95_40_0_marginalBoundary() {
            GpsQualityStats s = calculator.calculate(
                nPointsAt(20, 40.0), RTK_LAT, RTK_LNG, false);
            assertThat(s.p95()).isCloseTo(40.0, within(1e-6));
            assertThat(s.grade()).isEqualTo(QualityGrade.MARGINAL);
        }

        @Test
        void p95_40_1_unavailable() {
            GpsQualityStats s = calculator.calculate(
                nPointsAt(20, 40.1), RTK_LAT, RTK_LNG, false);
            assertThat(s.p95()).isCloseTo(40.1, within(1e-6));
            assertThat(s.grade()).isEqualTo(QualityGrade.UNAVAILABLE);
        }

        @Test
        void n10_lowCount_degradesGrade() {
            // 10 effective points at 10m → eff >= 10 but < 20, p95=10 ≤ 15
            // Cannot reach EXCELLENT (needs eff >= 20) → MARGINAL
            GpsQualityStats s = calculator.calculate(
                nPointsAt(10, 10.0), RTK_LAT, RTK_LNG, false);
            assertThat(s.effectivePoints()).isEqualTo(10);
            assertThat(s.grade()).isEqualTo(QualityGrade.MARGINAL);
        }
    }

    // ==================================================================
    //  N = 48  (typical)
    // ==================================================================

    @Nested
    class TypicalCase {

        @Test
        void n48_allMetricsComputed() {
            // 48 points spread 3–20m (step = 0.37 → distances: 3, 3.37, 3.74, …, 20)
            List<GpsPointWithTelemetry> pts = new ArrayList<>(48);
            for (int i = 0; i < 48; i++) {
                double dist = 3.0 + i * (17.0 / 47.0); // 3.0 → 20.0
                pts.add(pointNorthOf(dist));
            }

            GpsQualityStats stats = calculator.calculate(pts, RTK_LAT, RTK_LNG, false);

            assertThat(stats.totalPoints()).isEqualTo(48);
            assertThat(stats.effectivePoints()).isEqualTo(48);
            assertThat(stats.suspectPoints()).isEqualTo(0);
            assertThat(stats.p99()).isNull();           // N < 100
            assertThat(stats.meanError()).isGreaterThan(0.0);
            assertThat(stats.p50()).isLessThanOrEqualTo(stats.p95());
            assertThat(stats.p95()).isLessThanOrEqualTo(stats.maxError());
            assertThat(stats.maxError()).isCloseTo(20.0, within(0.1));
            assertThat(stats.jitterDiameter()).isCloseTo(17.0, within(0.5)); // 20-3=17m spread
            assertThat(stats.outlierCount()).isEqualTo(0);
            // p95 ≈ 19.3 → p95 ≤ 25 && eff ≥ 20 → USABLE
            assertThat(stats.grade()).isEqualTo(QualityGrade.USABLE);
        }
    }

    // ==================================================================
    //  Suspect filtering
    // ==================================================================

    @Nested
    class SuspectExclusion {

        @Test
        void excludeSuspect_removesMovingPoints() {
            // 20 clean points at 10m, 10 suspect at 50m
            List<GpsPointWithTelemetry> pts = new ArrayList<>(30);
            for (int i = 0; i < 20; i++) pts.add(pointNorthOf(10.0));
            for (int i = 0; i < 10; i++) pts.add(pointNorthOf(50.0, 5));

            // --- include suspect ---
            GpsQualityStats incl = calculator.calculate(pts, RTK_LAT, RTK_LNG, false);
            assertThat(incl.totalPoints()).isEqualTo(30);
            assertThat(incl.suspectPoints()).isEqualTo(10);
            assertThat(incl.effectivePoints()).isEqualTo(30);
            // p95 pulled up to 50 by suspect points → UNAVAILABLE
            assertThat(incl.p95()).isCloseTo(50.0, within(1e-6));
            assertThat(incl.grade()).isEqualTo(QualityGrade.UNAVAILABLE);

            // --- exclude suspect ---
            GpsQualityStats excl = calculator.calculate(pts, RTK_LAT, RTK_LNG, true);
            assertThat(excl.totalPoints()).isEqualTo(30);
            assertThat(excl.suspectPoints()).isEqualTo(10);
            assertThat(excl.effectivePoints()).isEqualTo(20);
            assertThat(excl.p95()).isCloseTo(10.0, within(1e-6));
            // 20 effective at 10m → EXCELLENT
            assertThat(excl.grade()).isEqualTo(QualityGrade.EXCELLENT);
        }

        @Test
        void stepNumberNull_isNotSuspect() {
            // stepNumber = null → not suspect (even if distance is large)
            List<GpsPointWithTelemetry> pts = new ArrayList<>(20);
            for (int i = 0; i < 20; i++) pts.add(pointNorthOf(10.0));

            GpsQualityStats stats = calculator.calculate(pts, RTK_LAT, RTK_LNG, true);
            assertThat(stats.suspectPoints()).isEqualTo(0);
            assertThat(stats.effectivePoints()).isEqualTo(20);
        }

        @Test
        void stepNumberZero_isNotSuspect() {
            // stepNumber = 0 → not suspect
            List<GpsPointWithTelemetry> pts = new ArrayList<>(20);
            for (int i = 0; i < 20; i++) {
                pts.add(new GpsPointWithTelemetry(
                    RTK_LAT.add(BigDecimal.valueOf(10.0 / METERS_PER_DEG_LAT)), RTK_LNG,
                    BigDecimal.valueOf(10.0), Instant.parse("2026-07-15T10:00:00Z"),
                    0, null, null));
            }
            GpsQualityStats stats = calculator.calculate(pts, RTK_LAT, RTK_LNG, true);
            assertThat(stats.suspectPoints()).isEqualTo(0);
            assertThat(stats.effectivePoints()).isEqualTo(20);
        }
    }

    // ==================================================================
    //  Outlier detection (N >= 100)
    // ==================================================================

    @Nested
    class OutlierDetection {

        @Test
        void n100_withExtremeOutlier() {
            // 99 points at 5m, 1 at 100m
            List<GpsPointWithTelemetry> pts = new ArrayList<>(100);
            for (int i = 0; i < 99; i++) pts.add(pointNorthOf(5.0));
            pts.add(pointNorthOf(100.0));

            GpsQualityStats stats = calculator.calculate(pts, RTK_LAT, RTK_LNG, false);

            assertThat(stats.effectivePoints()).isEqualTo(100);
            assertThat(stats.p99()).isNotNull();
            assertThat(stats.p99()).isCloseTo(5.0 + 0.01 * (100.0 - 5.0), within(1e-6));
            // 3*P95 ≈ 15, 30.0 floor → threshold = 30; the 100m point is an outlier
            assertThat(stats.outlierCount()).isEqualTo(1);
        }

        @Test
        void n110_noOutliers() {
            // 110 points at 5m — no outliers
            List<GpsPointWithTelemetry> pts = nPointsAt(110, 5.0);

            GpsQualityStats stats = calculator.calculate(pts, RTK_LAT, RTK_LNG, false);

            assertThat(stats.outlierCount()).isEqualTo(0);
            assertThat(stats.p99()).isCloseTo(5.0, within(1e-6));
            assertThat(stats.grade()).isEqualTo(QualityGrade.EXCELLENT);
        }
    }

    // ==================================================================
    //  Jitter diameter
    // ==================================================================

    @Nested
    class JitterDiameter {

        @Test
        void twoPoints_maxPairwiseDistance() {
            List<GpsPointWithTelemetry> pts = List.of(
                pointNorthOf(5.0),
                pointNorthOf(15.0)
            );
            GpsQualityStats stats = calculator.calculate(pts, RTK_LAT, RTK_LNG, false);
            assertThat(stats.jitterDiameter()).isCloseTo(10.0, within(1e-6));
        }

        @Test
        void singlePoint_zeroJitter() {
            GpsQualityStats stats = calculator.calculate(
                nPointsAt(1, 5.0), RTK_LAT, RTK_LNG, false);
            assertThat(stats.jitterDiameter()).isEqualTo(0.0);
        }
    }
}
