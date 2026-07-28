package com.smartlivestock.iot.domain.service;

import com.smartlivestock.iot.domain.model.QualityGrade;
import com.smartlivestock.iot.domain.port.dto.LineQualityStats;

import java.util.Arrays;
import java.util.List;

/**
 * Pure domain service for LINE tests (NIX-68, spec §5): shortest distance
 * from a device point to the standard track polyline, statistics aggregation
 * and grading. No time alignment — point timestamps only select the window,
 * they never enter the deviation math (the essential difference from
 * TRAJECTORY).
 * <p>
 * Distance math uses an equirectangular local projection centered on the
 * device point: x = (lng - P.lng) * cos(P.lat) * 111320,
 * y = (lat - P.lat) * 110540. For ranch-scale lines (&lt; a few km) this
 * deviates from haversine by &lt;0.1% and is far cheaper than per-segment
 * haversine. No IO dependencies — safe to unit-test in isolation.
 */
public class TrackLineCalculator {

    private static final double METERS_PER_DEG_LAT = 110_540.0;
    private static final double METERS_PER_DEG_LNG = 111_320.0;
    private static final double EARTH_RADIUS_METERS = 6_371_000.0;

    /** One vertex of the standard track polyline. */
    public record LinePoint(double latitude, double longitude) {}

    /**
     * Shortest distance of one device point to the polyline, plus the index
     * of the segment where the minimum was found (first minimum wins,
     * deterministic).
     */
    public record NearestDeviation(double deviationMeters, int segmentNo) {}

    /**
     * Shortest distance of point P to the whole polyline (spec §5.1).
     *
     * @param line standard track points after consecutive-duplicate removal
     * @throws IllegalArgumentException when the line has fewer than 2 points
     */
    public NearestDeviation nearestDeviation(double lat, double lng, List<LinePoint> line) {
        if (line == null || line.size() < 2) {
            throw new IllegalArgumentException("standard track line needs at least 2 points");
        }
        double best = Double.MAX_VALUE;
        int bestSegment = 0;
        for (int i = 0; i < line.size() - 1; i++) {
            LinePoint a = line.get(i);
            LinePoint b = line.get(i + 1);
            double d = pointToSegmentMeters(lat, lng, a.latitude(), a.longitude(),
                    b.latitude(), b.longitude());
            if (d < best) {
                best = d;
                bestSegment = i;
            }
        }
        return new NearestDeviation(best, bestSegment);
    }

    /**
     * Distance from P to segment AB in meters, on the equirectangular local
     * projection centered at P (perpendicular foot inside the segment →
     * perpendicular distance, otherwise the nearer endpoint).
     */
    public double pointToSegmentMeters(double pLat, double pLng,
                                       double aLat, double aLng,
                                       double bLat, double bLng) {
        double cosLat = Math.cos(Math.toRadians(pLat));
        // P is the local origin; project A and B into the local plane
        double ax = (aLng - pLng) * cosLat * METERS_PER_DEG_LNG;
        double ay = (aLat - pLat) * METERS_PER_DEG_LAT;
        double bx = (bLng - pLng) * cosLat * METERS_PER_DEG_LNG;
        double by = (bLat - pLat) * METERS_PER_DEG_LAT;

        double dx = bx - ax;
        double dy = by - ay;
        double segLenSq = dx * dx + dy * dy;
        if (segLenSq == 0.0) {
            // Degenerate segment (A == B): distance to the endpoint
            return Math.hypot(ax, ay);
        }
        // Projection parameter of the foot of P(0,0) onto AB, clamped to [0,1]
        double t = -(ax * dx + ay * dy) / segLenSq;
        t = Math.max(0.0, Math.min(1.0, t));
        double footX = ax + t * dx;
        double footY = ay + t * dy;
        return Math.hypot(footX, footY);
    }

    /**
     * Aggregate per-point deviations into statistics (spec §5.2). Percentile
     * uses the same linear interpolation and degenerate rules as
     * {@code TrajectoryPairingService}: p50 falls back to max below 5 samples,
     * p95 below 20.
     */
    public LineQualityStats aggregate(List<Double> deviations) {
        int n = deviations.size();
        if (n == 0) {
            return new LineQualityStats(0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
        }
        double[] sorted = deviations.stream().mapToDouble(Double::doubleValue).toArray();
        Arrays.sort(sorted);

        double mean = Arrays.stream(sorted).average().orElse(0.0);
        double max = sorted[n - 1];
        double p50 = n >= 5 ? percentile(sorted, 50) : max;
        double p95 = n >= 20 ? percentile(sorted, 95) : max;

        return new LineQualityStats(n, mean, p50, p95, max,
                withinPct(sorted, 15.0), withinPct(sorted, 25.0), withinPct(sorted, 40.0));
    }

    /**
     * LINE grade (spec D10): same p95 bands as the trajectory grade, but no
     * pair-rate constraint (LINE samples need no pairing).
     */
    public QualityGrade determineLineGrade(LineQualityStats stats) {
        if (stats.sampleCount() >= 10 && stats.p95() <= 15.0) {
            return QualityGrade.EXCELLENT;
        }
        if (stats.sampleCount() >= 6 && stats.p95() <= 25.0) {
            return QualityGrade.USABLE;
        }
        if (stats.sampleCount() >= 4 && stats.p95() <= 40.0) {
            return QualityGrade.MARGINAL;
        }
        return QualityGrade.UNAVAILABLE;
    }

    /**
     * Total length of the polyline in meters: haversine summed over
     * consecutive segments (spec D6 — always computed from coordinates).
     */
    public double polylineLengthMeters(List<LinePoint> line) {
        if (line == null || line.size() < 2) {
            return 0.0;
        }
        double total = 0.0;
        for (int i = 0; i < line.size() - 1; i++) {
            LinePoint a = line.get(i);
            LinePoint b = line.get(i + 1);
            total += haversineMeters(a.latitude(), a.longitude(), b.latitude(), b.longitude());
        }
        return total;
    }

    /** Haversine distance (independent copy, same convention as the other calculators). */
    public static double haversineMeters(double lat1, double lng1, double lat2, double lng2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
            + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
            * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return EARTH_RADIUS_METERS * c;
    }

    private static double withinPct(double[] sorted, double thresholdMeters) {
        int within = 0;
        for (double d : sorted) {
            if (d <= thresholdMeters) within++;
        }
        return (double) within / sorted.length * 100.0;
    }

    /** Linear interpolation on a sorted ascending array (TrajectoryPairingService convention). */
    private static double percentile(double[] sorted, int pct) {
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
}
