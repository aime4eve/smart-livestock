package com.smartlivestock.health.domain.port;

/**
 * ACL port for Health context to query subscription/feature-gate status.
 * <p>
 * Implemented in shared or identity infrastructure layer to avoid
 * Health directly depending on Commerce.
 */
public interface HealthSubscriptionPort {

    /**
     * Get the retention days for a feature key based on the current tenant's subscription tier.
     * Falls back to a default if the tenant has no subscription or the feature key is not found.
     */
    int getRetentionDays(String featureKey);

    /**
     * Check whether the current tenant has access to the given feature key.
     */
    boolean hasFeature(String featureKey);

    /**
     * Explicit-tenant variant of {@link #hasFeature} for threads that carry
     * no TenantContext (schedulers): {@code hasFeature} would silently fall
     * back to the basic tier there and lock every premium gate (NIX-381
     * Task 0 finding 1). Same tier resolution and gate semantics otherwise —
     * a null tenant, a missing or inactive subscription resolves to basic.
     */
    boolean hasFeatureForTenant(Long tenantId, String featureKey);
}
