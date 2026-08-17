package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.infrastructure.persistence.entity.DatagenDeviceAssignmentJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface DatagenDeviceAssignmentJpaRepository
        extends JpaRepository<DatagenDeviceAssignmentJpaEntity, Long> {
    List<DatagenDeviceAssignmentJpaEntity> findByControlId(Long controlId);
    Optional<DatagenDeviceAssignmentJpaEntity> findByControlIdAndDeviceId(
            Long controlId, Long deviceId);
    List<DatagenDeviceAssignmentJpaEntity> findByControlIdAndRemovedAtIsNull(Long controlId);

    @Query("""
            SELECT a FROM DatagenDeviceAssignmentJpaEntity a
            JOIN DatagenFarmControlJpaEntity c ON c.id = a.controlId
            WHERE c.scenarioId = :scenarioId
              AND c.enabled = true
              AND a.removedAt IS NULL
            """)
    List<DatagenDeviceAssignmentJpaEntity> findActiveByScenarioId(
            @Param("scenarioId") Long scenarioId);
}
