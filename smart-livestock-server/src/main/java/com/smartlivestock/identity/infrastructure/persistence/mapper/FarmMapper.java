package com.smartlivestock.identity.infrastructure.persistence.mapper;

import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.identity.infrastructure.persistence.entity.FarmJpaEntity;

public final class FarmMapper {

    private FarmMapper() {}

    public static FarmJpaEntity toJpaEntity(Farm farm) {
        FarmJpaEntity jpa = new FarmJpaEntity();
        jpa.setId(farm.getId());
        jpa.setTenantId(farm.getTenantId());
        jpa.setName(farm.getName());
        jpa.setLatitude(farm.getLatitude());
        jpa.setLongitude(farm.getLongitude());
        jpa.setAreaHectares(farm.getAreaHectares());
        return jpa;
    }

    public static Farm toDomain(FarmJpaEntity jpa) {
        Farm farm = new Farm();
        farm.setId(jpa.getId());
        farm.setTenantId(jpa.getTenantId());
        farm.setName(jpa.getName());
        farm.setLatitude(jpa.getLatitude());
        farm.setLongitude(jpa.getLongitude());
        farm.setAreaHectares(jpa.getAreaHectares());
        return farm;
    }
}
