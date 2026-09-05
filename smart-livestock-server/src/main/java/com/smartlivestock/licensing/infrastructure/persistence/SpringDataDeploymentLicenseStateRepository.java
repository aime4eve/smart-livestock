package com.smartlivestock.licensing.infrastructure.persistence;

import com.smartlivestock.licensing.infrastructure.persistence.entity.DeploymentLicenseStateJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

interface SpringDataDeploymentLicenseStateRepository
        extends JpaRepository<DeploymentLicenseStateJpaEntity, Long> {

    Optional<DeploymentLicenseStateJpaEntity> findByTenantId(Long tenantId);

    Optional<DeploymentLicenseStateJpaEntity> findTopByOrderByUpdatedAtDesc();
}
