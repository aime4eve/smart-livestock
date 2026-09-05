package com.smartlivestock.licensing.domain.repository;

import com.smartlivestock.licensing.domain.DeploymentLicense;

import java.util.Optional;
import java.util.UUID;

/** Repository port for {@code deployment_licenses}. */
public interface DeploymentLicenseRepository {

    /** The tenant's newest accepted license (record status CURRENT), if any. */
    Optional<DeploymentLicense> findCurrentByTenantId(Long tenantId);

    Optional<DeploymentLicense> findByLicenseId(UUID licenseId);

    DeploymentLicense save(DeploymentLicense license);
}
