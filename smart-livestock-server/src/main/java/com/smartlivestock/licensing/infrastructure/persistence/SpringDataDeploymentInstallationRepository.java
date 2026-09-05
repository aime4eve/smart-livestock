package com.smartlivestock.licensing.infrastructure.persistence;

import com.smartlivestock.licensing.infrastructure.persistence.entity.DeploymentInstallationJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

interface SpringDataDeploymentInstallationRepository
        extends JpaRepository<DeploymentInstallationJpaEntity, Long> {

    Optional<DeploymentInstallationJpaEntity> findByTenantId(Long tenantId);

    @Query("SELECT i.tenantId FROM DeploymentInstallationJpaEntity i ORDER BY i.tenantId")
    List<Long> findAllTenantIds();
}
