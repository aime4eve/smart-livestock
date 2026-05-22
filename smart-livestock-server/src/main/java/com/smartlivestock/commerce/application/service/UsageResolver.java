package com.smartlivestock.commerce.application.service;

/**
 * Resolves current usage count for a quota-gated feature at farm granularity.
 */
public interface UsageResolver {
    String featureKey();
    int resolve(Long tenantId, Long farmId);
}
