package com.smartlivestock.commerce.application.service;

public interface UsageResolver {
    String featureKey();
    int resolve(Long tenantId, Long farmId);
}
