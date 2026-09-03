package com.smartlivestock.licensing.application.port;

/**
 * Tenant-level current resource usage for the quota pre-check performed
 * before a license import is accepted (design §9 step 8 / §10).
 * <p>
 * Implemented in the licensing infrastructure with tenant-granularity counts;
 * the farm-scoped {@code UsageResolver} mechanism in platform/web answers a
 * different question (per-farm usage at request time) and is therefore not
 * reusable here.
 */
public interface LicenseUsagePort {

    /**
     * Current tenant-wide usage count for one of the quota feature keys
     * (livestock_management / fence_management / worker_management /
     * device_management). Unknown feature keys count as zero.
     */
    int countCurrentUsage(Long tenantId, String featureKey);
}
