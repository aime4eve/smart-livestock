package com.smartlivestock.datagen.domain.repository;

import com.smartlivestock.datagen.domain.model.GroundTruthLabel;
import com.smartlivestock.datagen.domain.model.LabelSource;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface GroundTruthLabelRepository {
    GroundTruthLabel save(GroundTruthLabel label);
    List<GroundTruthLabel> findByLivestockIdAndPeriodOverlap(Long livestockId, Instant from, Instant to);

    /**
     * The single effective (CONFIRMED/REJECTED) verdict row ruling on one
     * candidate alert — at most one exists per alert by
     * {@code uq_gt_labels_alert_active} (NIX-286 contract v2).
     */
    Optional<GroundTruthLabel> findActiveVerdictByRefAlertId(Long refAlertId);

    /**
     * Existing label row of one alert for the given source — used to detect
     * an already-written BREEDING_DERIVED row before writing a duplicate.
     */
    Optional<GroundTruthLabel> findByRefAlertIdAndSource(Long refAlertId, LabelSource source);
}
