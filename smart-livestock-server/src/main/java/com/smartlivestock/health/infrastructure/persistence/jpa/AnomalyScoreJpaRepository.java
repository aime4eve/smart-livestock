package com.smartlivestock.health.infrastructure.persistence.jpa;

import com.smartlivestock.health.infrastructure.persistence.entity.AnomalyScoreJpaEntity;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AnomalyScoreJpaRepository extends JpaRepository<AnomalyScoreJpaEntity, Long> {
    Optional<AnomalyScoreJpaEntity> findFirstByFarmIdAndLivestockIdOrderByCreatedAtDesc(Long farmId, Long livestockId);
    List<AnomalyScoreJpaEntity> findByFarmIdAndLivestockIdOrderByCreatedAtDesc(Long farmId, Long livestockId, Pageable pageable);

    interface LatestScoreProjection {
        Long getLivestockId();
        java.math.BigDecimal getAnomalyScore();
        String getAnomalyType();
        java.time.Instant getCreatedAt();
    }

    @org.springframework.data.jpa.repository.Query(value = """
            SELECT DISTINCT ON (livestock_id)
                   livestock_id AS livestockId,
                   anomaly_score AS anomalyScore,
                   anomaly_type AS anomalyType,
                   created_at AS createdAt
            FROM anomaly_scores
            WHERE farm_id = :farmId AND livestock_id IN :livestockIds
            ORDER BY livestock_id, created_at DESC
            """, nativeQuery = true)
    List<LatestScoreProjection> findLatestByLivestockIds(
            @org.springframework.data.repository.query.Param("farmId") Long farmId,
            @org.springframework.data.repository.query.Param("livestockIds") List<Long> livestockIds);
}
