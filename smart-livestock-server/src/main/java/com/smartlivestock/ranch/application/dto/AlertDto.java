package com.smartlivestock.ranch.application.dto;

import com.smartlivestock.ranch.domain.model.Alert;

import java.time.Instant;

public record AlertDto(
        Long id,
        Long farmId,
        Long livestockId,
        Long fenceId,
        String type,
        String status,
        String severity,
        String message,
        boolean read,
        String resolvedType,
        Instant resolvedAt,
        // Legacy fields retained for backward compatibility
        Long acknowledgedBy,
        Instant acknowledgedAt,
        Long handledBy,
        Instant handledAt
) {
    public static AlertDto from(Alert alert) {
        return new AlertDto(
                alert.getId(),
                alert.getFarmId(),
                alert.getLivestockId(),
                alert.getFenceId(),
                alert.getType().name(),
                alert.getStatus().name(),
                alert.getSeverity().name(),
                alert.getMessage(),
                false, // read status is populated separately via alert_read_status join
                alert.getResolvedType(),
                alert.getResolvedAt(),
                alert.getAcknowledgedBy(),
                alert.getAcknowledgedAt(),
                alert.getHandledBy(),
                alert.getHandledAt()
        );
    }

    public AlertDto withRead(boolean read) {
        return new AlertDto(
                id, farmId, livestockId, fenceId, type, status, severity, message,
                read, resolvedType, resolvedAt,
                acknowledgedBy, acknowledgedAt, handledBy, handledAt
        );
    }
}
