package com.smartlivestock.health.domain.repository;

import com.smartlivestock.health.domain.model.CalvingPrediction;

import java.util.List;
import java.util.Optional;

public interface CalvingPredictionRepository {
    CalvingPrediction save(CalvingPrediction prediction);
    Optional<CalvingPrediction> findLatestByLivestockId(Long livestockId);
    List<CalvingPrediction> findByLivestockIdOrderByPredictedAtDesc(Long livestockId, int limit);

    /**
     * Latest row per livestock for a farm (NIX-389 tile list), newest
     * {@code predicted_at} first within each head, at most {@code limit} rows.
     * Backed by the {@code idx_calving_livestock_time} index (V20261106130000).
     */
    List<CalvingPrediction> findLatestPerLivestockByFarm(Long farmId, int limit);
}
