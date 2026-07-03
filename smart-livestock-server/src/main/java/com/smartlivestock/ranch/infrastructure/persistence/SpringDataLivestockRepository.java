package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.infrastructure.persistence.entity.LivestockJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SpringDataLivestockRepository extends JpaRepository<LivestockJpaEntity, Long> {
    @Query("SELECT l FROM LivestockJpaEntity l WHERE l.farmId = :farmId AND l.deletedAt IS NULL")
    List<LivestockJpaEntity> findByFarmId(@Param("farmId") Long farmId);

    @Query("SELECT l FROM LivestockJpaEntity l WHERE l.farmId = :farmId AND l.deletedAt IS NULL ORDER BY l.id")
    org.springframework.data.domain.Page<LivestockJpaEntity> findByFarmIdPaged(@Param("farmId") Long farmId,
                                                                               org.springframework.data.domain.Pageable pageable);

    @Query("SELECT COUNT(l) FROM LivestockJpaEntity l WHERE l.farmId = :farmId AND l.deletedAt IS NULL")
    long countByFarmIdActive(@Param("farmId") Long farmId);

    Optional<LivestockJpaEntity> findByLivestockCode(String livestockCode);
    long countByFarmId(Long farmId);

    @Query("SELECT l FROM LivestockJpaEntity l WHERE l.farmId = :farmId AND l.deletedAt IS NULL " +
           "AND (LOWER(l.livestockCode) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
           "OR LOWER(l.breed) LIKE LOWER(CONCAT('%', :keyword, '%'))) ORDER BY l.id")
    List<LivestockJpaEntity> findByFarmIdAndKeyword(@Param("farmId") Long farmId,
                                                    @Param("keyword") String keyword,
                                                    org.springframework.data.domain.Pageable pageable);

    @Query("SELECT COUNT(l) FROM LivestockJpaEntity l WHERE l.farmId = :farmId AND l.deletedAt IS NULL " +
           "AND (LOWER(l.livestockCode) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
           "OR LOWER(l.breed) LIKE LOWER(CONCAT('%', :keyword, '%')))")
    long countByFarmIdAndKeyword(@Param("farmId") Long farmId, @Param("keyword") String keyword);

    @Query("SELECT COUNT(l) FROM LivestockJpaEntity l WHERE l.farmId = :farmId AND l.deletedAt IS NULL AND l.farmId IN (SELECT fm.id FROM com.smartlivestock.identity.infrastructure.persistence.entity.FarmJpaEntity fm WHERE fm.tenantId = :tenantId)")
    long countByFarmIdAndTenantId(@Param("farmId") Long farmId, @Param("tenantId") Long tenantId);
}
