package com.smartlivestock.licensing.domain;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * Immutable audit entry persisted to {@code deployment_license_events}
 * (design section 6). One row per import attempt and per periodic validation.
 */
public class DeploymentLicenseEvent {

    private Long id;
    /** License this event refers to ({@code null} when the envelope was unreadable). */
    private UUID licenseId;
    private Long tenantId;
    private LicenseEventType eventType;
    /** Outcome label ({@link LicenseValidationOutcome} name or ACCEPTED/REJECTED). */
    private String result;
    /** {@link com.smartlivestock.shared.common.ErrorCode} name when rejected/failed. */
    private String errorCode;
    private Map<String, Object> details;
    private Long operatorUserId;
    private Instant occurredAt;

    /** No-arg constructor for JPA/mapper use. */
    public DeploymentLicenseEvent() {
    }

    private DeploymentLicenseEvent(UUID licenseId, Long tenantId, LicenseEventType eventType,
                                   String result, String errorCode, Map<String, Object> details,
                                   Long operatorUserId, Instant occurredAt) {
        this.licenseId = licenseId;
        this.tenantId = tenantId;
        this.eventType = eventType;
        this.result = result;
        this.errorCode = errorCode;
        this.details = details;
        this.operatorUserId = operatorUserId;
        this.occurredAt = occurredAt;
    }

    public static DeploymentLicenseEvent of(UUID licenseId, Long tenantId, LicenseEventType eventType,
                                            String result, String errorCode,
                                            Map<String, Object> details, Long operatorUserId,
                                            Instant occurredAt) {
        return new DeploymentLicenseEvent(licenseId, tenantId, eventType, result, errorCode,
                details, operatorUserId, occurredAt);
    }

    public Long getId() { return id; }

    public void setId(Long id) { this.id = id; }

    public UUID getLicenseId() { return licenseId; }

    public Long getTenantId() { return tenantId; }

    public LicenseEventType getEventType() { return eventType; }

    public String getResult() { return result; }

    public String getErrorCode() { return errorCode; }

    public Map<String, Object> getDetails() { return details; }

    public Long getOperatorUserId() { return operatorUserId; }

    public Instant getOccurredAt() { return occurredAt; }

    public void setOccurredAt(Instant occurredAt) { this.occurredAt = occurredAt; }
}
