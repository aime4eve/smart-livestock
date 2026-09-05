package com.smartlivestock.licensing.domain;

/**
 * Outcome label recorded on a deployment license record
 * ({@code deployment_licenses.last_result}) after an import or a periodic
 * re-validation of the stored raw license.
 */
public enum LicenseValidationOutcome {
    /** Full validation (signature, binding, time window) passed. */
    VALID,
    /** License is past its expiresAt. */
    EXPIRED,
    /** Cryptographic/structural validation failed (tampered or corrupt raw license). */
    INVALID,
    /** License is bound to a different tenant/installation/host fingerprint. */
    BINDING_MISMATCH,
    /** Import refused because current resource usage exceeds the license quotas. */
    QUOTA_EXCEEDED
}
