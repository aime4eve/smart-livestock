package com.smartlivestock.licensing.domain;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Stored offline license record ({@code deployment_licenses}).
 * <p>
 * The aggregate keeps the verbatim raw license text ({@code rawLicense}) so
 * the periodic state machine can always re-derive the runtime state from the
 * signed payload itself (self-healing against manual DB edits). Record status
 * ({@link LicenseRecordStatus}) is import bookkeeping and never conflated with
 * {@link LicenseRuntimeStatus}.
 */
public class DeploymentLicense {

    private Long id;
    private UUID licenseId;
    /** Tenant this record belongs to (the importing tenant, i.e. audit anchor). */
    private Long tenantId;
    private UUID installationId;
    private String fingerprintHash;
    private String keyId;
    private LicenseType licenseType;
    private String tier;
    private String effectiveTier;
    private Instant issuedAt;
    private Instant expiresAt;
    private String payloadSha256;
    private String rawLicense;
    private LicenseRecordStatus status;
    private Instant acceptedAt;
    private Instant lastValidatedAt;
    private LicenseValidationOutcome lastResult;
    private String lastErrorCode;
    private UUID replacesLicenseId;

    /** No-arg constructor for JPA/mapper use. */
    public DeploymentLicense() {
    }

    private DeploymentLicense(UUID licenseId, Long tenantId, LicensePayload payload,
                              String rawLicense, LicenseRecordStatus status, Instant now) {
        this.licenseId = licenseId;
        this.tenantId = tenantId;
        this.installationId = payload.getInstallationId();
        this.fingerprintHash = payload.getFingerprintHash();
        this.keyId = payload.getKeyId();
        this.licenseType = payload.getLicenseType();
        this.tier = payload.getTier();
        this.effectiveTier = payload.getEffectiveTier();
        this.issuedAt = payload.getIssuedAt();
        this.expiresAt = payload.getExpiresAt();
        this.rawLicense = rawLicense;
        this.status = status;
        this.replacesLicenseId = payload.getReplacesLicenseId();
        if (status == LicenseRecordStatus.CURRENT) {
            this.acceptedAt = now;
            this.lastValidatedAt = now;
            this.lastResult = LicenseValidationOutcome.VALID;
        } else {
            this.acceptedAt = null;
            this.lastValidatedAt = now;
            this.lastResult = LicenseValidationOutcome.INVALID;
        }
    }

    /**
     * Record an accepted license as the tenant's CURRENT license.
     *
     * @param payload           verified payload of the license
     * @param tenantId          importing tenant (audit anchor; equals payload tenant)
     * @param rawLicense        verbatim raw envelope text (never re-serialized)
     * @param replacedLicenseId license superseded by this one ({@code null} for first import);
     *                          the payload-declared {@code replacesLicenseId} wins when present
     * @param now               acceptance timestamp
     */
    public static DeploymentLicense accept(LicensePayload payload, Long tenantId,
                                           String rawLicense, UUID replacedLicenseId, Instant now) {
        DeploymentLicense license = new DeploymentLicense(
                payload.getLicenseId(), tenantId, payload, rawLicense,
                LicenseRecordStatus.CURRENT, now);
        license.payloadSha256 = payloadSha256Of(rawLicense);
        if (license.replacesLicenseId == null) {
            license.replacesLicenseId = replacedLicenseId;
        }
        return license;
    }

    /**
     * Record a cryptographically verifiable but refused license (binding
     * mismatch, expired, quota exceeded) for audit purposes.
     */
    public static DeploymentLicense rejected(LicensePayload payload, Long tenantId,
                                             String rawLicense, String errorCode, Instant now) {
        DeploymentLicense license = new DeploymentLicense(
                payload.getLicenseId(), tenantId, payload, rawLicense,
                LicenseRecordStatus.REJECTED, now);
        license.payloadSha256 = payloadSha256Of(rawLicense);
        license.lastResult = LicenseValidationOutcome.INVALID;
        license.lastErrorCode = errorCode;
        return license;
    }

    /** Mark this record as superseded by a newly accepted license. */
    public void markReplaced() {
        this.status = LicenseRecordStatus.REPLACED;
    }

    /** Record the outcome of a periodic re-validation of the stored raw license. */
    public void markValidated(Instant at, LicenseValidationOutcome result, String errorCode) {
        this.lastValidatedAt = at;
        this.lastResult = result;
        this.lastErrorCode = errorCode;
    }

    public boolean isCurrent() {
        return status == LicenseRecordStatus.CURRENT;
    }

    // ── Getters / setters (setters for JPA mapper round-trip) ────────

    public Long getId() { return id; }

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

    public LicenseType getLicenseType() { return licenseType; }

    public void setLicenseType(LicenseType licenseType) { this.licenseType = licenseType; }

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

    public LicenseRecordStatus getStatus() { return status; }

    public void setStatus(LicenseRecordStatus status) { this.status = status; }

    public Instant getAcceptedAt() { return acceptedAt; }

    public void setAcceptedAt(Instant acceptedAt) { this.acceptedAt = acceptedAt; }

    public Instant getLastValidatedAt() { return lastValidatedAt; }

    public void setLastValidatedAt(Instant lastValidatedAt) { this.lastValidatedAt = lastValidatedAt; }

    public LicenseValidationOutcome getLastResult() { return lastResult; }

    public void setLastResult(LicenseValidationOutcome lastResult) { this.lastResult = lastResult; }

    public String getLastErrorCode() { return lastErrorCode; }

    public void setLastErrorCode(String lastErrorCode) { this.lastErrorCode = lastErrorCode; }

    public UUID getReplacesLicenseId() { return replacesLicenseId; }

    public void setReplacesLicenseId(UUID replacesLicenseId) { this.replacesLicenseId = replacesLicenseId; }

    // ── Helpers ──────────────────────────────────────────────────────

    /**
     * The payload sha256 declared by the envelope is authoritative; we parse it
     * from the raw text instead of re-hashing so tampering is detectable by
     * re-validation rather than hidden by a recomputed digest.
     */
    private static String payloadSha256Of(String rawLicense) {
        try {
            LicenseEnvelope envelope = LicenseEnvelope.parse(rawLicense);
            return envelope.getPayloadSha256();
        } catch (Exception e) {
            // Accepted licenses are always parseable; defensive fallback keeps
            // rejected-record persistence robust.
            return null;
        }
    }

    @Override
    public boolean equals(Object o) {
        return o instanceof DeploymentLicense other
                && licenseId != null && licenseId.equals(other.licenseId);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(licenseId);
    }
}
