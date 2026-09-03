package com.smartlivestock.licensing.infrastructure.persistence.mapper;

import com.smartlivestock.licensing.domain.DeploymentLicenseEvent;
import com.smartlivestock.licensing.domain.LicenseEventType;
import com.smartlivestock.licensing.infrastructure.persistence.entity.DeploymentLicenseEventJpaEntity;

/** Domain ↔ JPA mapping for {@code deployment_license_events}. */
public final class DeploymentLicenseEventMapper {

    private DeploymentLicenseEventMapper() {
    }

    public static DeploymentLicenseEventJpaEntity toEntity(DeploymentLicenseEvent domain) {
        DeploymentLicenseEventJpaEntity entity = new DeploymentLicenseEventJpaEntity();
        entity.setLicenseId(domain.getLicenseId());
        entity.setTenantId(domain.getTenantId());
        entity.setEventType(domain.getEventType() != null ? domain.getEventType().name() : null);
        entity.setResult(domain.getResult());
        entity.setErrorCode(domain.getErrorCode());
        entity.setDetails(domain.getDetails());
        entity.setOperatorUserId(domain.getOperatorUserId());
        entity.setOccurredAt(domain.getOccurredAt());
        return entity;
    }
}
