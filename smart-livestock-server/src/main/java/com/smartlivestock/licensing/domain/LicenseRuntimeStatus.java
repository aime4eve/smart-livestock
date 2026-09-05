package com.smartlivestock.licensing.domain;

/**
 * Runtime status of the deployment license on an on-premise installation
 * (design section 9 state machine).
 */
public enum LicenseRuntimeStatus {
    /** No usable license imported yet; business APIs stay blocked. */
    PENDING_ACTIVATION,
    /** Current license passed all validation checks (signature, binding, time). */
    VALID,
    /** Current license is past its expiresAt; subscription degrades to FREE/BASIC. */
    EXPIRED,
    /** Protective hold (e.g. time rollback detected); only license management stays usable. */
    SUSPENDED
}
