package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.infrastructure.persistence.entity.LivestockJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SpringDataLivestockRepository extends JpaRepository<LivestockJpaEntity, Long> {
    List<LivestockJpaEntity> findByFarmId(Long farmId);
    Optional<LivestockJpaEntity> findByLivestockCode(String livestockCode);
    long countByFarmId(Long farmId);

    @Query("SELECT COUNT(l) FROM LivestockJpaEntity l WHERE l.farmId = :farmId AND l.deletedAt IS NULL AND l.farmId IN (SELECT fm.id FROM com.smartlivestock.identity.infrastructure.persistence.entity.FarmJpaEntity fm WHERE fm.tenantId = :tenantId)")
    long countByFarmIdAndTenantId(@Param("farmId") Long farmId, @Param("tenantId") Long tenantId);
}
