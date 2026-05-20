package com.smartlivestock.commerce.domain.repository;

import com.smartlivestock.commerce.domain.model.SubscriptionService;

import java.util.Optional;

public interface SubscriptionServiceRepository {
    Optional<SubscriptionService> findByTenantId(Long tenantId);
    Optional<SubscriptionService> findById(Long id);
    SubscriptionService save(SubscriptionService subscriptionService);
}
