package com.smartlivestock.iot.domain.service;

import com.smartlivestock.iot.domain.port.dto.DynamicQualityStats;
import com.smartlivestock.iot.domain.port.dto.GpsPointWithTelemetry;
import com.smartlivestock.iot.domain.port.dto.RoutePoint;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.*;

class DynamicQualityCalculatorTest {

    private static final BigDecimal BASE_LAT = new BigDecimal("28.2465940");
    private static final BigDecimal BASE_LNG = new BigDecimal("112.8516104");

    private static final double EARTH_RADIUS = 6_371_000.0;
    private static final double METERS_PER_DEG_LAT = Math.PI * EARTH_RADIUS / 180.0;

    private final DynamicQualityCalculator calculator = new DynamicQualityCalculator();

    // ------------------------------------------------------------------
    // Helpers — points offset due north of the base coordinate
    // ------------------------------------------------------------------

    /** Route point at {@code distMeters} due north of base, with sequence {@code seq}. */
    private RoutePoint routeNorth(int seq, double distMeters) {
        double deltaLatDeg = distMeters / METERS_PER_DEG_LAT;
        return new RoutePoint(
            BASE_LAT.add(BigDecimal.valueOf(deltaLatDeg)),
            BASE_LNG,
            seq);
    }

    /** GPS report at {@code distMeters} due north of base, at the given timestamp. */
    private GpsPointWithTelemetry gpsNorth(double distMeters, Instant recordedAt) {
        double deltaLatDeg = distMeters / METERS_PER_DEG_LAT;
        return new GpsPointWithTelemetry(
            BASE_LAT.add(BigDecimal.valueOf(deltaLatDeg)),
            BASE_LNG,
            BigDecimal.valueOf(10.0),
            recordedAt,
            null, null, null);
    }

    // ==================================================================
    //  Perfect match
    // ==================================================================

    @Nested
    class PerfectMatch {

        @Test
        void threePoints_onRoute_fullCoverage_inOrder() {
            List<RoutePoint> route = List.of(
                routeNorth(1, 0), routeNorth(2, 100), routeNorth(3, 200));
            List<GpsPointWithTelemetry> gps = List.of(
                gpsNorth(0, Instant.parse("2026-07-15T10:00:00Z")),
                gpsNorth(100, Instant.parse("2026-07-15T10:30:00Z")),
                gpsNorth(200, Instant.parse("2026-07-15T11:00:00Z")));

            DynamicQualityStats s = calculator.calculate(route, gps);

            assertThat(s.routePointCount()).isEqualTo(3);
            assertThat(s.matchedCount()).isEqualTo(3);
            assertThat(s.missedCount()).isEqualTo(0);
            assertThat(s.ambiguousCount()).isEqualTo(0);
            assertThat(s.transitCount()).isEqualTo(0);
            assertThat(s.coverage()).isCloseTo(100.0, within(1e-6));
            assertThat(s.inOrder()).isTrue();
            assertThat(s.meanError()).isCloseTo(0.0, within(1e-6));
            assertThat(s.maxError()).isCloseTo(0.0, within(1e-6));
        }
    }

    // ==================================================================
    //  Missed point
    // ==================================================================

    @Nested
    class MissedPoint {

        @Test
        void thirdGpsDriftsBeyondThreshold_oneMissed() {
            // Route: 0, 100, 200, 300 m. GPS #3 sits at 240 m (40 m from R3 → missed).
            List<RoutePoint> route = List.of(
                routeNorth(1, 0), routeNorth(2, 100),
                routeNorth(3, 200), routeNorth(4, 300));
            List<GpsPointWithTelemetry> gps = List.of(
                gpsNorth(0, Instant.parse("2026-07-15T10:00:00Z")),
                gpsNorth(100, Instant.parse("2026-07-15T10:30:00Z")),
                gpsNorth(240, Instant.parse("2026-07-15T11:00:00Z")),
                gpsNorth(300, Instant.parse("2026-07-15T11:30:00Z")));

            DynamicQualityStats s = calculator.calculate(route, gps);

            assertThat(s.routePointCount()).isEqualTo(4);
            assertThat(s.matchedCount()).isEqualTo(3);
            assertThat(s.missedCount()).isEqualTo(1);
            assertThat(s.coverage()).isCloseTo(75.0, within(1e-6));
            assertThat(s.transitCount()).isEqualTo(1); // the drifted report is unmatched
        }
    }

    // ==================================================================
    //  Ambiguity
    // ==================================================================

    @Nested
    class Ambiguity {

