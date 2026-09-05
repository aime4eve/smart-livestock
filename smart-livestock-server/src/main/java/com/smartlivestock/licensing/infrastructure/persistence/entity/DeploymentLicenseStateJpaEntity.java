package com.smartlivestock.licensing.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

/** JPA mapping of {@code deployment_license_states} (design §6, PK = tenant_id). */
@Entity
@Table(name = "deployment_license_states")
public class DeploymentLicenseStateJpaEntity {

    @Id
    @Column(name = "tenant_id")
    private Long tenantId;

    @Column(name = "current_license_id")
    private UUID currentLicenseId;

    @Column(name = "runtime_status", length = 30)
    private String runtimeStatus;

    @Column(name = "max_observed_at")
    private Instant maxObservedAt;

    @Column(name = "last_validated_at")
    private Instant lastValidatedAt;

    @Column(name = "last_error_code", length = 50)
    private String lastErrorCode;

    @Column(name = "protection_reason", length = 50)
    private String protectionReason;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    protected void onCreate() {
        if (updatedAt == null) {
            updatedAt = Instant.now();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = Instant.now();
    }

    public Long getTenantId() { return tenantId; }

    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    public UUID getCurrentLicenseId() { return currentLicenseId; }

    public void setCurrentLicenseId(UUID currentLicenseId) { this.currentLicenseId = currentLicenseId; }

    public String getRuntimeStatus() { return runtimeStatus; }

    public void setRuntimeStatus(String runtimeStatus) { this.runtimeStatus = runtimeStatus; }

    public Instant getMaxObservedAt() { return maxObservedAt; }

    public void setMaxObservedAt(Instant maxObservedAt) { this.maxObservedAt = maxObservedAt; }

    public Instant getLastValidatedAt() { return lastValidatedAt; }

    public void setLastValidatedAt(Instant lastValidatedAt) { this.lastValidatedAt = lastValidatedAt; }

    public String getLastErrorCode() { return lastErrorCode; }

    public void setLastErrorCode(String lastErrorCode) { this.lastErrorCode = lastErrorCode; }

    public String getProtectionReason() { return protectionReason; }

    public void setProtectionReason(String protectionReason) { this.protectionReason = protectionReason; }

    public Instant getUpdatedAt() { return updatedAt; }

    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
