package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.infrastructure.persistence.entity.AlertJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface SpringDataAlertRepository extends JpaRepository<AlertJpaEntity, Long> {
    List<AlertJpaEntity> findByFarmId(Long farmId);
    List<AlertJpaEntity> findByFarmIdAndStatus(Long farmId, String status);
    List<AlertJpaEntity> findByFarmIdOrderByIdDesc(Long farmId, org.springframework.data.domain.Pageable pageable);
    List<AlertJpaEntity> findByLivestockIdAndTypeAndStatus(Long livestockId, String type, String status);
    List<AlertJpaEntity> findByDeviceIdAndTypeAndStatus(Long deviceId, String type, String status);

    @Modifying
    @Query("DELETE FROM AlertJpaEntity a WHERE a.fenceId = :fenceId")
    int deleteByFenceId(@Param("fenceId") Long fenceId);

    @Modifying
    @Query("UPDATE AlertJpaEntity a SET a.fenceId = NULL WHERE a.fenceId = :fenceId")
    int clearFenceReference(@Param("fenceId") Long fenceId);
}
