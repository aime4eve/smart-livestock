package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.infrastructure.persistence.entity.FenceZoneJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface SpringDataFenceZoneRepository extends JpaRepository<FenceZoneJpaEntity, Long> {
    List<FenceZoneJpaEntity> findByFarmId(Long farmId);

    @Modifying
    @Query("DELETE FROM FenceZoneJpaEntity z WHERE z.fenceId = :fenceId")
    int deleteByFenceId(@Param("fenceId") Long fenceId);
}
