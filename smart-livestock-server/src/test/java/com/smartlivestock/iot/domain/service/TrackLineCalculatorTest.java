package com.smartlivestock.iot.domain.service;

import com.smartlivestock.iot.domain.model.QualityGrade;
import com.smartlivestock.iot.domain.port.dto.LineQualityStats;
import com.smartlivestock.iot.domain.service.TrackLineCalculator.LinePoint;
import com.smartlivestock.iot.domain.service.TrackLineCalculator.NearestDeviation;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.*;

class TrackLineCalculatorTest {

    /** ~1m of latitude at the test site, matches the projection constant. */
    private static final double ONE_M_LAT = 1.0 / 110_540.0;

    private final TrackLineCalculator calculator = new TrackLineCalculator();

    /** Straight east-west segment at the ranch site, ~100m long. */
    private static List<LinePoint> straightLine() {
        return List.of(
                new LinePoint(28.2465940, 112.8516104),
                new LinePoint(28.2465940, 112.8516104 + 100.0 / (111_320.0 * Math.cos(Math.toRadians(28.2465940)))));
    }

    // ------------------------------------------------------------------
    // pointToSegmentMeters
    // ------------------------------------------------------------------

    @Nested
    class PointToSegment {

        @Test
        void perpendicularFootInsideSegment() {
            // P is ~10m north of the segment midpoint → foot inside → ~10m
            double pLat = 28.2465940 + 10.0 * ONE_M_LAT;
            double pLng = 112.8516104 + 50.0 / (111_320.0 * Math.cos(Math.toRadians(28.2465940)));
            List<LinePoint> line = straightLine();

            NearestDeviation result = calculator.nearestDeviation(pLat, pLng, line);

            assertThat(result.deviationMeters()).isCloseTo(10.0, within(0.2));
            assertThat(result.segmentNo()).isZero();
        }

        @Test
        void footBeyondSegmentEndFallsBackToEndpoint() {
            // P sits ~30m beyond the segment end → endpoint distance, not perpendicular
            List<LinePoint> line = straightLine();
            LinePoint end = line.get(1);
            double pLat = end.latitude();
            double pLng = end.longitude() + 30.0 / (111_320.0 * Math.cos(Math.toRadians(end.latitude())));

            double d = calculator.pointToSegmentMeters(pLat, pLng,
                    line.get(0).latitude(), line.get(0).longitude(),
                    end.latitude(), end.longitude());

            assertThat(d).isCloseTo(30.0, within(0.2));
        }

        @Test
        void degenerateSegmentUsesEndpointDistance() {
            // A == B → distance to the single point (~15m north)
            double d = calculator.pointToSegmentMeters(
                    28.2465940 + 15.0 * ONE_M_LAT, 112.8516104,
                    28.2465940, 112.8516104,
                    28.2465940, 112.8516104);

            assertThat(d).isCloseTo(15.0, within(0.2));
        }
    }

    // ------------------------------------------------------------------
    // nearestDeviation over a multi-segment polyline
    // ------------------------------------------------------------------

    @Nested
    class NearestOnPolyline {

        @Test
        void cornerProjectionPicksNearestSegment() {
            // L-shaped line: east 100m then north 100m; P near the north leg
            LinePoint corner = new LinePoint(28.2465940, 112.8516104);
            double cosLat = Math.cos(Math.toRadians(corner.latitude()));
            LinePoint east = new LinePoint(corner.latitude(),
                    corner.longitude() + 100.0 / (111_320.0 * cosLat));
            LinePoint north = new LinePoint(corner.latitude() + 100.0 * ONE_M_LAT,
                    corner.longitude());
            List<LinePoint> line = List.of(east, corner, north);

            // P ~8m east of the north leg midpoint → nearest segment is #1 (corner→north)
            double pLat = corner.latitude() + 50.0 * ONE_M_LAT;
            double pLng = corner.longitude() + 8.0 / (111_320.0 * cosLat);

            NearestDeviation result = calculator.nearestDeviation(pLat, pLng, line);

            assertThat(result.segmentNo()).isEqualTo(1);
            assertThat(result.deviationMeters()).isCloseTo(8.0, within(0.2));
        }

        @Test
        void equalDistanceTieKeepsFirstSegment() {
            // P exactly on the shared corner → both segments give 0m; first wins
            LinePoint corner = new LinePoint(28.2465940, 112.8516104);
            List<LinePoint> line = List.of(
                    new LinePoint(corner.latitude(), corner.longitude() - 0.001),
                    corner,
                    new LinePoint(corner.latitude() + 0.001, corner.longitude()));

            NearestDeviation result = calculator.nearestDeviation(
                    corner.latitude(), corner.longitude(), line);

            assertThat(result.deviationMeters()).isCloseTo(0.0, within(1e-6));
            assertThat(result.segmentNo()).isZero();
        }

