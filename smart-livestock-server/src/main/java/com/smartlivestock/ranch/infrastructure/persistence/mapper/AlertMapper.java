package com.smartlivestock.ranch.infrastructure.persistence.mapper;

import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.infrastructure.persistence.entity.AlertJpaEntity;

public final class AlertMapper {

    private AlertMapper() {}

    public static AlertJpaEntity toJpaEntity(Alert alert) {
        AlertJpaEntity jpa = new AlertJpaEntity();
        jpa.setId(alert.getId());
        jpa.setFarmId(alert.getFarmId());
        jpa.setLivestockId(alert.getLivestockId());
        jpa.setFenceId(alert.getFenceId());
        jpa.setType(alert.getType().name());
        jpa.setStatus(alert.getStatus().name());
        jpa.setSeverity(alert.getSeverity().name());
        jpa.setMessage(alert.getMessage());
        jpa.setAcknowledgedBy(alert.getAcknowledgedBy());
        jpa.setAcknowledgedAt(alert.getAcknowledgedAt());
        jpa.setHandledBy(alert.getHandledBy());
        jpa.setHandledAt(alert.getHandledAt());
        return jpa;
    }

    public static Alert toDomain(AlertJpaEntity jpa) {
        Alert alert = new Alert();
        alert.setId(jpa.getId());
        alert.setFarmId(jpa.getFarmId());
        alert.setLivestockId(jpa.getLivestockId());
        alert.setFenceId(jpa.getFenceId());
        alert.setType(AlertType.valueOf(jpa.getType()));
        alert.setStatus(AlertStatus.valueOf(jpa.getStatus()));
        alert.setSeverity(Severity.valueOf(jpa.getSeverity()));
        alert.setMessage(jpa.getMessage());
        // Acknowledged/handled fields are set via domain methods,
        // but for reconstitution we need to set them directly.
        // Since the domain model has setters for these, we use them.
        alert.reconstituteAcknowledgement(jpa.getAcknowledgedBy(), jpa.getAcknowledgedAt());
        alert.reconstituteHandled(jpa.getHandledBy(), jpa.getHandledAt());
        return alert;
    }
}
