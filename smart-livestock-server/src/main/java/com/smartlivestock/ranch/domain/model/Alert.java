package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;

import java.time.Instant;

/**
 * Alert aggregate root representing a ranch alert (fence breach, temperature abnormal, etc.)
 * <p>
 * Status machine: PENDING → ACKNOWLEDGED → HANDLED → ARCHIVED
 */
public class Alert extends AggregateRoot {

    private Long farmId;
    private Long livestockId;
    private Long fenceId;
    private AlertType type;
    private AlertStatus status;
    private Severity severity;
    private String message;
    private Long acknowledgedBy;
    private Instant acknowledgedAt;
    private Long handledBy;
    private Instant handledAt;

    public Alert() {
        this.status = AlertStatus.PENDING;
    }

    public Alert(Long farmId, Long livestockId, Long fenceId,
                 AlertType type, Severity severity, String message) {
        this.farmId = farmId;
        this.livestockId = livestockId;
        this.fenceId = fenceId;
        this.type = type;
        this.severity = severity;
        this.message = message;
        this.status = AlertStatus.PENDING;
    }

    /**
     * Acknowledge this alert. Only PENDING alerts can be acknowledged.
     *
     * @param userId the user performing the acknowledgment
     * @throws ApiException (STATE_CONFLICT) if alert is not in PENDING status
     */
    public void acknowledge(Long userId) {
        if (status != AlertStatus.PENDING) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                "Alert must be in pending status to acknowledge, current: " + status);
        }
        this.status = AlertStatus.ACKNOWLEDGED;
        this.acknowledgedBy = userId;
        this.acknowledgedAt = Instant.now();
    }

    /**
     * Handle this alert. Only ACKNOWLEDGED alerts can be handled.
     *
     * @param userId the user performing the handling
     * @throws ApiException (STATE_CONFLICT) if alert is not in ACKNOWLEDGED status
     */
    public void handle(Long userId) {
        if (status != AlertStatus.ACKNOWLEDGED) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                "Alert must be in acknowledged status to handle, current: " + status);
        }
        this.status = AlertStatus.HANDLED;
        this.handledBy = userId;
        this.handledAt = Instant.now();
    }

    /**
     * Archive this alert. Only HANDLED alerts can be archived.
     *
     * @param userId the user performing the archival
     * @throws ApiException (STATE_CONFLICT) if alert is not in HANDLED status
     */
    public void archive(Long userId) {
        if (status != AlertStatus.HANDLED) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                "Alert must be in handled status to archive, current: " + status);
        }
        this.status = AlertStatus.ARCHIVED;
    }

    // --- Getters and Setters ---

    public Long getFarmId() { return farmId; }
    public void setFarmId(Long farmId) { this.farmId = farmId; }

    public Long getLivestockId() { return livestockId; }
    public void setLivestockId(Long livestockId) { this.livestockId = livestockId; }

    public Long getFenceId() { return fenceId; }
    public void setFenceId(Long fenceId) { this.fenceId = fenceId; }

    public AlertType getType() { return type; }
    public void setType(AlertType type) { this.type = type; }

    public AlertStatus getStatus() { return status; }
    public void setStatus(AlertStatus status) { this.status = status; }

    public Severity getSeverity() { return severity; }
    public void setSeverity(Severity severity) { this.severity = severity; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public Long getAcknowledgedBy() { return acknowledgedBy; }

    public Instant getAcknowledgedAt() { return acknowledgedAt; }

    public Long getHandledBy() { return handledBy; }

    public Instant getHandledAt() { return handledAt; }
}
