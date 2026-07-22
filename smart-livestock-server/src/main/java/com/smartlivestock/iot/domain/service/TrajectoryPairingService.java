package com.smartlivestock.iot.domain.service;

import com.smartlivestock.iot.domain.model.GpsQualityTrackPoint;
import com.smartlivestock.iot.domain.model.QualityGrade;
import com.smartlivestock.iot.domain.model.TrackMatchSource;
import com.smartlivestock.iot.domain.port.dto.TrajectoryQualityStats;
import com.smartlivestock.iot.domain.port.dto.TrackPairCandidate;
import com.smartlivestock.iot.domain.port.dto.TrackPairResult;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;

/**
 * Pure domain service for TRAJECTORY tests: pairs imported RTK track points
 * with device coordinates (spec §4), aggregates error statistics and assigns
 * the trajectory grade (spec §6.5).
 * <p>
 * Pairing rules:
 * <ul>
 *   <li>File carries device coordinates → FILE (timeDiff = 0)</li>
 *   <li>Otherwise the gps_logs candidate nearest to the collection time wins
 *       when within the tolerance; equidistant ties go to the earlier report</li>
 *   <li>No candidate within tolerance → UNPAIRED (excluded from statistics)</li>
 * </ul>
 * No IO dependencies — safe to unit-test in isolation.
 */
public class TrajectoryPairingService {

    /** Default pairing tolerance T in seconds (spec D3). */
    public static final int DEFAULT_TOLERANCE_SECONDS = 60;

    private static final double EARTH_RADIUS_METERS = 6_371_000.0;

    /**
     * Pair one track point with its device coordinate.
     *
     * @param collectedAt      collection time of the track point
     * @param fileLatitude     device latitude from the file (null → pair from candidates)
     * @param fileLongitude    device longitude from the file (null → pair from candidates)
     * @param candidates       gps_logs reports of the same device (any order)
     * @param toleranceSeconds max allowed |recordedAt - collectedAt|
     * @return pairing outcome; never {@code null}
     */
    public TrackPairResult pair(
        Instant collectedAt,
        BigDecimal fileLatitude,
        BigDecimal fileLongitude,
        List<TrackPairCandidate> candidates,
        int toleranceSeconds
    ) {
        if (fileLatitude != null && fileLongitude != null) {
            return new TrackPairResult(TrackMatchSource.FILE, fileLatitude, fileLongitude, null, 0);
        }

        TrackPairCandidate best = null;
        long bestDiff = Long.MAX_VALUE;
        for (TrackPairCandidate c : candidates) {
            long diff = Math.abs(Duration.between(collectedAt, c.recordedAt()).getSeconds());
            if (diff > toleranceSeconds) {
                continue;
            }
            // Strictly smaller diff wins; on an exact tie the earlier report
            // wins (deterministic, spec §4.2).
            if (diff < bestDiff
                || (diff == bestDiff && best != null && c.recordedAt().isBefore(best.recordedAt()))) {
                best = c;
                bestDiff = diff;
            }
        }

        if (best == null) {
            return new TrackPairResult(TrackMatchSource.UNPAIRED, null, null, null, null);
        }
        return new TrackPairResult(TrackMatchSource.GPS_LOG,
            best.latitude(), best.longitude(), best.gpsLogId(), (int) bestDiff);
    }

    /**
     * Aggregate error statistics over persisted track points.
     * UNPAIRED points are counted but excluded from error distribution.
     */
    public TrajectoryQualityStats aggregate(List<GpsQualityTrackPoint> points) {
        int total = points.size();
        int filePaired = 0;
        int logPaired = 0;
        int unpaired = 0;

        double[] errors = new double[total];
        int paired = 0;
        for (GpsQualityTrackPoint p : points) {
            switch (p.getMatchSource()) {
                case FILE -> filePaired++;
                case GPS_LOG -> logPaired++;
                case UNPAIRED -> { unpaired++; continue; }
            }
            errors[paired++] = errorMeters(p);
        }

        double pairRate = total == 0 ? 0.0 : (double) paired / total * 100.0;

        double[] sorted = Arrays.copyOf(errors, paired);
        Arrays.sort(sorted);

        double mean = paired == 0 ? 0.0 : Arrays.stream(sorted).average().orElse(0.0);
        double max = paired == 0 ? 0.0 : sorted[paired - 1];
        double p50 = paired >= 5 ? percentile(sorted, 50) : max;
        double p95 = paired >= 20 ? percentile(sorted, 95) : max;

        return new TrajectoryQualityStats(total, filePaired, logPaired, unpaired,
            pairRate, mean, p50, p95, max);
    }

    /**
     * Trajectory grade (spec §6.5): static-grade error bands plus a pair-rate
     * constraint. Thresholds are initial values, to be calibrated with real data.
     */
    public QualityGrade determineTrajectoryGrade(TrajectoryQualityStats stats) {
        int paired = stats.filePaired() + stats.logPaired();
        if (paired >= 10 && stats.p95() <= 15.0 && stats.pairRate() >= 80.0) {
            return QualityGrade.EXCELLENT;
        }
        if (paired >= 6 && stats.p95() <= 25.0 && stats.pairRate() >= 60.0) {
            return QualityGrade.USABLE;
        }
        if (paired >= 4 && stats.p95() <= 40.0) {
            return QualityGrade.MARGINAL;
        }
        return QualityGrade.UNAVAILABLE;
    }

    /** Horizontal error of one paired track point in meters (RTK truth vs device). */
    public double errorMeters(GpsQualityTrackPoint p) {
        return haversine(
            p.getRtkLatitude().doubleValue(), p.getRtkLongitude().doubleValue(),
            p.getDeviceLatitude().doubleValue(), p.getDeviceLongitude().doubleValue());
    }

    // ------------------------------------------------------------------
    // Percentile — linear interpolation on a sorted ascending array
    // ------------------------------------------------------------------

    private double percentile(double[] sorted, int pct) {
        int n = sorted.length;
        if (n == 0) return 0.0;
        if (n == 1) return sorted[0];

        double index = (pct / 100.0) * (n - 1);
        int lower = (int) Math.floor(index);
        int upper = (int) Math.ceil(index);
        if (lower == upper) return sorted[lower];
        double fraction = index - lower;
        return sorted[lower] + fraction * (sorted[upper] - sorted[lower]);
    }

    // ------------------------------------------------------------------
    // Haversine distance (independent copy, same convention as the other calculators)
    // ------------------------------------------------------------------

    private double haversine(double lat1, double lng1, double lat2, double lng2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
            + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
            * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return EARTH_RADIUS_METERS * c;
    }
}
