package com.smartlivestock.iot.interfaces.admin.dto;

import java.math.BigDecimal;

/**
 * One point of a standard track polyline (NIX-68, spec §7.4): the test-time
 * point-list snapshot served by /tests/{id}/line-report/track, also reused
 * for candidate previews and device tracks in the line comparison.
 */
public record LineTrackPointDto(
    int sequenceNo,
    BigDecimal lng,
    BigDecimal lat
) {}
