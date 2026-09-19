package com.smartlivestock.iot.domain.model;

/**
 * Centroid of weak-signal frames (RSSI < -95 dBm) over the window (F8 direction test).
 */
public record WeakCentroidRow(Double centroidLat, Double centroidLng, long frames) {
}
