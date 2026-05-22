package com.smartlivestock.commerce.infrastructure.persistence.mapper;

import com.smartlivestock.commerce.domain.model.SubscriptionService;
import com.smartlivestock.commerce.domain.model.SubscriptionServiceStatus;
import com.smartlivestock.commerce.infrastructure.persistence.entity.SubscriptionServiceJpaEntity;

import static com.smartlivestock.commerce.infrastructure.persistence.mapper.EnumConverters.fromDb;
import static com.smartlivestock.commerce.infrastructure.persistence.mapper.EnumConverters.toDb;

public final class SubscriptionServiceMapper {

    private SubscriptionServiceMapper() {}

    public static SubscriptionServiceJpaEntity toJpaEntity(SubscriptionService domain) {
        SubscriptionServiceJpaEntity jpa = new SubscriptionServiceJpaEntity();
        jpa.setId(domain.getId());
        jpa.setTenantId(domain.getTenantId());
        jpa.setServiceName(domain.getServiceName());
        jpa.setServiceKeyPrefix(domain.getServiceKeyPrefix());
        jpa.setServiceKeyHash(domain.getServiceKeyHash());
        jpa.setEffectiveTier(domain.getEffectiveTier());
        jpa.setDeviceQuota(domain.getDeviceQuota());
        jpa.setStatus(toDb(domain.getStatus()));
        jpa.setLastHeartbeatAt(domain.getLastHeartbeatAt());
        jpa.setGraceEndsAt(domain.getGraceEndsAt());
        jpa.setStartedAt(domain.getStartedAt());
        jpa.setExpiresAt(domain.getExpiresAt());
        jpa.setHeartbeatIntervalHrs(domain.getHeartbeatIntervalHrs());
        jpa.setGracePeriodDays(domain.getGracePeriodDays());
        return jpa;
    }

    public static void updateEntity(SubscriptionServiceJpaEntity existing, SubscriptionService domain) {
        existing.setServiceName(domain.getServiceName());
        existing.setServiceKeyPrefix(domain.getServiceKeyPrefix());
        existing.setServiceKeyHash(domain.getServiceKeyHash());
        existing.setEffectiveTier(domain.getEffectiveTier());
        existing.setDeviceQuota(domain.getDeviceQuota());
        existing.setStatus(toDb(domain.getStatus()));
        existing.setLastHeartbeatAt(domain.getLastHeartbeatAt());
        existing.setGraceEndsAt(domain.getGraceEndsAt());
        existing.setStartedAt(domain.getStartedAt());
        existing.setExpiresAt(domain.getExpiresAt());
        existing.setHeartbeatIntervalHrs(domain.getHeartbeatIntervalHrs());
        existing.setGracePeriodDays(domain.getGracePeriodDays());
    }

    public static SubscriptionService toDomain(SubscriptionServiceJpaEntity jpa) {
        SubscriptionService domain = new SubscriptionService();
        domain.setId(jpa.getId());
        domain.setTenantId(jpa.getTenantId());
        domain.setServiceName(jpa.getServiceName());
        domain.setServiceKeyPrefix(jpa.getServiceKeyPrefix());
        domain.setServiceKeyHash(jpa.getServiceKeyHash());
        domain.setEffectiveTier(jpa.getEffectiveTier());
        domain.setDeviceQuota(jpa.getDeviceQuota());
        domain.setStatus(fromDb(jpa.getStatus(), SubscriptionServiceStatus.class));
        domain.setLastHeartbeatAt(jpa.getLastHeartbeatAt());
        domain.setGraceEndsAt(jpa.getGraceEndsAt());
        domain.setStartedAt(jpa.getStartedAt());
        domain.setExpiresAt(jpa.getExpiresAt());
        domain.setHeartbeatIntervalHrs(jpa.getHeartbeatIntervalHrs() != null ? jpa.getHeartbeatIntervalHrs() : 24);
        domain.setGracePeriodDays(jpa.getGracePeriodDays() != null ? jpa.getGracePeriodDays() : 7);
        return domain;
    }
}
