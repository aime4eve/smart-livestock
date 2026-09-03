package com.smartlivestock.licensing.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/** JPA mapping of {@code deployment_license_events} (design §6). */
@Entity
@Table(name = "deployment_license_events")
public class DeploymentLicenseEventJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "license_id")
    private UUID licenseId;

    @Column(name = "tenant_id")
    private Long tenantId;

    @Column(name = "event_type", nullable = false, length = 50)
    private String eventType;

    @Column(name = "result", length = 20)
    private String result;

    @Column(name = "error_code", length = 50)
    private String errorCode;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "details", columnDefinition = "jsonb")
    private Map<String, Object> details;

    @Column(name = "operator_user_id")
    private Long operatorUserId;

    @Column(name = "occurred_at", nullable = false)
    private Instant occurredAt;

    public Long getId() { return id; }

    public UUID getLicenseId() { return licenseId; }

    public void setLicenseId(UUID licenseId) { this.licenseId = licenseId; }

    public Long getTenantId() { return tenantId; }

    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    public String getEventType() { return eventType; }

    public void setEventType(String eventType) { this.eventType = eventType; }

    public String getResult() { return result; }

    public void setResult(String result) { this.result = result; }

    public String getErrorCode() { return errorCode; }

    public void setErrorCode(String errorCode) { this.errorCode = errorCode; }

    public Map<String, Object> getDetails() { return details; }

    public void setDetails(Map<String, Object> details) { this.details = details; }

    public Long getOperatorUserId() { return operatorUserId; }

    public void setOperatorUserId(Long operatorUserId) { this.operatorUserId = operatorUserId; }

    public Instant getOccurredAt() { return occurredAt; }

    public void setOccurredAt(Instant occurredAt) { this.occurredAt = occurredAt; }
}
