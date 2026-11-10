package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.infrastructure.persistence.entity.GroundTruthLabelJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface GroundTruthLabelJpaRepository extends JpaRepository<GroundTruthLabelJpaEntity, Long> {
    @Query("SELECT g FROM GroundTruthLabelJpaEntity g WHERE g.livestockId = :id " +
           "AND g.periodStart <= :to AND g.periodEnd >= :from")
    List<GroundTruthLabelJpaEntity> findByLivestockIdAndPeriodOverlap(
        @Param("id") Long id, @Param("from") Instant from, @Param("to") Instant to);

    /**
     * The effective (CONFIRMED/REJECTED) verdict row of one alert — at most
     * one exists by uq_gt_labels_alert_active; newest-first pick is a safety
     * net against transient duplicates written before that index existed.
     */
    Optional<GroundTruthLabelJpaEntity> findFirstByRefAlertIdAndVerdictInOrderByIdDesc(
            Long refAlertId, Collection<String> verdicts);

    /** Detection lookup for an already-written per-alert source row. */
    Optional<GroundTruthLabelJpaEntity> findFirstByRefAlertIdAndSourceOrderByIdDesc(
            Long refAlertId, String source);
}
