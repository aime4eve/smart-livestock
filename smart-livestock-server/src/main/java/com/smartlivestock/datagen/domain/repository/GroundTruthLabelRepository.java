package com.smartlivestock.datagen.domain.repository;

import com.smartlivestock.datagen.domain.model.GroundTruthLabel;

import java.time.Instant;
import java.util.List;

public interface GroundTruthLabelRepository {
    GroundTruthLabel save(GroundTruthLabel label);
    List<GroundTruthLabel> findByLivestockIdAndPeriodOverlap(Long livestockId, Instant from, Instant to);
}
