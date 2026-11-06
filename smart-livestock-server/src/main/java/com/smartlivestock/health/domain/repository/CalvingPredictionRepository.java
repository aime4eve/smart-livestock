package com.smartlivestock.health.domain.repository;

import com.smartlivestock.health.domain.model.CalvingPrediction;

import java.util.List;
import java.util.Optional;

public interface CalvingPredictionRepository {
    CalvingPrediction save(CalvingPrediction prediction);
    Optional<CalvingPrediction> findLatestByLivestockId(Long livestockId);
    List<CalvingPrediction> findByLivestockIdOrderByPredictedAtDesc(Long livestockId, int limit);
}
