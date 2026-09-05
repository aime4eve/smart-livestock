package com.smartlivestock.licensing.domain;

import com.smartlivestock.shared.common.ErrorCode;

import java.util.Objects;
import java.util.Optional;

/**
 * Outcome of a full license validation (signature, binding, time window).
 * <p>
 * Validation never throws for business-level rejection: failures are reported
 * with the corresponding {@link ErrorCode} so the caller (state machine in T4)
 * can map them onto {@link LicenseRuntimeStatus} transitions.
 */
public final class LicenseValidationResult {

    private final LicensePayload payload;
    private final ErrorCode errorCode;
    private final String message;

    private LicenseValidationResult(LicensePayload payload, ErrorCode errorCode, String message) {
        this.payload = payload;
        this.errorCode = errorCode;
        this.message = message;
    }

    public static LicenseValidationResult success(LicensePayload payload) {
        return new LicenseValidationResult(Objects.requireNonNull(payload, "payload"), null, null);
    }

    /** Failure without a parsed payload (e.g. cryptographic rejection). */
    public static LicenseValidationResult failure(ErrorCode errorCode, String message) {
        return new LicenseValidationResult(null, Objects.requireNonNull(errorCode, "errorCode"), message);
    }

    /**
     * Failure that still carries the parsed payload (e.g. binding mismatch or
     * expired license) so the caller can record license metadata against the
     * failed validation.
     */
    public static LicenseValidationResult failure(LicensePayload payload, ErrorCode errorCode,
                                                  String message) {
        return new LicenseValidationResult(Objects.requireNonNull(payload, "payload"),
                Objects.requireNonNull(errorCode, "errorCode"), message);
    }

    /** True when signature, binding and time window all passed. */
    public boolean isValid() {
        return errorCode == null;
    }

    /** Parsed payload when cryptographic verification passed; {@code null} otherwise. */
    public LicensePayload getPayload() {
        return payload;
    }

    /** Failure reason; empty on success. */
    public Optional<ErrorCode> getErrorCode() {
        return Optional.ofNullable(errorCode);
    }

    public Optional<String> getMessage() {
        return Optional.ofNullable(message);
    }

    @Override
    public String toString() {
        return isValid() ? "LicenseValidationResult[VALID " + payload.getLicenseId() + "]"
                : "LicenseValidationResult[" + errorCode + ": " + message + "]";
    }
}
