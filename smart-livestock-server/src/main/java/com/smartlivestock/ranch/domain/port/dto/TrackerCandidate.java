package com.smartlivestock.ranch.domain.port.dto;

import java.time.Instant;

/**
 * Tracker device eligible for the fence track-draft wizard: a TRACKER-type
 * device with an active installation on one of the farm's livestock.
 * {@code lastFixAt} is the latest gps_logs recorded_at inside the lookback
 * window (null when the device produced no point in the window);
 * {@code pointCount} is the row count in the same window.
 * <p>
 * Field mapping note: {@code name} carries the iot Device's deviceCode (the
 * device model has no separate display name) and {@code earTag} carries the
 * ranch Livestock's livestockCode (the animal's ear-tag identifier).
 */
public record TrackerCandidate(
        Long deviceId,
        String name,
        String earTag,
        Instant lastFixAt,
        long pointCount
) {
}
