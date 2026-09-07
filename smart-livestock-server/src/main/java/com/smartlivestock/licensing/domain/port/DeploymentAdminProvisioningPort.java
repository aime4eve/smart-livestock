package com.smartlivestock.licensing.domain.port;

/**
 * NIX-191: provisioning of the deployment administrator whose account is
 * born together with the first accepted activation certificate. Implemented
 * by the identity module (ACL adapter) — licensing never touches user tables
 * directly.
 */
public interface DeploymentAdminProvisioningPort {

    /** True when at least one active PLATFORM_ADMIN account exists. */
    boolean hasActivePlatformAdmin();

    /** Id of the single seeded tenant (ONPREM deployments are single-tenant). */
    Long firstTenantId();

    /**
     * Idempotent provisioning: create the platform admin when the phone is
     * unknown, otherwise return the existing account untouched. Returns the
     * account id.
     *
     * @param phone           login phone of the deployment administrator
     * @param bcryptHash      bcrypt hash of the one-time initial password
     * @param mustChangePassword force a password change on first login
     */
    Long provisionAdmin(String phone, String bcryptHash, boolean mustChangePassword);
}
