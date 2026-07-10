package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.infrastructure.persistence.entity.FarmTileTaskJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SpringDataFarmTileTaskRepository extends JpaRepository<FarmTileTaskJpaEntity, Long> {
    List<FarmTileTaskJpaEntity> findByFarmId(Long farmId);
    Optional<FarmTileTaskJpaEntity> findByFarmIdAndRegionId(Long farmId, Long regionId);
    List<FarmTileTaskJpaEntity> findByRegionIdAndStatus(Long regionId, String status);

    @org.springframework.data.jpa.repository.Query("SELECT DISTINCT f.farmId FROM FarmTileTaskJpaEntity f")
    List<Long> findAllDistinctFarmIds();
}
