package com.smartlivestock.commerce.domain.repository;

import com.smartlivestock.commerce.domain.model.SubscriptionService;
import com.smartlivestock.commerce.domain.model.SubscriptionServiceStatus;

import java.util.List;
import java.util.Optional;

public interface SubscriptionServiceRepository {
    Optional<SubscriptionService> findByTenantId(Long tenantId);
    Optional<SubscriptionService> findById(Long id);
    List<SubscriptionService> findByStatus(SubscriptionServiceStatus status);
    SubscriptionService save(SubscriptionService subscriptionService);
}
