package com.smartlivestock.iot.domain.model;

import java.time.Instant;

/**
 * Global coverage totals over the diagnostic window (NIX-219 F8).
 * centroidLat/centroidLng are the all-frame weighted centroid.
 */
public record CoverageTierTotals(
        long totalFrames,
        long stableFrames,
        long weakFrames,
        long edgeFrames,
        Double centroidLat,
        Double centroidLng,
        Instant earliestFrame) {
}
