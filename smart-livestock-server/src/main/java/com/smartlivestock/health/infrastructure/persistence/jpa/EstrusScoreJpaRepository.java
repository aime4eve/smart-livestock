package com.smartlivestock.health.infrastructure.persistence.jpa;

import com.smartlivestock.health.infrastructure.persistence.entity.EstrusScoreJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface EstrusScoreJpaRepository extends JpaRepository<EstrusScoreJpaEntity, Long> {
    List<EstrusScoreJpaEntity> findByFarmIdOrderByScoredAtDesc(Long farmId);
    List<EstrusScoreJpaEntity> findByLivestockIdOrderByScoredAtDesc(Long livestockId);
    Optional<EstrusScoreJpaEntity> findTopByLivestockIdOrderByScoredAtDesc(Long livestockId);
}
