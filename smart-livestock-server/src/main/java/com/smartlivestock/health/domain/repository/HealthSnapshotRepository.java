package com.smartlivestock.health.domain.repository;

import com.smartlivestock.health.domain.model.HealthSnapshot;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface HealthSnapshotRepository {
    List<HealthSnapshot> findByFarmId(Long farmId);
    Optional<HealthSnapshot> findByLivestockId(Long livestockId);
    HealthSnapshot save(HealthSnapshot snapshot);
    void ensureSnapshotExists(Long livestockId, Long farmId);

    /** Livestock with health telemetry after {@code cutoff}, newest source included. */
    List<ActiveLivestock> findRecentlyActive(Instant cutoff, int maxRows);

    record ActiveLivestock(Long livestockId, Long farmId, String telemetrySource) {}
    /** All farm ids that have snapshots (drives farm-wide health schedulers). */
    List<Long> findDistinctFarmIds();

    /**
     * Targeted UPDATE that writes only the learned-baseline fields of one
     * snapshot ({@code baseline_source} is stamped {@code LEARNED}). The
     * whole-entity write path must not be used here: processTelemetry does a
     * read-modify-write on the same row and a full-entity save would clobber
     * concurrent health-state changes (dirty-write-back lesson, plan
     * 2026-11-03 §1.4).
     *
     * @return number of snapshot rows updated (0 = no snapshot for the livestock)
     */
    int updateLearnedBaseline(LearnedBaselineUpdate update);

    /** Learned-baseline field set written by {@link #updateLearnedBaseline}. */
    record LearnedBaselineUpdate(Long livestockId,
                                 java.math.BigDecimal baselineTemp,
                                 Integer sampleCount,
                                 Integer qualifiedDays,
                                 Instant windowStart,
                                 Instant computedAt,
                                 java.math.BigDecimal bandLow,
                                 java.math.BigDecimal bandHigh,
                                 String algorithmVersion) {}

    /**
     * Targeted UPDATE that writes only {@code calving_risk_score} of one
     * snapshot (NIX-381). {@code null} clears the column (alert released =
     * back to never-assessed semantics). The whole-entity write path must
     * not be used here: processTelemetry and the baseline learner do
     * read-modify-write on the same row and a full-entity save would clobber
     * their concurrent changes (dirty-write-back lesson, plan 2026-11-03).
     *
     * @return number of snapshot rows updated (0 = no snapshot for the livestock)
     */
    int updateCalvingRiskScore(Long livestockId, Integer riskScore);
}
