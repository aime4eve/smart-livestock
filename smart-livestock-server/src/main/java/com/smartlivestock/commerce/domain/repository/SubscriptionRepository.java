package com.smartlivestock.commerce.domain.repository;

import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionStatus;

import java.util.List;
import java.util.Optional;

public interface SubscriptionRepository {
    Optional<Subscription> findByTenantId(Long tenantId);
    List<Subscription> findByStatus(SubscriptionStatus status);
    Subscription save(Subscription subscription);
}
