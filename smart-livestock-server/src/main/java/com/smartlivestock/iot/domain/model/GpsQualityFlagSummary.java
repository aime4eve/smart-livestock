package com.smartlivestock.iot.domain.model;

import java.time.LocalDate;

/**
 * Read model for governance flag metrics (NIX-220 admin endpoint).
 */
public record GpsQualityFlagSummary(
        Long deviceId,
        String ruleName,
        LocalDate day,
        long total,
        long devices
) {
}
