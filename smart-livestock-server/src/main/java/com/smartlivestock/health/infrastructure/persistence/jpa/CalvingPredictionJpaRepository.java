package com.smartlivestock.health.infrastructure.persistence.jpa;

import com.smartlivestock.health.infrastructure.persistence.entity.CalvingPredictionJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CalvingPredictionJpaRepository extends JpaRepository<CalvingPredictionJpaEntity, Long> {
    List<CalvingPredictionJpaEntity> findByLivestockIdOrderByPredictedAtDesc(Long livestockId);
    Optional<CalvingPredictionJpaEntity> findTopByLivestockIdOrderByPredictedAtDesc(Long livestockId);

    /**
     * Latest row per livestock of a farm (NIX-389). PostgreSQL DISTINCT ON
     * keeps one row per head — the newest {@code predicted_at} (id as the
     * tiebreaker) — served by {@code idx_calving_livestock_time}. Plain
     * SELECT * is safe: the table has no generated columns.
     */
    @org.springframework.data.jpa.repository.Query(value = """
            SELECT DISTINCT ON (livestock_id) *
            FROM calving_predictions
            WHERE farm_id = :farmId
            ORDER BY livestock_id ASC, predicted_at DESC, id DESC
            LIMIT :limit
            """, nativeQuery = true)
    List<CalvingPredictionJpaEntity> findLatestPerLivestockByFarm(
            @org.springframework.data.repository.query.Param("farmId") Long farmId,
            @org.springframework.data.repository.query.Param("limit") int limit);
}
