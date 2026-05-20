package com.smartlivestock.commerce.domain.repository;

import com.smartlivestock.commerce.domain.model.Subscription;

import java.util.Optional;

public interface SubscriptionRepository {
    Optional<Subscription> findByTenantId(Long tenantId);
    Subscription save(Subscription subscription);
}
