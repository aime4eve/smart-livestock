package com.smartlivestock.licensing.domain.repository;

import com.smartlivestock.licensing.domain.DeploymentInstallation;

import java.util.List;
import java.util.Optional;

/** Repository port for {@code deployment_installations}. */
public interface DeploymentInstallationRepository {

    Optional<DeploymentInstallation> findByTenantId(Long tenantId);

    DeploymentInstallation save(DeploymentInstallation installation);

    /** Tenant ids that have an installation (drives the periodic validation). */
    List<Long> findAllTenantIds();
}
