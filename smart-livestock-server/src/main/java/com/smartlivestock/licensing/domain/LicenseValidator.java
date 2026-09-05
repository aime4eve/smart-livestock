package com.smartlivestock.licensing.domain;

import java.time.Instant;

/**
 * Domain service contract for validating an offline license envelope against
 * an expected deployment binding at a point in time (design sections 3/9).
 * <p>
 * Implementations (infrastructure) must run the full pipeline:
 * format/keyId/public-key resolution, SHA-256 payload digest comparison,
 * Ed25519 signature verification, binding comparison and time-window checks.
 * Rejections are returned as {@link LicenseValidationResult} carrying the
 * mapped {@link com.smartlivestock.shared.common.ErrorCode}.
 */
public interface LicenseValidator {

    /**
     * Validate a license envelope.
     *
     * @param envelope    parsed license envelope (structure already validated)
     * @param binding     expected tenant/installation/fingerprint binding
     * @param now         validation time source
     * @return success with the payload, or failure with the mapped error code
     */
    LicenseValidationResult validate(LicenseEnvelope envelope, LicenseBinding binding, Instant now);
}
