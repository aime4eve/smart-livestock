package com.smartlivestock.health.domain.repository;

import com.smartlivestock.health.domain.model.EstrusScore;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface EstrusScoreRepository {
    List<EstrusScore> findByFarmIdOrderByScoredAtDesc(Long farmId);
    List<EstrusScore> findByLivestockIdOrderByScoredAtDesc(Long livestockId, int limit);
    Optional<EstrusScore> findLatestByLivestockId(Long livestockId);
    EstrusScore save(EstrusScore score);
}
