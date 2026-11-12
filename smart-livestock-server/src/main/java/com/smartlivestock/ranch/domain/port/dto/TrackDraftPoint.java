package com.smartlivestock.ranch.domain.port.dto;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * One sampled GPS track point for the fence track-draft flow (NIX fence
 * from device track). Ranch-side projection of an iot gps_logs row, so the
 * ranch context never references iot types. {@code accuracyM} stays null
 * when the source row has no accuracy — clients treat null as trusted.
 */
public record TrackDraftPoint(
        BigDecimal lat,
        BigDecimal lng,
        Double accuracyM,
        Instant recordedAt
) {
}