        @Test
        void rejectsLineWithFewerThanTwoPoints() {
            assertThatThrownBy(() -> calculator.nearestDeviation(28.0, 112.0, List.of()))
                    .isInstanceOf(IllegalArgumentException.class);
            assertThatThrownBy(() -> calculator.nearestDeviation(28.0, 112.0,
                    List.of(new LinePoint(28.0, 112.0))))
                    .isInstanceOf(IllegalArgumentException.class);
        }
    }

    // ------------------------------------------------------------------
    // aggregate
    // ------------------------------------------------------------------

    @Nested
    class Aggregate {

        @Test
        void emptyDeviationsYieldZeroStats() {
            LineQualityStats stats = calculator.aggregate(List.of());

            assertThat(stats.sampleCount()).isZero();
            assertThat(stats.meanDeviation()).isZero();
            assertThat(stats.p95()).isZero();
            assertThat(calculator.determineLineGrade(stats)).isEqualTo(QualityGrade.UNAVAILABLE);
        }

        @Test
        void degeneratePercentilesFallBackToMax() {
            // 4 samples (< 5 and < 20): p50 and p95 both equal max
            LineQualityStats stats = calculator.aggregate(List.of(5.0, 10.0, 20.0, 30.0));

            assertThat(stats.sampleCount()).isEqualTo(4);
            assertThat(stats.meanDeviation()).isCloseTo(16.25, within(1e-9));
            assertThat(stats.p50()).isEqualTo(30.0);
            assertThat(stats.p95()).isEqualTo(30.0);
            assertThat(stats.maxDeviation()).isEqualTo(30.0);
        }

        @Test
        void percentilesUseLinearInterpolation() {
            // 20 samples 1..20 → p95 = index 0.95*19 = 18.05 → 19 + 0.05*(20-19) = 19.05
            List<Double> deviations = new ArrayList<>();
            for (int i = 1; i <= 20; i++) deviations.add((double) i);

            LineQualityStats stats = calculator.aggregate(deviations);

            assertThat(stats.p95()).isCloseTo(19.05, within(1e-9));
            assertThat(stats.p50()).isCloseTo(10.5, within(1e-9));
            assertThat(stats.within15mPct()).isCloseTo(75.0, within(1e-9));
            assertThat(stats.within25mPct()).isCloseTo(100.0, within(1e-9));
            assertThat(stats.within40mPct()).isCloseTo(100.0, within(1e-9));
        }
    }

    // ------------------------------------------------------------------
    // determineLineGrade (spec D10 thresholds)
    // ------------------------------------------------------------------

    @Nested
    class Grading {

        private LineQualityStats stats(int samples, double p95) {
            return new LineQualityStats(samples, p95, p95, p95, p95, 0, 0, 0);
        }

        @Test
        void p95Exactly15With10SamplesIsExcellent() {
            assertThat(calculator.determineLineGrade(stats(10, 15.0)))
                    .isEqualTo(QualityGrade.EXCELLENT);
        }

        @Test
        void p95JustAbove15DropsToUsable() {
            assertThat(calculator.determineLineGrade(stats(10, 15.01)))
                    .isEqualTo(QualityGrade.USABLE);
        }

        @Test
        void nineSamplesCannotBeExcellent() {
            assertThat(calculator.determineLineGrade(stats(9, 10.0)))
                    .isEqualTo(QualityGrade.USABLE);
        }

        @Test
        void p95Exactly40With4SamplesIsMarginal() {
            assertThat(calculator.determineLineGrade(stats(4, 40.0)))
                    .isEqualTo(QualityGrade.MARGINAL);
        }

        @Test
        void fewerThan4SamplesIsUnavailable() {
            assertThat(calculator.determineLineGrade(stats(3, 5.0)))
                    .isEqualTo(QualityGrade.UNAVAILABLE);
        }

        @Test
        void p95Above40IsUnavailable() {
            assertThat(calculator.determineLineGrade(stats(10, 40.01)))
                    .isEqualTo(QualityGrade.UNAVAILABLE);
        }
    }

    // ------------------------------------------------------------------
    // polylineLengthMeters
    // ------------------------------------------------------------------

    @Test
    void polylineLengthSumsHaversineSegments() {
        List<LinePoint> line = straightLine();
        // ~100m straight line
        assertThat(calculator.polylineLengthMeters(line)).isCloseTo(100.0, within(0.5));
        assertThat(calculator.polylineLengthMeters(List.of())).isZero();
        assertThat(calculator.polylineLengthMeters(List.of(new LinePoint(28.0, 112.0)))).isZero();
    }
}
