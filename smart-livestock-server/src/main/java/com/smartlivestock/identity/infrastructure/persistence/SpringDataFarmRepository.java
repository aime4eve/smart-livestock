package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.infrastructure.persistence.entity.FarmJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SpringDataFarmRepository extends JpaRepository<FarmJpaEntity, Long> {
    List<FarmJpaEntity> findByTenantId(Long tenantId);

    /** Non-deleted farms only — used for tenant option farm counts. */
    List<FarmJpaEntity> findByTenantIdAndDeletedAtIsNull(Long tenantId);

    boolean existsByIdAndTenantId(Long id, Long tenantId);
}
