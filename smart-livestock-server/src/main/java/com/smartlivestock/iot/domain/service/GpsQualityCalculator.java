package com.smartlivestock.iot.domain.service;

import com.smartlivestock.iot.domain.model.QualityGrade;
import com.smartlivestock.iot.domain.port.dto.GpsPointWithTelemetry;
import com.smartlivestock.iot.domain.port.dto.GpsQualityStats;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * Pure domain service that computes GPS quality statistics from a list of GPS
 * points measured against an RTK ground-truth coordinate.
 * <p>
 * No IO dependencies — safe to unit-test in isolation.
 */
public class GpsQualityCalculator {

    private static final double EARTH_RADIUS_METERS = 6_371_000.0;

    /**
     * Calculate full quality statistics.
     *
     * @param points          raw GPS points (with optional telemetry)
     * @param rtkLatitude     RTK ground-truth latitude
     * @param rtkLongitude    RTK ground-truth longitude
     * @param excludeSuspect  if {@code true}, points with stepNumber > 0 are excluded from stats
     * @return computed statistics; never {@code null}
     */
    public GpsQualityStats calculate(
        List<GpsPointWithTelemetry> points,
        BigDecimal rtkLatitude, BigDecimal rtkLongitude,
        boolean excludeSuspect
    ) {
        int totalPoints = points.size();

        int suspectPoints = (int) points.stream()
            .filter(p -> p.stepNumber() != null && p.stepNumber() > 0)
            .count();

        List<GpsPointWithTelemetry> effective = excludeSuspect
            ? points.stream()
                .filter(p -> p.stepNumber() == null || p.stepNumber() <= 0)
                .toList()
            : points;

        int effectivePoints = effective.size();

        // --- errors (haversine distance to RTK truth) ---
        double[] errors = new double[effectivePoints];
        for (int i = 0; i < effectivePoints; i++) {
            GpsPointWithTelemetry p = effective.get(i);
            errors[i] = haversine(
                rtkLatitude.doubleValue(), rtkLongitude.doubleValue(),
                p.latitude().doubleValue(), p.longitude().doubleValue()
            );
        }
        Arrays.sort(errors);

        // --- basic stats ---
        double meanError = effectivePoints == 0
            ? 0.0
            : Arrays.stream(errors).average().orElse(0.0);
        double maxError = effectivePoints == 0
            ? 0.0
            : errors[effectivePoints - 1];

        // --- percentiles (with degradation rules) ---
        double p50 = effectivePoints >= 5
            ? percentile(errors, 50)
            : maxError;
        double p95 = effectivePoints >= 20
            ? percentile(errors, 95)
            : maxError;
        Double p99 = effectivePoints >= 100
            ? percentile(errors, 99)
            : null;

        // --- jitter diameter ---
        double jitterDiameter = computeJitterDiameter(effective);

        // --- outliers ---
        double outlierThreshold = effectivePoints >= 100
            ? Math.max(Math.max(p99, 3 * p95), 30.0)
            : Math.max(3 * p95, 30.0);

        int outlierCount = 0;
        for (double e : errors) {
            if (e > outlierThreshold) outlierCount++;
        }

        // --- grade ---
        QualityGrade grade = determineGrade(effectivePoints, p95);

        return new GpsQualityStats(
            totalPoints, suspectPoints, effectivePoints,
            meanError, p50, p95, p99, maxError,
            jitterDiameter, outlierCount, grade
        );
    }

    // ------------------------------------------------------------------
    // Percentile — linear interpolation on a sorted array
    // ------------------------------------------------------------------

    /**
     * Linear-interpolation percentile on a <b>sorted ascending</b> array.
     * Index = (pct / 100) * (n - 1).
     */
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
    // Jitter diameter — max pairwise haversine (convex hull for N > 500)
    // ------------------------------------------------------------------

    private double computeJitterDiameter(List<GpsPointWithTelemetry> points) {
        int n = points.size();
        if (n <= 1) return 0.0;

        if (n > 500) {
            List<double[]> hull = convexHull(points);
            return maxPairwiseHaversine(hull);
        }

        // brute-force pairwise
        double max = 0.0;
        for (int i = 0; i < n; i++) {
            double lat1 = points.get(i).latitude().doubleValue();
            double lng1 = points.get(i).longitude().doubleValue();
            for (int j = i + 1; j < n; j++) {
                double d = haversine(lat1, lng1,
                    points.get(j).latitude().doubleValue(),
                    points.get(j).longitude().doubleValue());
                if (d > max) max = d;
            }
        }
        return max;
    }

    /**
     * Andrew's monotone-chain convex hull.
     * Points are represented as {@code [longitude, latitude]} (planar sorting).
     *
     * @return hull vertices as {@code [longitude, latitude]}
     */
    private List<double[]> convexHull(List<GpsPointWithTelemetry> points) {
        int n = points.size();
        double[][] pts = new double[n][];
        for (int i = 0; i < n; i++) {
            pts[i] = new double[]{
                points.get(i).longitude().doubleValue(),
                points.get(i).latitude().doubleValue()
            };
        }
        Arrays.sort(pts, (a, b) ->
            a[0] != b[0] ? Double.compare(a[0], b[0]) : Double.compare(a[1], b[1]));

        if (n <= 2) {
            List<double[]> result = new ArrayList<>(n);
            for (double[] p : pts) result.add(p);
            return result;
        }

        List<double[]> hull = new ArrayList<>(2 * n);

        // Lower hull (left to right)
        for (int i = 0; i < n; i++) {
            while (hull.size() >= 2
                && cross(hull.get(hull.size() - 2), hull.get(hull.size() - 1), pts[i]) <= 0) {
                hull.remove(hull.size() - 1);
            }
            hull.add(pts[i]);
        }

        // Upper hull (right to left)
        int lowerSize = hull.size() + 1;
        for (int i = n - 2; i >= 0; i--) {
            while (hull.size() >= lowerSize
                && cross(hull.get(hull.size() - 2), hull.get(hull.size() - 1), pts[i]) <= 0) {
                hull.remove(hull.size() - 1);
            }
            hull.add(pts[i]);
        }

        hull.remove(hull.size() - 1); // last point == first point
        return hull;
    }

    /** 2-D cross product of OA × OB (z-component). */
    private double cross(double[] o, double[] a, double[] b) {
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0]);
    }

    private double maxPairwiseHaversine(List<double[]> hull) {
        int n = hull.size();
        double max = 0.0;
        for (int i = 0; i < n; i++) {
            // hull[i] = [lng, lat]
            for (int j = i + 1; j < n; j++) {
                double d = haversine(hull.get(i)[1], hull.get(i)[0],
                                     hull.get(j)[1], hull.get(j)[0]);
                if (d > max) max = d;
            }
        }
        return max;
    }

    // ------------------------------------------------------------------
    // Grade determination
    // ------------------------------------------------------------------

    private QualityGrade determineGrade(int effectivePoints, double p95) {
        if (effectivePoints < 10) return QualityGrade.UNAVAILABLE;
        if (p95 <= 15.0 && effectivePoints >= 20) return QualityGrade.EXCELLENT;
        if (p95 <= 25.0 && effectivePoints >= 20) return QualityGrade.USABLE;
        if (p95 <= 40.0 && effectivePoints >= 10) return QualityGrade.MARGINAL;
        return QualityGrade.UNAVAILABLE;
    }

    // ------------------------------------------------------------------
    // Haversine distance
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
