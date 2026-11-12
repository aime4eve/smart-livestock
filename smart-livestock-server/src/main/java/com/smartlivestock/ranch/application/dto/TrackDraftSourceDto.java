package com.smartlivestock.ranch.application.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * Response of POST /farms/{farmId}/fences/track-draft/source: the merged,
 * stride-sampled track points (ascending by recordedAt, capped at ~5000)
 * plus the raw counts behind the stride estimate. {@code truncated} is true
 * when sampling actually dropped points ({@code sampledStride} > 1).
 */
public record TrackDraftSourceDto(
        List<Point> points,
        long totalRaw,
        List<DeviceRaw> perDevice,
        boolean truncated,
        long sampledStride
) {
    /**
     * One track point. {@code accuracyM} is null when the gps_logs row has
     * no accuracy — the client treats null as trusted (0), no faked value.
     */
    public record Point(
            BigDecimal lat,
            BigDecimal lng,
            Double accuracyM,
            Instant recordedAt
    ) {
    }

    /** Raw (pre-sampling) point count of one device in the requested window. */
    public record DeviceRaw(
            Long deviceId,
            long raw
    ) {
    }
}
