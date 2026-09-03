package com.smartlivestock.licensing.domain;

/**
 * Type of an issued offline license file (".sllicense").
 * <p>
 * REPLACEMENT is intentionally not a runtime type: it is an issuance reason
 * recorded via {@code replacesLicenseId} on the payload (design section 3).
 */
public enum LicenseType {
    /** Time-boxed trial license issued for pilot deployments. */
    TRIAL,
    /** Paid/renewal license; the only type allowed to restore an expired trial. */
    ACTIVE
}
