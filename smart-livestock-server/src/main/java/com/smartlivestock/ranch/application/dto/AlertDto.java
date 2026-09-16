package com.smartlivestock.ranch.application.dto;

import com.smartlivestock.ranch.domain.model.Alert;

import java.time.Instant;

public record AlertDto(
        Long id,
        Long farmId,
        Long livestockId,
        Long fenceId,
        Long deviceId,
        String deviceCode,
        String type,
        String status,
        String severity,
        String message,
        Instant occurredAt,
       boolean read,
        String resolvedType,
        Instant resolvedAt,
        // Legacy fields retained for backward compatibility
        Long acknowledgedBy,
        Instant acknowledgedAt,
        Long handledBy,
        Instant handledAt,
        String source
) {
    public static AlertDto from(Alert alert) {
        return from(alert, alert.getMessage());
    }

    public static AlertDto from(Alert alert, String message) {
        return from(alert, message, null);
    }

    /**
     * @param deviceCode resolved device serial for device-originated alerts
     *                   (null when the caller did not enrich, or the alert
     *                   has no deviceId)
     * @param occurredAt alias of the alert's creation time, fed to the
     *                   clients' "occurred at" display
     */
    public static AlertDto from(Alert alert, String message, String deviceCode) {
        return new AlertDto(
                alert.getId(),
                alert.getFarmId(),
                alert.getLivestockId(),
                alert.getFenceId(),
                alert.getDeviceId(),
                deviceCode,
                alert.getType().name(),
                alert.getStatus().name(),
                alert.getSeverity().name(),
                message,
                alert.getCreatedAt(),
                false, // read status is populated separately via alert_read_status join
                alert.getResolvedType(),
                alert.getResolvedAt(),
                alert.getAcknowledgedBy(),
                alert.getAcknowledgedAt(),
                alert.getHandledBy(),
                alert.getHandledAt(),
                alert.getSource()
        );
    }

    public AlertDto withRead(boolean read) {
        return new AlertDto(
                id, farmId, livestockId, fenceId, deviceId, deviceCode,
                type, status, severity, message, occurredAt,
                read, resolvedType, resolvedAt,
                acknowledgedBy, acknowledgedAt, handledBy, handledAt, source
        );
    }
}
