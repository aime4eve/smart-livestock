package com.smartlivestock.licensing.application.port;

import java.util.Optional;

/**
 * Read-only port into the licensing context (design §10, NIX-184) implemented
 * by the commerce context via {@code CommerceQuotaLicenseAdapter}.
 * <p>
 * Direction of dependency: commerce reads licensing (never the reverse).
 * The adapter returns a quota only for an ONPREM deployment whose current
 * license is VALID and whose payload actually carries the feature key;
 * otherwise it returns empty and callers fall back to their own gating.
 */
public interface LicenseQuotaPort {

    /**
     * License-declared quota for the feature key.
     *
     * @return the quota, or empty when no license quota applies (HOSTED mode,
     *         no valid current license, or payload lacks the key)
     */
    Optional<Integer> findLicenseQuota(Long tenantId, String featureKey);
}
