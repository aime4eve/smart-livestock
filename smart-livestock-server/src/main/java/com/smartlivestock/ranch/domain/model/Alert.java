package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;

import java.time.Instant;

/**
 * Alert aggregate root representing a ranch alert (fence breach, temperature abnormal, etc.)
 * <p>
 * Notification center model: ACTIVE → DISMISSED (manual) or AUTO_RESOLVED (automatic).
 * Read status is tracked per-user via alert_read_status table.
 */
public class Alert extends AggregateRoot {

    private Long farmId;
    private Long livestockId;
    private Long fenceId;
    private Long deviceId;
    private AlertType type;
    private AlertStatus status;
    private Severity severity;
    private String message;
    private String resolvedType;   // "AUTO" / "MANUAL_DISMISS"
    private Instant resolvedAt;
    private String source = "RULE"; // RULE / AI

    // Legacy fields retained for backward compatibility during migration window
    private Long acknowledgedBy;
    private Instant acknowledgedAt;
    private Long handledBy;
    private Instant handledAt;

    public Alert() {
        this.status = AlertStatus.ACTIVE;
    }

    public Alert(Long farmId, Long livestockId, Long fenceId,
                 AlertType type, Severity severity, String message) {
        this.farmId = farmId;
        this.livestockId = livestockId;
        this.fenceId = fenceId;
        this.type = type;
        this.severity = severity;
        this.message = message;
        this.status = AlertStatus.ACTIVE;
    }

    public Alert(Long farmId, Long livestockId, Long fenceId, Long deviceId,
                 AlertType type, Severity severity, String message) {
        this.farmId = farmId;
        this.livestockId = livestockId;
        this.fenceId = fenceId;
        this.deviceId = deviceId;
        this.type = type;
        this.severity = severity;
        this.message = message;
        this.status = AlertStatus.ACTIVE;
    }

    /**
     * Dismiss this alert (manual). Only ACTIVE alerts can be dismissed.
     *
     * @param userId the user performing the dismissal
     * @throws ApiException (STATE_CONFLICT) if alert is not in ACTIVE status
     */
    public void dismiss(Long userId) {
        if (status != AlertStatus.ACTIVE) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                "Alert must be in ACTIVE status to dismiss, current: " + status);
        }
        this.status = AlertStatus.DISMISSED;
        this.resolvedType = "MANUAL_DISMISS";
        this.resolvedAt = Instant.now();
        // Legacy compatibility
        this.handledBy = userId;
        this.handledAt = this.resolvedAt;
    }

    /**
     * Auto-resolve this alert. Idempotent — no-op if already resolved.
     */
    public void autoResolve() {
        if (status != AlertStatus.ACTIVE) {
            return; // idempotent
        }
        this.status = AlertStatus.AUTO_RESOLVED;
        this.resolvedType = "AUTO";
        this.resolvedAt = Instant.now();
    }

    // --- Legacy compatibility methods (redirect to new model) ---

    /**
     * @deprecated Use dismiss(userId) instead.
     */
    @Deprecated
    public void acknowledge(Long userId) {
        // Legacy: PENDING → ACKNOWLEDGED mapped to ACTIVE (read status tracked separately)
        // No-op on the alert itself — read status is in alert_read_status table
    }

    /**
     * @deprecated Use dismiss(userId) instead.
     */
    @Deprecated
    public void handle(Long userId) {
        dismiss(userId);
    }

    /**
     * @deprecated Use autoResolve() instead.
     */
    @Deprecated
    public void archive(Long userId) {
        autoResolve();
    }

    // --- Reconstitution ---

    public void reconstituteResolved(String resolvedType, Instant resolvedAt) {
        this.resolvedType = resolvedType;
        this.resolvedAt = resolvedAt;
    }

    public void reconstituteAcknowledgement(Long acknowledgedBy, Instant acknowledgedAt) {
        this.acknowledgedBy = acknowledgedBy;
        this.acknowledgedAt = acknowledgedAt;
    }

    public void reconstituteHandled(Long handledBy, Instant handledAt) {
        this.handledBy = handledBy;
        this.handledAt = handledAt;
    }

    // --- Getters and Setters ---

    public Long getFarmId() { return farmId; }
    public void setFarmId(Long farmId) { this.farmId = farmId; }

    public Long getLivestockId() { return livestockId; }
    public void setLivestockId(Long livestockId) { this.livestockId = livestockId; }

    public Long getFenceId() { return fenceId; }
    public void setFenceId(Long fenceId) { this.fenceId = fenceId; }

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }

    public AlertType getType() { return type; }
    public void setType(AlertType type) { this.type = type; }

    public AlertStatus getStatus() { return status; }
    public void setStatus(AlertStatus status) { this.status = status; }

    public Severity getSeverity() { return severity; }
    public void setSeverity(Severity severity) { this.severity = severity; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public String getResolvedType() { return resolvedType; }
    public void setResolvedType(String resolvedType) { this.resolvedType = resolvedType; }

    public Instant getResolvedAt() { return resolvedAt; }
    public void setResolvedAt(Instant resolvedAt) { this.resolvedAt = resolvedAt; }

    public Long getAcknowledgedBy() { return acknowledgedBy; }
    public void setAcknowledgedBy(Long acknowledgedBy) { this.acknowledgedBy = acknowledgedBy; }

    public Instant getAcknowledgedAt() { return acknowledgedAt; }
    public void setAcknowledgedAt(Instant acknowledgedAt) { this.acknowledgedAt = acknowledgedAt; }

    public Long getHandledBy() { return handledBy; }
    public void setHandledBy(Long handledBy) { this.handledBy = handledBy; }

    public Instant getHandledAt() { return handledAt; }
    public void setHandledAt(Instant handledAt) { this.handledAt = handledAt; }

    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }
}
