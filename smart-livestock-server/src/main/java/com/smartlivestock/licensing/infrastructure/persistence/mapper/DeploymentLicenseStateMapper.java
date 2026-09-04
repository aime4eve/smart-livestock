package com.smartlivestock.licensing.infrastructure.persistence.mapper;

import com.smartlivestock.licensing.domain.DeploymentLicenseState;
import com.smartlivestock.licensing.domain.LicenseRuntimeStatus;
import com.smartlivestock.licensing.infrastructure.persistence.entity.DeploymentLicenseStateJpaEntity;

/** Domain ↔ JPA mapping for {@code deployment_license_states}. */
public final class DeploymentLicenseStateMapper {

    private DeploymentLicenseStateMapper() {
    }

    public static DeploymentLicenseStateJpaEntity toEntity(DeploymentLicenseState domain) {
        DeploymentLicenseStateJpaEntity entity = new DeploymentLicenseStateJpaEntity();
        // tenant_id is the natural @Id; set it explicitly anyway for clarity
        entity.setTenantId(domain.getTenantId());
        entity.setCurrentLicenseId(domain.getCurrentLicenseId());
        entity.setRuntimeStatus(domain.getRuntimeStatus() != null
                ? domain.getRuntimeStatus().name() : null);
        entity.setMaxObservedAt(domain.getMaxObservedAt());
        entity.setLastValidatedAt(domain.getLastValidatedAt());
        entity.setLastErrorCode(domain.getLastErrorCode());
        entity.setProtectionReason(domain.getProtectionReason());
        entity.setUpdatedAt(domain.getUpdatedAt());
        return entity;
    }

    public static DeploymentLicenseState toDomain(DeploymentLicenseStateJpaEntity entity) {
        DeploymentLicenseState domain = new DeploymentLicenseState();
        domain.setTenantId(entity.getTenantId());
        domain.setCurrentLicenseId(entity.getCurrentLicenseId());
        if (entity.getRuntimeStatus() != null && !entity.getRuntimeStatus().isBlank()) {
            try {
                domain.setRuntimeStatus(
                        LicenseRuntimeStatus.valueOf(entity.getRuntimeStatus()));
            } catch (IllegalArgumentException ignored) {
                // Unknown persisted value: leave null, derived on next validation.
            }
        }
        domain.setMaxObservedAt(entity.getMaxObservedAt());
        domain.setLastValidatedAt(entity.getLastValidatedAt());
        domain.setLastErrorCode(entity.getLastErrorCode());
        domain.setProtectionReason(entity.getProtectionReason());
        domain.setUpdatedAt(entity.getUpdatedAt());
        return domain;
    }
}
