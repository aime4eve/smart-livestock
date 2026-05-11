package com.smartlivestock.ranch.domain.event;

import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.shared.domain.DomainEvent;

/**
 * Domain event fired when an alert transitions to a new status.
 */
public class AlertStatusChangedEvent extends DomainEvent {

    private final Long alertId;
    private final AlertStatus newStatus;

    public AlertStatusChangedEvent(Long alertId, AlertStatus newStatus) {
        this.alertId = alertId;
        this.newStatus = newStatus;
    }

    public Long getAlertId() { return alertId; }
    public AlertStatus getNewStatus() { return newStatus; }
}
