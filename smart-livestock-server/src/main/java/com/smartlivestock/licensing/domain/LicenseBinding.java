package com.smartlivestock.licensing.domain;

import java.util.Objects;
import java.util.UUID;

/**
 * Expected deployment binding of a license: the tenant, installation and host
 * fingerprint a presented license must match (design section 9, step 6).
 */
public final class LicenseBinding {

    private final Long tenantId;
    private final UUID installationId;
    private final HostFingerprint fingerprint;

    public LicenseBinding(Long tenantId, UUID installationId, HostFingerprint fingerprint) {
        this.tenantId = Objects.requireNonNull(tenantId, "tenantId");
        this.installationId = Objects.requireNonNull(installationId, "installationId");
        this.fingerprint = Objects.requireNonNull(fingerprint, "fingerprint");
    }

    public Long getTenantId() { return tenantId; }

    public UUID getInstallationId() { return installationId; }

    public HostFingerprint getFingerprint() { return fingerprint; }

    @Override
    public boolean equals(Object o) {
        return o instanceof LicenseBinding other
                && tenantId.equals(other.tenantId)
                && installationId.equals(other.installationId)
                && fingerprint.equals(other.fingerprint);
    }

    @Override
    public int hashCode() {
        return Objects.hash(tenantId, installationId, fingerprint);
    }

    @Override
    public String toString() {
        return "LicenseBinding[tenantId=" + tenantId + ", installationId=" + installationId + "]";
    }
}
