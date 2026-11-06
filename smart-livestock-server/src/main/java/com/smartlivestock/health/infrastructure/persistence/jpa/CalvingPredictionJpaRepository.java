package com.smartlivestock.health.infrastructure.persistence.jpa;

import com.smartlivestock.health.infrastructure.persistence.entity.CalvingPredictionJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CalvingPredictionJpaRepository extends JpaRepository<CalvingPredictionJpaEntity, Long> {
    List<CalvingPredictionJpaEntity> findByLivestockIdOrderByPredictedAtDesc(Long livestockId);
    Optional<CalvingPredictionJpaEntity> findTopByLivestockIdOrderByPredictedAtDesc(Long livestockId);
}
