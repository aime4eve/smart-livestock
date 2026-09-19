package com.smartlivestock.iot.domain.model;

/**
 * One 100m-grid cell of the coverage diagnostics (NIX-219 F8):
 * aggregated frame count and average RSSI, with the cell centroid.
 */
public record CoverageCellRow(
        int gridY,
        int gridX,
        long frames,
        double avgRssi,
        double centroidLat,
        double centroidLng) {
}
