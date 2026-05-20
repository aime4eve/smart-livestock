package com.smartlivestock.commerce.infrastructure.persistence.mapper;

import com.smartlivestock.commerce.domain.model.RevenuePeriod;
import com.smartlivestock.commerce.domain.model.RevenueSettlementStatus;
import com.smartlivestock.commerce.infrastructure.persistence.entity.RevenuePeriodJpaEntity;

public final class RevenuePeriodMapper {

    private RevenuePeriodMapper() {}

    public static RevenuePeriodJpaEntity toJpaEntity(RevenuePeriod domain) {
        RevenuePeriodJpaEntity jpa = new RevenuePeriodJpaEntity();
        jpa.setId(domain.getId());
        jpa.setContractId(domain.getContractId());
        jpa.setTenantId(domain.getTenantId());
        jpa.setPeriodStart(domain.getPeriodStart());
        jpa.setPeriodEnd(domain.getPeriodEnd());
        jpa.setGrossAmount(domain.getGrossAmount());
        jpa.setPlatformShare(domain.getPlatformShare());
        jpa.setPartnerShare(domain.getPartnerShare());
        jpa.setRevenueShareRatio(domain.getRevenueShareRatio());
        jpa.setStatus(domain.getStatus().name().toLowerCase());
        jpa.setSettledAt(domain.getSettledAt());
        return jpa;
    }

    public static void updateEntity(RevenuePeriodJpaEntity existing, RevenuePeriod domain) {
        existing.setPeriodStart(domain.getPeriodStart());
        existing.setPeriodEnd(domain.getPeriodEnd());
        existing.setGrossAmount(domain.getGrossAmount());
        existing.setPlatformShare(domain.getPlatformShare());
        existing.setPartnerShare(domain.getPartnerShare());
        existing.setRevenueShareRatio(domain.getRevenueShareRatio());
        existing.setStatus(domain.getStatus().name().toLowerCase());
        existing.setSettledAt(domain.getSettledAt());
    }

    public static RevenuePeriod toDomain(RevenuePeriodJpaEntity jpa) {
        RevenuePeriod domain = new RevenuePeriod();
        domain.setId(jpa.getId());
        domain.setContractId(jpa.getContractId());
        domain.setTenantId(jpa.getTenantId());
        domain.setPeriodStart(jpa.getPeriodStart());
        domain.setPeriodEnd(jpa.getPeriodEnd());
        domain.setGrossAmount(jpa.getGrossAmount());
        domain.setPlatformShare(jpa.getPlatformShare());
        domain.setPartnerShare(jpa.getPartnerShare());
        domain.setRevenueShareRatio(jpa.getRevenueShareRatio());
        domain.setStatus(RevenueSettlementStatus.valueOf(jpa.getStatus().toUpperCase()));
        domain.setSettledAt(jpa.getSettledAt());
        return domain;
    }
}
