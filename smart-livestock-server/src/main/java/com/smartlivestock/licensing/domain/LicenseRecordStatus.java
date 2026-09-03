package com.smartlivestock.licensing.domain;

/**
 * Lifecycle status of a stored deployment license record
 * ({@code deployment_licenses.status}).
 * <p>
 * This is the <em>record bookkeeping</em> status of the import history and is
 * deliberately distinct from {@link LicenseRuntimeStatus}, which is the
 * derived runtime state of the whole installation:
 * <ul>
 *   <li>{@link #CURRENT} — the newest accepted license for the tenant. The
 *       record stays CURRENT even after its {@code expiresAt} has passed;
 *       expiry is a runtime state derived from the stored raw license so the
 *       state machine can always re-derive from the raw payload.</li>
 *   <li>{@link #REPLACED} — superseded by a newer accepted license; kept for
 *       audit (data is never deleted).</li>
 *   <li>{@link #REJECTED} — the import was refused (binding mismatch, expired
 *       file, quota precheck failure). Only recorded when the payload could be
 *       verified cryptographically, so the refusal reason is auditable.</li>
 * </ul>
 */
public enum LicenseRecordStatus {
    CURRENT,
    REPLACED,
    REJECTED
}
