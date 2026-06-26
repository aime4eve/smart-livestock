package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.infrastructure.persistence.entity.GroundTruthLabelJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface GroundTruthLabelJpaRepository extends JpaRepository<GroundTruthLabelJpaEntity, Long> {
    @Query("SELECT g FROM GroundTruthLabelJpaEntity g WHERE g.livestockId = :id " +
           "AND g.periodStart <= :to AND g.periodEnd >= :from")
    List<GroundTruthLabelJpaEntity> findByLivestockIdAndPeriodOverlap(
        @Param("id") Long id, @Param("from") Instant from, @Param("to") Instant to);
}
