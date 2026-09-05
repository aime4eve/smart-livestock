package com.smartlivestock.licensing.domain;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * On-premise host registration of a tenant ({@code deployment_installations}).
 * <p>
 * The {@code installationId} is generated once at first enrollment and never
 * changes; licenses bind to it. The fingerprint is refreshed on re-enrollment
 * (e.g. after a host migration the operator re-enrolls, but the installation
 * identity stays stable so the old installation id remains auditable).
 */
public class DeploymentInstallation {

    private Long id;
    private Long tenantId;
    private UUID installationId;
    /** SHA-256 hex digest of the current host fingerprint. */
    private String fingerprintHash;
    private Instant createdAt;
    private Instant updatedAt;

    /** No-arg constructor for JPA/mapper use. */
    public DeploymentInstallation() {
    }

    private DeploymentInstallation(Long tenantId, UUID installationId, String fingerprintHash,
                                   Instant now) {
        this.tenantId = tenantId;
        this.installationId = installationId;
        this.fingerprintHash = fingerprintHash;
        this.createdAt = now;
        this.updatedAt = now;
    }

    /**
     * Create a new installation for the tenant; the installationId is randomly
     * generated at first enrollment and stays stable afterwards.
     */
    public static DeploymentInstallation create(Long tenantId, HostFingerprint fingerprint,
                                                Instant now) {
        Objects.requireNonNull(tenantId, "tenantId");
        Objects.requireNonNull(fingerprint, "fingerprint");
        return new DeploymentInstallation(tenantId, UUID.randomUUID(), fingerprint.getValue(), now);
    }

    /** Refresh the stored fingerprint (host migration / re-enrollment). */
    public void refreshFingerprint(HostFingerprint fingerprint, Instant now) {
        Objects.requireNonNull(fingerprint, "fingerprint");
        this.fingerprintHash = fingerprint.getValue();
        this.updatedAt = now;
    }

    public Long getId() { return id; }

    public void setId(Long id) { this.id = id; }

    public Long getTenantId() { return tenantId; }

    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    /** Restore immutable identity fields on persistence round-trip (mapper use only). */
    public void restoreIdentity(UUID installationId, String fingerprintHash) {
        this.installationId = installationId;
        this.fingerprintHash = fingerprintHash;
    }

    public UUID getInstallationId() { return installationId; }

    public String getFingerprintHash() { return fingerprintHash; }

    public Instant getCreatedAt() { return createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }

    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
