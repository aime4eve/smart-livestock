package com.smartlivestock.identity.infrastructure.persistence.mapper;

import com.smartlivestock.identity.domain.model.Tenant;
import com.smartlivestock.identity.domain.model.TenantPhase;
import com.smartlivestock.identity.infrastructure.persistence.entity.TenantJpaEntity;

public final class TenantMapper {

    private TenantMapper() {}

    public static TenantJpaEntity toJpaEntity(Tenant tenant) {
        TenantJpaEntity jpa = new TenantJpaEntity();
        jpa.setId(tenant.getId());
        jpa.setName(tenant.getName());
        jpa.setContactName(tenant.getContactName());
        jpa.setContactPhone(tenant.getContactPhone());
        jpa.setPhase(tenant.getPhase().name());
        jpa.setType(tenant.getType());
        jpa.setBillingModel(tenant.getBillingModel());
        return jpa;
    }

    public static Tenant toDomain(TenantJpaEntity jpa) {
        Tenant tenant = new Tenant();
        tenant.setId(jpa.getId());
        tenant.setName(jpa.getName());
        tenant.setContactName(jpa.getContactName());
        tenant.setContactPhone(jpa.getContactPhone());
        tenant.reconstitutePhase(TenantPhase.valueOf(jpa.getPhase()));
        tenant.setType(jpa.getType());
        tenant.setBillingModel(jpa.getBillingModel());
        return tenant;
    }

    public static void applyTo(TenantJpaEntity jpa, Tenant tenant) {
        jpa.setName(tenant.getName());
        jpa.setContactName(tenant.getContactName());
        jpa.setContactPhone(tenant.getContactPhone());
        jpa.setPhase(tenant.getPhase().name());
        jpa.setType(tenant.getType());
        jpa.setBillingModel(tenant.getBillingModel());
    }
}
