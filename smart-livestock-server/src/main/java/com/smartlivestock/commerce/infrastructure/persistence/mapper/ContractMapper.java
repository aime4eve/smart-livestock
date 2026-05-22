package com.smartlivestock.commerce.infrastructure.persistence.mapper;

import com.smartlivestock.commerce.domain.model.Contract;
import com.smartlivestock.commerce.domain.model.ContractStatus;
import com.smartlivestock.commerce.infrastructure.persistence.entity.ContractJpaEntity;

import static com.smartlivestock.commerce.infrastructure.persistence.mapper.EnumConverters.fromDb;
import static com.smartlivestock.commerce.infrastructure.persistence.mapper.EnumConverters.toDb;

public final class ContractMapper {

    private ContractMapper() {}

    public static ContractJpaEntity toJpaEntity(Contract domain) {
        ContractJpaEntity jpa = new ContractJpaEntity();
        jpa.setId(domain.getId());
        jpa.setContractNumber(domain.getContractNumber());
        jpa.setTenantId(domain.getTenantId());
        jpa.setBillingModel(domain.getBillingModel());
        jpa.setEffectiveTier(domain.getEffectiveTier());
        jpa.setRevenueShareRatio(domain.getRevenueShareRatio());
        jpa.setStatus(toDb(domain.getStatus()));
        jpa.setSignedBy(domain.getSignedBy());
        jpa.setSignedAt(domain.getSignedAt());
        jpa.setStartedAt(domain.getStartedAt());
        jpa.setExpiresAt(domain.getExpiresAt());
        return jpa;
    }

    public static void updateEntity(ContractJpaEntity existing, Contract domain) {
        existing.setContractNumber(domain.getContractNumber());
        existing.setBillingModel(domain.getBillingModel());
        existing.setEffectiveTier(domain.getEffectiveTier());
        existing.setRevenueShareRatio(domain.getRevenueShareRatio());
        existing.setStatus(toDb(domain.getStatus()));
        existing.setSignedBy(domain.getSignedBy());
        existing.setSignedAt(domain.getSignedAt());
        existing.setStartedAt(domain.getStartedAt());
        existing.setExpiresAt(domain.getExpiresAt());
    }

    public static Contract toDomain(ContractJpaEntity jpa) {
        Contract domain = new Contract();
        domain.setId(jpa.getId());
        domain.setContractNumber(jpa.getContractNumber());
        domain.setTenantId(jpa.getTenantId());
        domain.setBillingModel(jpa.getBillingModel());
        domain.setEffectiveTier(jpa.getEffectiveTier());
        domain.setRevenueShareRatio(jpa.getRevenueShareRatio());
        domain.setStatus(fromDb(jpa.getStatus(), ContractStatus.class));
        domain.setSignedBy(jpa.getSignedBy());
        domain.setSignedAt(jpa.getSignedAt());
        domain.setStartedAt(jpa.getStartedAt());
        domain.setExpiresAt(jpa.getExpiresAt());
        return domain;
    }
}
