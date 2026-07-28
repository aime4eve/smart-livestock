package com.smartlivestock.iot.domain.service;

import com.smartlivestock.iot.domain.model.QualityGrade;
import com.smartlivestock.iot.domain.port.dto.LineQualityStats;
import com.smartlivestock.iot.domain.service.TrackLineCalculator.LineMatch;
import com.smartlivestock.iot.domain.service.TrackLineCalculator.LinePoint;
import com.smartlivestock.iot.domain.service.TrackLineCalculator.NearestDeviation;
import com.smartlivestock.iot.domain.service.TrackLineCalculator.TrackSample;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.time.Instant;
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
            return new LineQualityStats(samples, 0, p95, p95, p95, p95, 0, 0, 0);
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
    // matchLine: spatial trip-segment matching (corridor + gap + min size)
    // ------------------------------------------------------------------

    private static final Instant T0 = Instant.parse("2026-07-28T00:00:00Z");

    /** A sample ~metersNorth of the straight line's midpoint at time t. */
    private static TrackSample sampleAt(Instant t, double metersNorth) {
        List<LinePoint> line = straightLine();
        double midLng = (line.get(0).longitude() + line.get(1).longitude()) / 2.0;
        return new TrackSample(t, line.get(0).latitude() + metersNorth * ONE_M_LAT, midLng);
    }

    /** count points spaced stepSeconds apart, all ~metersNorth of the line. */
    private static List<TrackSample> trip(Instant start, int count, long stepSeconds,
                                          double metersNorth) {
        List<TrackSample> out = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            out.add(sampleAt(start.plusSeconds(i * stepSeconds), metersNorth));
        }
        return out;
    }

    @Nested
    class SpatialMatching {

        @Test
        void corridorBoundaryIncludes99m() {
            LineMatch match = calculator.matchLine(straightLine(), trip(T0, 4, 60, 99.0));

            assertThat(match.stats().sampleCount()).isEqualTo(4);
            assertThat(match.stats().tripCount()).isEqualTo(1);
            assertThat(match.points()).hasSize(4);
            assertThat(match.stats().maxDeviation()).isCloseTo(99.0, within(0.5));
        }

        @Test
        void corridorBoundaryExcludes101m() {
            LineMatch match = calculator.matchLine(straightLine(), trip(T0, 4, 60, 101.0));

            assertThat(match.stats().sampleCount()).isZero();
            assertThat(match.stats().tripCount()).isZero();
            assertThat(match.points()).isEmpty();
            assertThat(calculator.determineLineGrade(match.stats()))
                    .isEqualTo(QualityGrade.UNAVAILABLE);
        }

        @Test
        void gapOver300sSplitsIntoTwoTrips() {
            List<TrackSample> samples = new ArrayList<>(trip(T0, 4, 60, 10.0));
            samples.addAll(trip(T0.plusSeconds(180 + 301), 4, 60, 20.0));

            LineMatch match = calculator.matchLine(straightLine(), samples);

            assertThat(match.stats().tripCount()).isEqualTo(2);
            assertThat(match.stats().sampleCount()).isEqualTo(8);
        }

        @Test
        void gapExactly300sStaysInOneTrip() {
            LineMatch match = calculator.matchLine(straightLine(), trip(T0, 5, 300, 10.0));

            assertThat(match.stats().tripCount()).isEqualTo(1);
            assertThat(match.stats().sampleCount()).isEqualTo(5);
        }

        @Test
        void segmentWithFewerThan4PointsIsDropped() {
            List<TrackSample> samples = new ArrayList<>(trip(T0, 3, 60, 10.0)); // dropped
            samples.addAll(trip(T0.plusSeconds(1000), 4, 60, 20.0));            // kept

            LineMatch match = calculator.matchLine(straightLine(), samples);

            assertThat(match.stats().tripCount()).isEqualTo(1);
            assertThat(match.stats().sampleCount()).isEqualTo(4);
            assertThat(match.stats().meanDeviation()).isCloseTo(20.0, within(0.5));
        }

        @Test
        void outsideCorridorPointCutsTheSegment() {
            List<TrackSample> samples = new ArrayList<>(trip(T0, 4, 60, 10.0));
            samples.add(sampleAt(T0.plusSeconds(240), 150.0)); // far point cuts the segment
            samples.addAll(trip(T0.plusSeconds(300), 4, 60, 10.0));

            LineMatch match = calculator.matchLine(straightLine(), samples);

            assertThat(match.stats().tripCount()).isEqualTo(2);
            assertThat(match.stats().sampleCount()).isEqualTo(8);
        }

        @Test
        void multipleTripsMergeIntoOneStatistic() {
            List<TrackSample> samples = new ArrayList<>(trip(T0, 4, 60, 10.0));
            samples.addAll(trip(T0.plusSeconds(1000), 4, 60, 20.0));

            LineMatch match = calculator.matchLine(straightLine(), samples);
            LineQualityStats stats = match.stats();

            assertThat(stats.sampleCount()).isEqualTo(8);
            assertThat(stats.tripCount()).isEqualTo(2);
            assertThat(stats.meanDeviation()).isCloseTo(15.0, within(0.5));
            assertThat(stats.maxDeviation()).isCloseTo(20.0, within(0.5));
            // 8 samples < 20 → p95 = max = 20 ≤ 25 with ≥ 6 samples → USABLE
            assertThat(calculator.determineLineGrade(stats)).isEqualTo(QualityGrade.USABLE);
        }

        @Test
        void noValidSegmentYieldsZeroSamplesAndUnavailable() {
            LineMatch match = calculator.matchLine(straightLine(), trip(T0, 10, 60, 150.0));

            assertThat(match.stats().sampleCount()).isZero();
            assertThat(match.stats().tripCount()).isZero();
            assertThat(match.points()).isEmpty();
            assertThat(calculator.determineLineGrade(match.stats()))
                    .isEqualTo(QualityGrade.UNAVAILABLE);
        }

        @Test
        void matchedPointsCarryDeviationAndSegment() {
            LineMatch match = calculator.matchLine(straightLine(), trip(T0, 4, 60, 12.0));

            assertThat(match.points()).allSatisfy(p -> {
                assertThat(p.deviationMeters()).isCloseTo(12.0, within(0.5));
                assertThat(p.segmentNo()).isZero();
            });
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
