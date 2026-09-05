package com.smartlivestock.licensing.domain;

/**
 * Audit event types persisted to {@code deployment_license_events}
 * (design section 6/9). Every import attempt and every periodic validation
 * run writes exactly one event.
 */
public enum LicenseEventType {
    /** License import accepted; old CURRENT record (if any) was marked REPLACED. */
    IMPORT_ACCEPTED,
    /** License import rejected; {@code error_code} carries the refusal reason. */
    IMPORT_REJECTED,
    /** Periodic validation passed; runtime status stays/reaches VALID. */
    VALIDATION_PASSED,
    /** Periodic validation found the current license expired; subscription downgraded. */
    VALIDATION_EXPIRED,
    /** Time rollback detected (or signature/binding broke); runtime suspended. */
    VALIDATION_SUSPENDED,
    /** Runtime recovered to VALID after a non-VALID state (self-healing). */
    VALIDATION_RECOVERED,
    /** Periodic validation could not produce a valid state (no current license). */
    VALIDATION_FAILED
}
