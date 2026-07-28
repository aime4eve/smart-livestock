package com.smartlivestock.iot.interfaces.admin.dto;

import java.time.Instant;

/**
 * One device with gps_logs data inside the requested window
 * (NIX-68, spec §7.3 GET /line-checks/devices).
 */
public record LineCheckDeviceDto(
    String deviceCode,
    Long deviceId,
    int pointCount,
    Instant firstRecordedAt,
    Instant lastRecordedAt
) {}
