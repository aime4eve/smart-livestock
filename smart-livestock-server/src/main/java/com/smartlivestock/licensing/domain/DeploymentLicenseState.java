package com.smartlivestock.licensing.domain;

import java.time.Instant;
import java.util.UUID;

/**
 * Per-tenant runtime licensing state ({@code deployment_license_states}).
 * <p>
 * Holds the tamper guard bookkeeping:
 * <ul>
 *   <li>{@code maxObservedAt} is monotonic (only ever advanced); it is the
 *       anchor for the time-rollback protection.</li>
 *   <li>{@code protectionReason} stays set while the runtime is SUSPENDED and
 *       is cleared on recovery.</li>
 * </ul>
 * The runtime status itself is always re-derived from the stored raw license
 * of the CURRENT record — never trusted from this row.
 */
public class DeploymentLicenseState {

    /** Protection reason when a system time rollback was detected. */
    public static final String PROTECTION_TIME_ROLLBACK = "LICENSE_TIME_ROLLBACK";
    /** Protection reason when the stored raw license fails cryptographic validation. */
    public static final String PROTECTION_LICENSE_INVALID = "LICENSE_INVALID";
    /** Protection reason when the stored raw license no longer matches this host. */
    public static final String PROTECTION_BINDING_MISMATCH = "LICENSE_BINDING_MISMATCH";

    private Long tenantId; // primary key
    private UUID currentLicenseId;
    private LicenseRuntimeStatus runtimeStatus;
    private Instant maxObservedAt;
    private Instant lastValidatedAt;
    private String lastErrorCode;
    private String protectionReason;
    private Instant updatedAt;

    /** No-arg constructor for JPA/mapper use. */
    public DeploymentLicenseState() {
    }

    private DeploymentLicenseState(Long tenantId, LicenseRuntimeStatus runtimeStatus, Instant now) {
        this.tenantId = tenantId;
        this.runtimeStatus = runtimeStatus;
        this.updatedAt = now;
    }

    /** Initial state for a tenant before any validation ran. */
    public static DeploymentLicenseState initial(Long tenantId, Instant now) {
        return new DeploymentLicenseState(tenantId, LicenseRuntimeStatus.PENDING_ACTIVATION, now);
    }

    /**
     * Advance the monotonic time anchor; {@code maxObservedAt} only ever moves
     * forward (design §9 step 2).
     */
    public void advanceTime(Instant now) {
        if (maxObservedAt == null || now.isAfter(maxObservedAt)) {
            maxObservedAt = now;
        }
    }

    /**
     * True when the system clock rolled back beyond the tolerance
     * ({@code now + tolerance < maxObservedAt}, design §9 step 3).
     */
    public boolean isTimeRollback(Instant now, java.time.Duration tolerance) {
        return maxObservedAt != null && now.plus(tolerance).isBefore(maxObservedAt);
    }

    /** True when the runtime currently sits in a protective hold. */
    public boolean isSuspended() {
        return runtimeStatus == LicenseRuntimeStatus.SUSPENDED;
    }

    /**
     * Transition the runtime state.
     *
     * @param status           new runtime status
     * @param currentLicenseId current license reference ({@code null} clears it)
     * @param at               validation timestamp
     * @param errorCode        failing error code name ({@code null} when healthy)
     * @param protectionReason protective hold reason ({@code null} clears it)
     */
    public void transitionTo(LicenseRuntimeStatus status, UUID currentLicenseId, Instant at,
                             String errorCode, String protectionReason) {
        this.runtimeStatus = status;
        this.currentLicenseId = currentLicenseId;
        this.lastValidatedAt = at;
        this.lastErrorCode = errorCode;
        this.protectionReason = protectionReason;
        this.updatedAt = at;
    }

    public Long getTenantId() { return tenantId; }

    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    public UUID getCurrentLicenseId() { return currentLicenseId; }

    public void setCurrentLicenseId(UUID currentLicenseId) { this.currentLicenseId = currentLicenseId; }

    public LicenseRuntimeStatus getRuntimeStatus() { return runtimeStatus; }

    public void setRuntimeStatus(LicenseRuntimeStatus runtimeStatus) { this.runtimeStatus = runtimeStatus; }

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