        @Test
        void adjacentRoutePointsShareGpsReport_ambiguous() {
            // Two route points 5 m apart, one GPS report in the middle.
            List<RoutePoint> route = List.of(
                routeNorth(1, 0), routeNorth(2, 5));
            List<GpsPointWithTelemetry> gps = List.of(
                gpsNorth(2.5, Instant.parse("2026-07-15T10:00:00Z")));

            DynamicQualityStats s = calculator.calculate(route, gps);

            assertThat(s.matchedCount()).isEqualTo(2);
            assertThat(s.ambiguousCount()).isEqualTo(1);
            assertThat(s.transitCount()).isEqualTo(0);
        }
    }

    // ==================================================================
    //  Order compliance
    // ==================================================================

    @Nested
    class OrderCompliance {

        @Test
        void reversedTimestamps_inOrderFalse() {
            List<RoutePoint> route = List.of(
                routeNorth(1, 0), routeNorth(2, 100));
            List<GpsPointWithTelemetry> gps = List.of(
                gpsNorth(0, Instant.parse("2026-07-15T10:01:00Z")),
                gpsNorth(100, Instant.parse("2026-07-15T10:00:00Z")));

            DynamicQualityStats s = calculator.calculate(route, gps);

            assertThat(s.matchedCount()).isEqualTo(2);
            assertThat(s.inOrder()).isFalse();
        }

        @Test
        void equalTimestampsAmbiguity_inOrderTrue() {
            // Same GPS report serves both route points (equal timestamps) → still in order.
            List<RoutePoint> route = List.of(
                routeNorth(1, 0), routeNorth(2, 5));
            List<GpsPointWithTelemetry> gps = List.of(
                gpsNorth(2.5, Instant.parse("2026-07-15T10:00:00Z")));

            DynamicQualityStats s = calculator.calculate(route, gps);

            assertThat(s.inOrder()).isTrue();
        }
    }

    // ==================================================================
    //  Empty input
    // ==================================================================

    @Nested
    class EmptyInput {

        @Test
        void emptyRoute_coverageZero_allGpsTransit() {
            DynamicQualityStats s = calculator.calculate(
                List.of(),
                List.of(gpsNorth(0, Instant.parse("2026-07-15T10:00:00Z"))));

            assertThat(s.routePointCount()).isEqualTo(0);
            assertThat(s.matchedCount()).isEqualTo(0);
            assertThat(s.coverage()).isEqualTo(0.0);
            assertThat(s.transitCount()).isEqualTo(1);
        }

        @Test
        void emptyGps_allRouteMissed() {
            List<RoutePoint> route = List.of(
                routeNorth(1, 0), routeNorth(2, 100));

            DynamicQualityStats s = calculator.calculate(route, List.of());

            assertThat(s.routePointCount()).isEqualTo(2);
            assertThat(s.matchedCount()).isEqualTo(0);
            assertThat(s.missedCount()).isEqualTo(2);
            assertThat(s.coverage()).isEqualTo(0.0);
            assertThat(s.inOrder()).isTrue();
        }
    }

    // ==================================================================
    //  Error distribution
    // ==================================================================

    @Nested
    class ErrorDistribution {

        @Test
        void fiveMatched_meanP50P95() {
            // Errors: 3, 6, 9, 12, 15 → mean=9, p50=9, p95=max=15 (n < 20)
            List<RoutePoint> route = List.of(
                routeNorth(1, 0), routeNorth(2, 100), routeNorth(3, 200),
                routeNorth(4, 300), routeNorth(5, 400));
            List<GpsPointWithTelemetry> gps = List.of(
                gpsNorth(3, Instant.parse("2026-07-15T10:00:00Z")),
                gpsNorth(106, Instant.parse("2026-07-15T10:30:00Z")),
                gpsNorth(209, Instant.parse("2026-07-15T11:00:00Z")),
                gpsNorth(312, Instant.parse("2026-07-15T11:30:00Z")),
                gpsNorth(415, Instant.parse("2026-07-15T12:00:00Z")));

            DynamicQualityStats s = calculator.calculate(route, gps);

            assertThat(s.matchedCount()).isEqualTo(5);
            assertThat(s.meanError()).isCloseTo(9.0, within(1e-6));
            assertThat(s.p50()).isCloseTo(9.0, within(1e-6));   // n >= 5 → percentile
            assertThat(s.p95()).isCloseTo(15.0, within(1e-6));  // n < 20 → max
            assertThat(s.maxError()).isCloseTo(15.0, within(1e-6));
        }
    }
}
