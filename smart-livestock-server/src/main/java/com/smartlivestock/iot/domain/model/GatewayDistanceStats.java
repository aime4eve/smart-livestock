package com.smartlivestock.iot.domain.model;

import java.time.Instant;

/**
 * Per-gateway communication distance statistics for one device (NIX-219 F2).
 * Distances are frame-level Haversine distances between the device GPS fix and
 * the position of the gateway that received the frame (valid frames only).
 */
public record GatewayDistanceStats(
        String gatewayId,
        Instant lastSeen,
        long frames,
        double lastDistanceMeters,
        double medianMeters,
        double p95Meters
) {
}
