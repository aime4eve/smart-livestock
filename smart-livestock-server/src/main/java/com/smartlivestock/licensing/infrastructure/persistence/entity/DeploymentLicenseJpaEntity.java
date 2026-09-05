package com.smartlivestock.licensing.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

/** JPA mapping of {@code deployment_licenses} (design §6). */
@Entity
@Table(name = "deployment_licenses")
public class DeploymentLicenseJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "license_id", nullable = false, unique = true)
    private UUID licenseId;

    @Column(name = "tenant_id")
    private Long tenantId;

    @Column(name = "installation_id")
    private UUID installationId;

    @Column(name = "fingerprint_hash", length = 64)
    private String fingerprintHash;

    @Column(name = "key_id", length = 64)
    private String keyId;

    @Column(name = "license_type", length = 20)
    private String licenseType;

    @Column(name = "tier", length = 20)
    private String tier;

    @Column(name = "effective_tier", length = 20)
    private String effectiveTier;

    @Column(name = "issued_at")
    private Instant issuedAt;

    @Column(name = "expires_at")
    private Instant expiresAt;

    @Column(name = "payload_sha256", length = 64)
    private String payloadSha256;

    @Column(name = "raw_license", columnDefinition = "text")
    private String rawLicense;

    @Column(name = "status", nullable = false, length = 30)
    private String status;

    @Column(name = "accepted_at")
    private Instant acceptedAt;

    @Column(name = "last_validated_at")
    private Instant lastValidatedAt;

    @Column(name = "last_result", length = 20)
    private String lastResult;

    @Column(name = "last_error_code", length = 50)
    private String lastErrorCode;

    @Column(name = "replaces_license_id")
    private UUID replacesLicenseId;

    public Long getId() { return id; }
    /** Used by the mapper to re-attach the surrogate key on merge. */
    public void setId(Long id) { this.id = id; }

    public UUID getLicenseId() { return licenseId; }

    public void setLicenseId(UUID licenseId) { this.licenseId = licenseId; }

    public Long getTenantId() { return tenantId; }

    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    public UUID getInstallationId() { return installationId; }

    public void setInstallationId(UUID installationId) { this.installationId = installationId; }

    public String getFingerprintHash() { return fingerprintHash; }

    public void setFingerprintHash(String fingerprintHash) { this.fingerprintHash = fingerprintHash; }

    public String getKeyId() { return keyId; }

    public void setKeyId(String keyId) { this.keyId = keyId; }

    public String getLicenseType() { return licenseType; }

    public void setLicenseType(String licenseType) { this.licenseType = licenseType; }

    public String getTier() { return tier; }

    public void setTier(String tier) { this.tier = tier; }

    public String getEffectiveTier() { return effectiveTier; }

    public void setEffectiveTier(String effectiveTier) { this.effectiveTier = effectiveTier; }

    public Instant getIssuedAt() { return issuedAt; }

    public void setIssuedAt(Instant issuedAt) { this.issuedAt = issuedAt; }

    public Instant getExpiresAt() { return expiresAt; }

    public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }

    public String getPayloadSha256() { return payloadSha256; }

    public void setPayloadSha256(String payloadSha256) { this.payloadSha256 = payloadSha256; }

    public String getRawLicense() { return rawLicense; }

    public void setRawLicense(String rawLicense) { this.rawLicense = rawLicense; }

    public String getStatus() { return status; }

    public void setStatus(String status) { this.status = status; }

    public Instant getAcceptedAt() { return acceptedAt; }

    public void setAcceptedAt(Instant acceptedAt) { this.acceptedAt = acceptedAt; }

    public Instant getLastValidatedAt() { return lastValidatedAt; }

    public void setLastValidatedAt(Instant lastValidatedAt) { this.lastValidatedAt = lastValidatedAt; }

    public String getLastResult() { return lastResult; }

    public void setLastResult(String lastResult) { this.lastResult = lastResult; }

    public String getLastErrorCode() { return lastErrorCode; }

    public void setLastErrorCode(String lastErrorCode) { this.lastErrorCode = lastErrorCode; }

    public UUID getReplacesLicenseId() { return replacesLicenseId; }

    public void setReplacesLicenseId(UUID replacesLicenseId) { this.replacesLicenseId = replacesLicenseId; }
}
