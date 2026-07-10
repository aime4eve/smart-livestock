package com.smartlivestock.health.infrastructure.persistence.jpa;

import com.smartlivestock.health.infrastructure.persistence.entity.AnomalyScoreJpaEntity;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AnomalyScoreJpaRepository extends JpaRepository<AnomalyScoreJpaEntity, Long> {
    Optional<AnomalyScoreJpaEntity> findFirstByFarmIdAndLivestockIdOrderByCreatedAtDesc(Long farmId, Long livestockId);
    List<AnomalyScoreJpaEntity> findByFarmIdAndLivestockIdOrderByCreatedAtDesc(Long farmId, Long livestockId, Pageable pageable);
}
