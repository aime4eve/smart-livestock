package com.smartlivestock.iot.domain.service;

import com.smartlivestock.iot.domain.model.GpsQualityTrackPoint;
import com.smartlivestock.iot.domain.model.QualityGrade;
import com.smartlivestock.iot.domain.model.TrackMatchSource;
import com.smartlivestock.iot.domain.port.dto.TrajectoryQualityStats;
import com.smartlivestock.iot.domain.port.dto.TrackPairCandidate;
import com.smartlivestock.iot.domain.port.dto.TrackPairResult;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.*;

class TrajectoryPairingServiceTest {

    private static final BigDecimal BASE_LAT = new BigDecimal("28.2284100");
    private static final BigDecimal BASE_LNG = new BigDecimal("112.9387600");
    private static final Instant T0 = Instant.parse("2026-07-21T01:00:00Z");

    private static final double EARTH_RADIUS = 6_371_000.0;
    private static final double METERS_PER_DEG_LAT = Math.PI * EARTH_RADIUS / 180.0;

    private final TrajectoryPairingService service = new TrajectoryPairingService();

    /** Coordinate {@code distMeters} due north of base. */
    private static BigDecimal north(double distMeters) {
        return BASE_LAT.add(BigDecimal.valueOf(distMeters / METERS_PER_DEG_LAT));
    }

    private static TrackPairCandidate logAt(long id, double northMeters, Instant recordedAt) {
        return new TrackPairCandidate(id, north(northMeters), BASE_LNG, recordedAt);
    }

    private static GpsQualityTrackPoint point(TrackMatchSource source, double rtkNorth, Double devNorth) {
        GpsQualityTrackPoint p = new GpsQualityTrackPoint();
        p.setMatchSource(source);
        p.setCollectedAt(T0);
        p.setRtkLatitude(north(rtkNorth));
        p.setRtkLongitude(BASE_LNG);
        if (devNorth != null) {
            p.setDeviceLatitude(north(devNorth));
            p.setDeviceLongitude(BASE_LNG);
        }
        return p;
    }

    // ------------------------------------------------------------------
    // pair()
    // ------------------------------------------------------------------

    @Nested
    class Pair {

        @Test
        void fileCoordinatesShortCircuitWithoutCandidates() {
            TrackPairResult r = service.pair(T0, north(5), BASE_LNG, List.of(), 60);

            assertThat(r.matchSource()).isEqualTo(TrackMatchSource.FILE);
            assertThat(r.deviceLatitude()).isEqualByComparingTo(north(5));
            assertThat(r.timeDiffSeconds()).isZero();
            assertThat(r.matchedGpsLogId()).isNull();
        }

        @Test
        void pairsNearestLogWithinTolerance() {
            List<TrackPairCandidate> candidates = List.of(
                logAt(1, 10, T0.plusSeconds(30)),
                logAt(2, 20, T0.plusSeconds(50)));

            TrackPairResult r = service.pair(T0, null, null, candidates, 60);

            assertThat(r.matchSource()).isEqualTo(TrackMatchSource.GPS_LOG);
            assertThat(r.matchedGpsLogId()).isEqualTo(1);
            assertThat(r.timeDiffSeconds()).isEqualTo(30);
        }

        @Test
        void equidistantTieGoesToEarlierReport() {
            List<TrackPairCandidate> candidates = List.of(
                logAt(1, 10, T0.plusSeconds(30)),
                logAt(2, 20, T0.minusSeconds(30)));

            TrackPairResult r = service.pair(T0, null, null, candidates, 60);

            assertThat(r.matchedGpsLogId()).isEqualTo(2);
        }

        @Test
        void beyondToleranceIsUnpaired() {
            List<TrackPairCandidate> candidates = List.of(logAt(1, 10, T0.plusSeconds(61)));

            TrackPairResult r = service.pair(T0, null, null, candidates, 60);

            assertThat(r.matchSource()).isEqualTo(TrackMatchSource.UNPAIRED);
            assertThat(r.deviceLatitude()).isNull();
            assertThat(r.timeDiffSeconds()).isNull();
        }

        @Test
        void emptyCandidatesIsUnpaired() {
            TrackPairResult r = service.pair(T0, null, null, List.of(), 60);
            assertThat(r.matchSource()).isEqualTo(TrackMatchSource.UNPAIRED);
        }
    }

