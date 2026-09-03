package com.smartlivestock.licensing.infrastructure.persistence.mapper;

import com.smartlivestock.licensing.domain.DeploymentInstallation;
import com.smartlivestock.licensing.infrastructure.persistence.entity.DeploymentInstallationJpaEntity;

/** Domain ↔ JPA mapping for {@code deployment_installations}. */
public final class DeploymentInstallationMapper {

    private DeploymentInstallationMapper() {
    }

    public static DeploymentInstallationJpaEntity toEntity(DeploymentInstallation domain) {
        DeploymentInstallationJpaEntity entity = new DeploymentInstallationJpaEntity();
        entity.setTenantId(domain.getTenantId());
        entity.setInstallationId(domain.getInstallationId());
        entity.setFingerprintHash(domain.getFingerprintHash());
        entity.setCreatedAt(domain.getCreatedAt());
        entity.setUpdatedAt(domain.getUpdatedAt());
        return entity;
    }

    public static DeploymentInstallation toDomain(DeploymentInstallationJpaEntity entity) {
        DeploymentInstallation domain = new DeploymentInstallation();
        domain.setId(entity.getId());
        domain.setTenantId(entity.getTenantId());
        domain.restoreIdentity(entity.getInstallationId(), entity.getFingerprintHash());
        domain.setCreatedAt(entity.getCreatedAt());
        domain.setUpdatedAt(entity.getUpdatedAt());
        return domain;
    }
}
