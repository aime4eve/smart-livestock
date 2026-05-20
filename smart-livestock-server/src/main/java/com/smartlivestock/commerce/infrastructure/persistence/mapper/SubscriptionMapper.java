package com.smartlivestock.commerce.infrastructure.persistence.mapper;

import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionStatus;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.commerce.infrastructure.persistence.entity.SubscriptionJpaEntity;

public final class SubscriptionMapper {

    private SubscriptionMapper() {}

    public static SubscriptionJpaEntity toJpaEntity(Subscription domain) {
        SubscriptionJpaEntity jpa = new SubscriptionJpaEntity();
        jpa.setId(domain.getId());
        jpa.setTenantId(domain.getTenantId());
        jpa.setTier(domain.getTier().name().toLowerCase());
        jpa.setBillingModel(domain.getBillingModel());
        jpa.setStatus(domain.getStatus().name().toLowerCase());
        jpa.setBillingCycle(domain.getBillingCycle());
        jpa.setStartedAt(domain.getStartedAt());
        jpa.setExpiresAt(domain.getExpiresAt());
        jpa.setTrialEndsAt(domain.getTrialEndsAt());
        jpa.setCancelledAt(domain.getCancelledAt());
        return jpa;
    }

    public static void updateEntity(SubscriptionJpaEntity existing, Subscription domain) {
        existing.setTier(domain.getTier().name().toLowerCase());
        existing.setBillingModel(domain.getBillingModel());
        existing.setStatus(domain.getStatus().name().toLowerCase());
        existing.setBillingCycle(domain.getBillingCycle());
        existing.setStartedAt(domain.getStartedAt());
        existing.setExpiresAt(domain.getExpiresAt());
        existing.setTrialEndsAt(domain.getTrialEndsAt());
        existing.setCancelledAt(domain.getCancelledAt());
    }

    public static Subscription toDomain(SubscriptionJpaEntity jpa) {
        Subscription domain = new Subscription();
        domain.setId(jpa.getId());
        domain.setTenantId(jpa.getTenantId());
        domain.setTier(SubscriptionTier.valueOf(jpa.getTier().toUpperCase()));
        domain.setBillingModel(jpa.getBillingModel());
        domain.setStatus(SubscriptionStatus.valueOf(jpa.getStatus().toUpperCase()));
        domain.setBillingCycle(jpa.getBillingCycle());
        domain.setStartedAt(jpa.getStartedAt());
        domain.setExpiresAt(jpa.getExpiresAt());
        domain.setTrialEndsAt(jpa.getTrialEndsAt());
        domain.setCancelledAt(jpa.getCancelledAt());
        return domain;
    }
}
