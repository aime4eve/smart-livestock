package com.smartlivestock.iot.application.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * DTOs for the device-dimension Open API telemetry endpoint (NIX-323).
 * Raw frame-level telemetry of a device.
 */
public final class OpenDeviceTelemetryDtos {

    private OpenDeviceTelemetryDtos() {}

    public record SeriesPage<T>(List<T> items, int page, int pageSize, long total) {}

    public record DeviceFrameReading(
            Instant reportTime,
            Integer batteryLevel,
            Integer rssi,
            BigDecimal snr,
            Integer stepNumber,
            Long gastricMotility,
            BigDecimal accelXG,
            BigDecimal accelYG,
            BigDecimal accelZG,
            BigDecimal accelMagnitudeG,
            BigDecimal latitude,
            BigDecimal longitude,
            String source) {}

    public record DeviceTelemetry(
            Long deviceId,
            String deviceCode,
            Instant windowFrom,
            Instant windowTo,
            SeriesPage<DeviceFrameReading> frames) {}
}
