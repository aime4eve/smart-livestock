package com.smartlivestock.licensing.infrastructure.persistence.mapper;

import com.smartlivestock.licensing.domain.DeploymentLicense;
import com.smartlivestock.licensing.domain.LicenseRecordStatus;
import com.smartlivestock.licensing.domain.LicenseType;
import com.smartlivestock.licensing.domain.LicenseValidationOutcome;
import com.smartlivestock.licensing.infrastructure.persistence.entity.DeploymentLicenseJpaEntity;

/** Domain ↔ JPA mapping for {@code deployment_licenses}. */
public final class DeploymentLicenseMapper {

    private DeploymentLicenseMapper() {
    }

    public static DeploymentLicenseJpaEntity toEntity(DeploymentLicense domain) {
        DeploymentLicenseJpaEntity entity = new DeploymentLicenseJpaEntity();
        entity.setLicenseId(domain.getLicenseId());
        entity.setTenantId(domain.getTenantId());
        entity.setInstallationId(domain.getInstallationId());
        entity.setFingerprintHash(domain.getFingerprintHash());
        entity.setKeyId(domain.getKeyId());
        entity.setLicenseType(domain.getLicenseType() != null ? domain.getLicenseType().name() : null);
        entity.setTier(domain.getTier());
        entity.setEffectiveTier(domain.getEffectiveTier());
        entity.setIssuedAt(domain.getIssuedAt());
        entity.setExpiresAt(domain.getExpiresAt());
        entity.setPayloadSha256(domain.getPayloadSha256());
        entity.setRawLicense(domain.getRawLicense());
        entity.setStatus(domain.getStatus() != null ? domain.getStatus().name() : null);
        entity.setAcceptedAt(domain.getAcceptedAt());
        entity.setLastValidatedAt(domain.getLastValidatedAt());
        entity.setLastResult(domain.getLastResult() != null ? domain.getLastResult().name() : null);
        entity.setLastErrorCode(domain.getLastErrorCode());
        entity.setReplacesLicenseId(domain.getReplacesLicenseId());
        return entity;
    }

    public static DeploymentLicense toDomain(DeploymentLicenseJpaEntity entity) {
        DeploymentLicense domain = new DeploymentLicense();
        domain.setId(entity.getId());
        domain.setLicenseId(entity.getLicenseId());
        domain.setTenantId(entity.getTenantId());
        domain.setInstallationId(entity.getInstallationId());
        domain.setFingerprintHash(entity.getFingerprintHash());
        domain.setKeyId(entity.getKeyId());
        domain.setLicenseType(parseEnum(LicenseType.class, entity.getLicenseType()));
        domain.setTier(entity.getTier());
        domain.setEffectiveTier(entity.getEffectiveTier());
        domain.setIssuedAt(entity.getIssuedAt());
        domain.setExpiresAt(entity.getExpiresAt());
        domain.setPayloadSha256(entity.getPayloadSha256());
        domain.setRawLicense(entity.getRawLicense());
        domain.setStatus(parseEnum(LicenseRecordStatus.class, entity.getStatus()));
        domain.setAcceptedAt(entity.getAcceptedAt());
        domain.setLastValidatedAt(entity.getLastValidatedAt());
        domain.setLastResult(parseEnum(LicenseValidationOutcome.class, entity.getLastResult()));
        domain.setLastErrorCode(entity.getLastErrorCode());
        domain.setReplacesLicenseId(entity.getReplacesLicenseId());
        return domain;
    }

    private static <E extends Enum<E>> E parseEnum(Class<E> type, String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return Enum.valueOf(type, value);
        } catch (IllegalArgumentException e) {
            // Unknown persisted value: keep the row loadable, field stays null.
            return null;
        }
    }
}
