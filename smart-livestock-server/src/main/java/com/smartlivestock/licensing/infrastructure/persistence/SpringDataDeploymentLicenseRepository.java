package com.smartlivestock.licensing.infrastructure.persistence;

import com.smartlivestock.licensing.infrastructure.persistence.entity.DeploymentLicenseJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

interface SpringDataDeploymentLicenseRepository
        extends JpaRepository<DeploymentLicenseJpaEntity, Long> {

    Optional<DeploymentLicenseJpaEntity> findByLicenseId(UUID licenseId);

    Optional<DeploymentLicenseJpaEntity> findFirstByTenantIdAndStatusOrderByAcceptedAtDesc(
            Long tenantId, String status);
}
