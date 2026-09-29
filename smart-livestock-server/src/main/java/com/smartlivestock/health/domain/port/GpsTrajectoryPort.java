package com.smartlivestock.health.domain.port;

import java.time.Instant;
import java.util.List;

/**
 * ACL port for the Health context to read GPS trajectories owned by the
 * IoT context (livestock -> active installation -> device -> gps_logs).
 */
public interface GpsTrajectoryPort {

    /**
     * GPS points of the livestock's active GPS-capable device (tracker
     * preferred, ear tag fallback) recorded inside [{@code from}, {@code to}].
     * Returns an empty list when the livestock has no active bound device or
     * no points in the window.
     */
    List<GpsPoint> findTrajectory(Long livestockId, Instant from, Instant to);

    /** A single trajectory fix; coordinates are decimal degrees (WGS84). */
    record GpsPoint(Instant recordedAt, double latitude, double longitude) {}
}
