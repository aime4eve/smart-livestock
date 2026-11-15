package com.smartlivestock.ranch.domain.service;

import com.smartlivestock.ranch.domain.model.GpsCoordinate;

import java.util.List;

/**
 * NIX-200: fence area in hectares from the stored WGS-84 vertices, using
 * the SAME planar approximation as the client's track-draft area
 * (equirectangular projection around the ring centroid + shoelace) so the
 * editor form and every read surface display one identical value.
 */
public final class FenceAreaCalculator {

    private static final double M_PER_DEG_LAT = 111320.0;

    private FenceAreaCalculator() {
    }

    /** Hectares; 0 for rings with fewer than 3 vertices. */
    public static double areaHectares(List<GpsCoordinate> ring) {
        return areaM2(ring) / 10000.0;
    }

    /** Square meters via centroid equirectangular projection + shoelace. */
    public static double areaM2(List<GpsCoordinate> ring) {
        if (ring == null || ring.size() < 3) return 0.0;
        double lat0 = 0;
        double lng0 = 0;
        for (GpsCoordinate p : ring) {
            lat0 += p.latitude().doubleValue();
            lng0 += p.longitude().doubleValue();
        }
        lat0 /= ring.size();
        lng0 /= ring.size();
        double mPerDegLng = M_PER_DEG_LAT * Math.cos(lat0 * Math.PI / 180.0);
        double area = 0;
        int n = ring.size();
        for (int i = 0; i < n; i++) {
            GpsCoordinate a = ring.get(i);
            GpsCoordinate b = ring.get((i + 1) % n);
            double ax = (a.longitude().doubleValue() - lng0) * mPerDegLng;
            double ay = (a.latitude().doubleValue() - lat0) * M_PER_DEG_LAT;
            double bx = (b.longitude().doubleValue() - lng0) * mPerDegLng;
            double by = (b.latitude().doubleValue() - lat0) * M_PER_DEG_LAT;
            area += ax * by - bx * ay;
        }
        return Math.abs(area) / 2;
    }
}
