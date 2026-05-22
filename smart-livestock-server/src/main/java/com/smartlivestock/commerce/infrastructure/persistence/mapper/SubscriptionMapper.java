package com.smartlivestock.commerce.infrastructure.persistence.mapper;

import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionStatus;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.commerce.infrastructure.persistence.entity.SubscriptionJpaEntity;

import static com.smartlivestock.commerce.infrastructure.persistence.mapper.EnumConverters.fromDb;
import static com.smartlivestock.commerce.infrastructure.persistence.mapper.EnumConverters.toDb;

public final class SubscriptionMapper {

    private SubscriptionMapper() {}

    public static SubscriptionJpaEntity toJpaEntity(Subscription domain) {
        SubscriptionJpaEntity jpa = new SubscriptionJpaEntity();
        jpa.setId(domain.getId());
        jpa.setTenantId(domain.getTenantId());
        jpa.setTier(toDb(domain.getTier()));
        jpa.setBillingModel(domain.getBillingModel());
        jpa.setStatus(toDb(domain.getStatus()));
        jpa.setBillingCycle(domain.getBillingCycle());
        jpa.setStartedAt(domain.getStartedAt());
        jpa.setExpiresAt(domain.getExpiresAt());
        jpa.setTrialEndsAt(domain.getTrialEndsAt());
        jpa.setCancelledAt(domain.getCancelledAt());
        return jpa;
    }

    public static void updateEntity(SubscriptionJpaEntity existing, Subscription domain) {
        existing.setTier(toDb(domain.getTier()));
        existing.setBillingModel(domain.getBillingModel());
        existing.setStatus(toDb(domain.getStatus()));
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
        domain.setTier(fromDb(jpa.getTier(), SubscriptionTier.class));
        domain.setBillingModel(jpa.getBillingModel());
        domain.setStatus(fromDb(jpa.getStatus(), SubscriptionStatus.class));
        domain.setBillingCycle(jpa.getBillingCycle());
        domain.setStartedAt(jpa.getStartedAt());
        domain.setExpiresAt(jpa.getExpiresAt());
        domain.setTrialEndsAt(jpa.getTrialEndsAt());
        domain.setCancelledAt(jpa.getCancelledAt());
        return domain;
    }
}
