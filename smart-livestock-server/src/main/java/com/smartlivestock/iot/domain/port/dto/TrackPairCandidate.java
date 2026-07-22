package com.smartlivestock.iot.domain.port.dto;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * A gps_logs report offered as a pairing candidate for an RTK track point.
 *
 * @param gpsLogId    gps_logs primary key
 * @param latitude    reported latitude
 * @param longitude   reported longitude
 * @param recordedAt  report timestamp (same clock baseline as the track point)
 */
public record TrackPairCandidate(
    Long gpsLogId,
    BigDecimal latitude,
    BigDecimal longitude,
    Instant recordedAt
) {}