    // ------------------------------------------------------------------
    // aggregate()
    // ------------------------------------------------------------------

    @Nested
    class Aggregate {

        @Test
        void emptyListYieldsZeros() {
            TrajectoryQualityStats s = service.aggregate(List.of());

            assertThat(s.totalPoints()).isZero();
            assertThat(s.pairRate()).isZero();
            assertThat(s.maxError()).isZero();
        }

        @Test
        void unpairedExcludedFromErrorStatistics() {
            List<GpsQualityTrackPoint> points = List.of(
                point(TrackMatchSource.FILE, 0, 5.0),
                point(TrackMatchSource.GPS_LOG, 0, 15.0),
                point(TrackMatchSource.UNPAIRED, 0, null));

            TrajectoryQualityStats s = service.aggregate(points);

            assertThat(s.totalPoints()).isEqualTo(3);
            assertThat(s.filePaired()).isEqualTo(1);
            assertThat(s.logPaired()).isEqualTo(1);
            assertThat(s.unpaired()).isEqualTo(1);
            assertThat(s.pairRate()).isCloseTo(66.67, within(0.01));
            assertThat(s.meanError()).isCloseTo(10.0, within(0.5));
            assertThat(s.maxError()).isCloseTo(15.0, within(0.5));
        }

        @Test
        void percentilesDegradeToMaxOnSmallSamples() {
            // 3 paired points: p50 and p95 both degrade to maxError
            List<GpsQualityTrackPoint> points = List.of(
                point(TrackMatchSource.FILE, 0, 5.0),
                point(TrackMatchSource.FILE, 0, 10.0),
                point(TrackMatchSource.FILE, 0, 20.0));

            TrajectoryQualityStats s = service.aggregate(points);

            assertThat(s.p50()).isCloseTo(s.maxError(), within(0.001));
            assertThat(s.p95()).isCloseTo(s.maxError(), within(0.001));
        }

        @Test
        void p95ComputedWhenEnoughSamples() {
            // 20 paired points at 1..20m → p95 interpolated, not max
            List<GpsQualityTrackPoint> points = new ArrayList<>();
            for (int i = 1; i <= 20; i++) {
                points.add(point(TrackMatchSource.FILE, 0, (double) i));
            }

            TrajectoryQualityStats s = service.aggregate(points);

            assertThat(s.p95()).isLessThan(s.maxError());
            assertThat(s.p95()).isCloseTo(19.05, within(0.5));
        }
    }

    // ------------------------------------------------------------------
    // determineTrajectoryGrade()
    // ------------------------------------------------------------------

    @Nested
    class Grade {

        private TrajectoryQualityStats stats(int paired, double p95, double pairRate) {
            return new TrajectoryQualityStats(
                paired, paired, 0, 0, pairRate, 0.0, 0.0, p95, p95);
        }

        @Test
        void prototypeExampleIsExcellent() {
            // Prototype report card: p95 = 12.4m, pairRate = 87.5%, paired = 21
            TrajectoryQualityStats s = new TrajectoryQualityStats(
                24, 14, 7, 3, 87.5, 6.8, 5.9, 12.4, 18.2);

            assertThat(service.determineTrajectoryGrade(s)).isEqualTo(QualityGrade.EXCELLENT);
        }

        @Test
        void excellentRequiresTenPairedSamples() {
            assertThat(service.determineTrajectoryGrade(stats(9, 10.0, 100.0)))
                .isEqualTo(QualityGrade.USABLE);
        }

        @Test
        void excellentRequiresPairRateAboveEighty() {
            assertThat(service.determineTrajectoryGrade(stats(10, 12.0, 79.9)))
                .isEqualTo(QualityGrade.USABLE);
        }

        @Test
        void usableRequiresPairRateAboveSixty() {
            assertThat(service.determineTrajectoryGrade(stats(6, 20.0, 59.9)))
                .isEqualTo(QualityGrade.MARGINAL);
        }

        @Test
        void fewerThanFourPairedIsUnavailable() {
            assertThat(service.determineTrajectoryGrade(stats(3, 5.0, 100.0)))
                .isEqualTo(QualityGrade.UNAVAILABLE);
        }

        @Test
        void p95AboveFortyIsUnavailable() {
            assertThat(service.determineTrajectoryGrade(stats(10, 41.0, 100.0)))
                .isEqualTo(QualityGrade.UNAVAILABLE);
        }
    }
}
