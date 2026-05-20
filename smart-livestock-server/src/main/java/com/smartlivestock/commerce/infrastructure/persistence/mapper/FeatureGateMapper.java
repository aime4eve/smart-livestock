package com.smartlivestock.commerce.infrastructure.persistence.mapper;

import com.smartlivestock.commerce.domain.model.FeatureGate;
import com.smartlivestock.commerce.domain.model.GateType;
import com.smartlivestock.commerce.infrastructure.persistence.entity.FeatureGateJpaEntity;

public final class FeatureGateMapper {

    private FeatureGateMapper() {}

    public static FeatureGateJpaEntity toJpaEntity(FeatureGate domain) {
        FeatureGateJpaEntity jpa = new FeatureGateJpaEntity();
        jpa.setId(domain.getId());
        jpa.setTier(domain.getTier());
        jpa.setFeatureKey(domain.getFeatureKey());
        jpa.setGateType(domain.getGateType().name().toLowerCase());
        jpa.setLimitValue(domain.getLimitValue());
        jpa.setRetentionDays(domain.getRetentionDays());
        jpa.setIsEnabled(domain.isEnabled());
        return jpa;
    }

    public static FeatureGate toDomain(FeatureGateJpaEntity jpa) {
        FeatureGate domain = new FeatureGate();
        domain.setId(jpa.getId());
        domain.setTier(jpa.getTier());
        domain.setFeatureKey(jpa.getFeatureKey());
        domain.setGateType(GateType.valueOf(jpa.getGateType().toUpperCase()));
        domain.setLimitValue(jpa.getLimitValue());
        domain.setRetentionDays(jpa.getRetentionDays());
        domain.setEnabled(jpa.getIsEnabled() != null ? jpa.getIsEnabled() : true);
        return domain;
    }
}
