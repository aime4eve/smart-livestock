package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.infrastructure.persistence.entity.FarmJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SpringDataFarmRepository extends JpaRepository<FarmJpaEntity, Long> {
    List<FarmJpaEntity> findByTenantId(Long tenantId);

    boolean existsByIdAndTenantId(Long id, Long tenantId);
}
