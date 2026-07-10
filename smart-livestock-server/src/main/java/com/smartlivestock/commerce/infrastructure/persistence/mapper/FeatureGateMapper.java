package com.smartlivestock.commerce.infrastructure.persistence.mapper;

import com.smartlivestock.commerce.domain.model.FeatureGate;
import com.smartlivestock.commerce.domain.model.GateType;
import com.smartlivestock.commerce.infrastructure.persistence.entity.FeatureGateJpaEntity;

import static com.smartlivestock.commerce.infrastructure.persistence.mapper.EnumConverters.fromDb;
import static com.smartlivestock.commerce.infrastructure.persistence.mapper.EnumConverters.toDb;

public final class FeatureGateMapper {

    private FeatureGateMapper() {}

    public static FeatureGateJpaEntity toJpaEntity(FeatureGate domain) {
        FeatureGateJpaEntity jpa = new FeatureGateJpaEntity();
        jpa.setId(domain.getId());
        jpa.setTier(domain.getTier());
        jpa.setFeatureKey(domain.getFeatureKey());
        jpa.setGateType(toDb(domain.getGateType()));
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
        domain.setGateType(fromDb(jpa.getGateType(), GateType.class));
        domain.setLimitValue(jpa.getLimitValue());
        domain.setRetentionDays(jpa.getRetentionDays());
        domain.setEnabled(jpa.getIsEnabled() != null ? jpa.getIsEnabled() : true);
        return domain;
    }
}
