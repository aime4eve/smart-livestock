package com.smartlivestock.iot.domain.service;

import com.smartlivestock.iot.domain.port.dto.DynamicQualityStats;
import com.smartlivestock.iot.domain.port.dto.GpsPointWithTelemetry;
import com.smartlivestock.iot.domain.port.dto.RoutePoint;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * Pure domain service that computes GPS dynamic quality statistics by matching
 * time-windowed GPS reports against an ordered RTK route (spec §4.2).
 * <p>
 * Route-driven matching: for each route point (in sequence order), find the
 * nearest GPS report within the threshold. When the same GPS report is the
 * nearest match for two adjacent route points, the later match is flagged
 * ambiguous and the shared report is attributed to the earlier sequence
 * (spec §4.2 ambiguity handling).
 * <p>
 * No IO dependencies — safe to unit-test in isolation.
 */
public class DynamicQualityCalculator {

    /** Default matching threshold T in meters (spec §4.1). */
    public static final double DEFAULT_THRESHOLD = 30.0;

    private static final double EARTH_RADIUS_METERS = 6_371_000.0;

    /**
     * Calculate dynamic quality statistics using the default threshold (30m).
     *
     * @param route      RTK route points (sorted by sequenceNo internally)
     * @param gpsPoints  GPS reports within the dynamic test time window
     * @return computed statistics; never {@code null}
     */
    public DynamicQualityStats calculate(
        List<RoutePoint> route,
        List<GpsPointWithTelemetry> gpsPoints
    ) {
        return calculate(route, gpsPoints, DEFAULT_THRESHOLD);
    }

    /**
     * Calculate dynamic quality statistics with a custom threshold.
     *
     * @param route      RTK route points (sorted by sequenceNo internally)
     * @param gpsPoints  GPS reports within the dynamic test time window
     * @param threshold  matching threshold in meters
     * @return computed statistics; never {@code null}
     */
    public DynamicQualityStats calculate(
        List<RoutePoint> route,
        List<GpsPointWithTelemetry> gpsPoints,
        double threshold
    ) {
        int routePointCount = route.size();

        // Edge case: empty route or no GPS reports → nothing to match.
        if (routePointCount == 0 || gpsPoints.isEmpty()) {
            return new DynamicQualityStats(
                routePointCount, 0, routePointCount, 0, gpsPoints.size(),
                true, 0.0, 0.0, 0.0, 0.0, 0.0
            );
        }

        // --- sort route by sequenceNo (planned traversal order) ---
        List<RoutePoint> orderedRoute = new ArrayList<>(route);
        orderedRoute.sort((a, b) -> Integer.compare(a.sequenceNo(), b.sequenceNo()));

        int matchedCount = 0;
        int missedCount = 0;
        int ambiguousCount = 0;

        double[] errors = new double[routePointCount];
        Instant[] matchedTimestamps = new Instant[routePointCount];
        boolean[] usedGps = new boolean[gpsPoints.size()];

        int lastMatchedGpsIndex = -1;   // GPS index matched by the previous route point
        boolean prevMatched = false;    // whether the previous route point was matched

        for (int i = 0; i < routePointCount; i++) {
            RoutePoint rp = orderedRoute.get(i);
            double rLat = rp.latitude().doubleValue();
            double rLng = rp.longitude().doubleValue();

            // Find nearest GPS report to this route point.
            int nearestIdx = -1;
            double nearestDist = Double.MAX_VALUE;
            for (int j = 0; j < gpsPoints.size(); j++) {
                GpsPointWithTelemetry gp = gpsPoints.get(j);
                double d = haversine(rLat, rLng,
                    gp.latitude().doubleValue(), gp.longitude().doubleValue());
                if (d < nearestDist) {
                    nearestDist = d;
                    nearestIdx = j;
                }
            }

            if (nearestDist <= threshold) {
                errors[matchedCount] = nearestDist;
                matchedTimestamps[matchedCount] = gpsPoints.get(nearestIdx).recordedAt();
                usedGps[nearestIdx] = true;
                matchedCount++;

                // Ambiguity: the previous route point matched the same GPS report,
                // so this shared report is attributed to the earlier sequence.
                if (prevMatched && nearestIdx == lastMatchedGpsIndex) {
                    ambiguousCount++;
                }

                lastMatchedGpsIndex = nearestIdx;
                prevMatched = true;
            } else {
                missedCount++;
                prevMatched = false;
            }
        }

        // --- transit: GPS reports not consumed by any route match ---
        int transitCount = 0;
        for (boolean used : usedGps) {
            if (!used) transitCount++;
        }

        boolean inOrder = isMonotonicNonDecreasing(matchedTimestamps, matchedCount);
        double coverage = (double) matchedCount / routePointCount * 100.0;

        // --- error distribution across matched points ---
        double[] sortedErrors = Arrays.copyOf(errors, matchedCount);
        Arrays.sort(sortedErrors);

        double meanError = matchedCount == 0
            ? 0.0
            : Arrays.stream(sortedErrors).average().orElse(0.0);
        double maxError = matchedCount == 0
            ? 0.0
            : sortedErrors[matchedCount - 1];
        double p50 = matchedCount >= 5
            ? percentile(sortedErrors, 50)
            : maxError;
        double p95 = matchedCount >= 20
            ? percentile(sortedErrors, 95)
            : maxError;

        return new DynamicQualityStats(
            routePointCount, matchedCount, missedCount, ambiguousCount, transitCount,
            inOrder, coverage, meanError, p50, p95, maxError
        );
    }

    // ------------------------------------------------------------------
    // Monotonic check — non-decreasing timestamps by route order
    // ------------------------------------------------------------------

    private boolean isMonotonicNonDecreasing(Instant[] timestamps, int count) {
        for (int i = 1; i < count; i++) {
            if (timestamps[i].isBefore(timestamps[i - 1])) {
                return false;
            }
        }
        return true;
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
    // Haversine distance (independent copy, no coupling to GpsQualityCalculator)
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
