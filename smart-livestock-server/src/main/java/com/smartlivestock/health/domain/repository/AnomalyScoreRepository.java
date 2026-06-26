package com.smartlivestock.health.domain.repository;

import com.smartlivestock.health.domain.model.AnomalyScore;

import java.util.List;
import java.util.Optional;

public interface AnomalyScoreRepository {
    AnomalyScore save(AnomalyScore score);
    Optional<AnomalyScore> findLatestByFarmIdAndLivestockId(Long farmId, Long livestockId);
    List<AnomalyScore> findByFarmIdAndLivestockId(Long farmId, Long livestockId, int limit);
}
