package com.smartlivestock.licensing.infrastructure.persistence;

import com.smartlivestock.licensing.infrastructure.persistence.entity.DeploymentLicenseEventJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

interface SpringDataDeploymentLicenseEventRepository
        extends JpaRepository<DeploymentLicenseEventJpaEntity, Long> {
}
