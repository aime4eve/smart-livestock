package com.smartlivestock.licensing.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

/** JPA mapping of {@code deployment_installations} (design §6). */
@Entity
@Table(name = "deployment_installations")
public class DeploymentInstallationJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false, unique = true)
    private Long tenantId;

    @Column(name = "installation_id", nullable = false, unique = true)
    private UUID installationId;

    @Column(name = "fingerprint_hash", length = 64)
    private String fingerprintHash;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    protected void onCreate() {
        Instant now = Instant.now();
        if (createdAt == null) {
            createdAt = now;
        }
        updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = Instant.now();
    }

    public Long getId() { return id; }
    /** Used by the mapper to re-attach the surrogate key on merge. */
    public void setId(Long id) { this.id = id; }

    public Long getTenantId() { return tenantId; }

    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    public UUID getInstallationId() { return installationId; }

    public void setInstallationId(UUID installationId) { this.installationId = installationId; }

    public String getFingerprintHash() { return fingerprintHash; }

    public void setFingerprintHash(String fingerprintHash) { this.fingerprintHash = fingerprintHash; }

    public Instant getCreatedAt() { return createdAt; }

    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }

    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
