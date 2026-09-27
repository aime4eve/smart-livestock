package com.smartlivestock.ranch.application.signal;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public final class SignalDtos {
    private SignalDtos() {}

    public record HealthMetricSignal(
            Double value,
            String unit,
            String status,
            Instant recordedAt,
            Long ageSeconds,
            String freshness,
            String source
    ) {}

    public record HealthSignal(
            String status,
            List<String> activeAlertTypes,
            HealthMetricsSignal metrics
    ) {}

    public record HealthMetricsSignal(
            HealthMetricSignal rumenTemperature,
            HealthMetricSignal rumenMotility
    ) {}

    public record AiSignal(
            String status,
            Double score,
            String anomalyType,
            Instant assessedAt
    ) {}

    public record FenceSignal(
            String status,
            List<String> activeAlertTypes
    ) {}

    public record DeviceSignal(
            String status,
            List<String> faultTypes,
            int deviceCount
    ) {}

    public record AlertSummarySignal(int activeCount, int unreadCount) {}

    public record LivestockSignal(
            Long livestockId,
            String livestockCode,
            Long revision,
            HealthSignal health,
            AiSignal ai,
            FenceSignal fence,
            DeviceSignal device,
            AlertSummarySignal alerts
    ) {}

    public record LivestockSignalResponse(
            Long farmId,
            Long statusRevision,
            boolean changed,
            List<LivestockSignal> items
    ) {}

    public record MapFenceSignal(
            Long fenceId,
            String name,
            Long revision,
            String status,
            List<String> activeAlertTypes,
            int livestockCount,
            List<List<BigDecimal>> geometry
    ) {}

    public record PositionSignal(
            Long livestockId,
            Long revision,
            BigDecimal lat,
            BigDecimal lng,
            Instant recordedAt,
            Long ageSeconds,
            String freshness,
            String source
    ) {}

    public record MapSignalResponse(
            Long farmId,
            Long statusRevision,
            Long positionRevision,
            Long fenceGeometryRevision,
            String cursor,
            boolean changed,
            boolean statusChanged,
            boolean positionChanged,
            boolean fenceGeometryChanged,
            List<MapFenceSignal> fences,
            List<LivestockSignal> livestockSignals,
            List<PositionSignal> positionUpdates
    ) {}
}
