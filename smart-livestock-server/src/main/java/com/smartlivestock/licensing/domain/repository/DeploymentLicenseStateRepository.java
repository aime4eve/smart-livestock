package com.smartlivestock.licensing.domain.repository;

import com.smartlivestock.licensing.domain.DeploymentLicenseState;

import java.util.Optional;

/** Repository port for {@code deployment_license_states} (one row per tenant). */
public interface DeploymentLicenseStateRepository {

    Optional<DeploymentLicenseState> findByTenantId(Long tenantId);

    /**
     * Most recently updated state row. ONPREM deployments are single-tenant,
     * so this backs the tenant-less public deployment-info lookup.
     */
    Optional<DeploymentLicenseState> findLatest();

    DeploymentLicenseState save(DeploymentLicenseState state);
}
