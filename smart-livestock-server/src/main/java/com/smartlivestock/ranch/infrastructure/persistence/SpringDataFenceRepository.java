package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.infrastructure.persistence.entity.FenceJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface SpringDataFenceRepository extends JpaRepository<FenceJpaEntity, Long> {
    List<FenceJpaEntity> findByFarmId(Long farmId);
    long countByFarmId(Long farmId);

    @Query("SELECT COUNT(f) FROM FenceJpaEntity f WHERE f.farmId = :farmId AND f.farmId IN (SELECT fm.id FROM com.smartlivestock.identity.infrastructure.persistence.entity.FarmJpaEntity fm WHERE fm.tenantId = :tenantId)")
    long countByFarmIdAndTenantId(@Param("farmId") Long farmId, @Param("tenantId") Long tenantId);
}
