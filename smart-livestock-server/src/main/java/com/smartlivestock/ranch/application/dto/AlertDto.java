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
                alert.getAcknowledgedBy(),
                alert.getAcknowledgedAt(),
                alert.getHandledBy(),
                alert.getHandledAt()
        );
    }
}
