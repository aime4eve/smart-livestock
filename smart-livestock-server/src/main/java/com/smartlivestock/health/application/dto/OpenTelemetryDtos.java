package com.smartlivestock.health.application.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * DTOs for the Open API telemetry endpoints (NIX-323).
 * Read-only projections of the raw telemetry logs; every series paginates
 * independently.
 */
public final class OpenTelemetryDtos {

    private OpenTelemetryDtos() {}

    public record SeriesPage<T>(List<T> items, int page, int pageSize, long total) {}

    public record TemperatureReading(
            BigDecimal temperature, BigDecimal baselineTemp, BigDecimal delta,
            String source, Instant recordedAt) {}

    public record MotilityReading(
            BigDecimal frequency, BigDecimal intensity, Long rawCounter, Long counterDelta,
            String source, Instant recordedAt) {}

    public record ActivityReading(
            Integer stepCount, BigDecimal activityIndex, BigDecimal distanceMeters,
            String source, Instant recordedAt) {}

    public record LivestockTelemetry(
            Long livestockId, Long deviceId, Instant windowFrom, Instant windowTo,
            SeriesPage<TemperatureReading> temperature,
            SeriesPage<MotilityReading> motility,
            SeriesPage<ActivityReading> activity) {}

    public record DeviceHealthTelemetry(
            Long deviceId, Instant windowFrom, Instant windowTo,
            SeriesPage<TemperatureReading> temperature,
            SeriesPage<MotilityReading> motility) {}
}
