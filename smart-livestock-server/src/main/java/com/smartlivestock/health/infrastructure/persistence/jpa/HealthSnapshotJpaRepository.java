package com.smartlivestock.health.infrastructure.persistence.jpa;

import com.smartlivestock.health.infrastructure.persistence.entity.HealthSnapshotJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface HealthSnapshotJpaRepository extends JpaRepository<HealthSnapshotJpaEntity, Long> {
    List<HealthSnapshotJpaEntity> findByFarmId(Long farmId);
    Optional<HealthSnapshotJpaEntity> findByLivestockId(Long livestockId);

    // UPSERT: race-safe idempotent insert; does nothing if a snapshot for this livestock already exists
    @Modifying
    @Query(value = """
            INSERT INTO health_snapshots
                (livestock_id, farm_id, baseline_temp, motility_baseline,
                 temp_status, motility_status, activity_status, estrus_score,
                 created_at, updated_at)
            VALUES
                (:livestockId, :farmId, 38.50, 3.0,
                 'NORMAL', 'NORMAL', 'NORMAL', 0,
                 NOW(), NOW())
            ON CONFLICT (livestock_id) DO NOTHING
            """, nativeQuery = true)
    void ensureSnapshotExists(@Param("livestockId") Long livestockId, @Param("farmId") Long farmId);

    /**
     * Livestock with temperature telemetry after :cutoff — the candidates the
     * AI anomaly scheduler should assess. farm_id comes from the snapshot
     * (temperature_logs has none); telemetry source is the latest
     * device_telemetry_logs row of the reporting device. Rows come back as
     * [livestock_id(BIGINT), farm_id(BIGINT), source(VARCHAR)].
     */
    @Query(value = """
            SELECT DISTINCT ON (tl.livestock_id)
                   tl.livestock_id,
                   hs.farm_id,
                   COALESCE((SELECT dtl.source FROM device_telemetry_logs dtl
                             WHERE dtl.device_id = tl.device_id
                               AND dtl.report_time > :cutoff
                             ORDER BY dtl.report_time DESC LIMIT 1), 'UNKNOWN') AS source
            FROM temperature_logs tl
            JOIN health_snapshots hs ON hs.livestock_id = tl.livestock_id
            WHERE tl.recorded_at > :cutoff
            ORDER BY tl.livestock_id
            LIMIT :maxRows
            """, nativeQuery = true)
    List<Object[]> findRecentlyActiveLivestock(@Param("cutoff") java.time.Instant cutoff,
                                               @Param("maxRows") int maxRows);
    /** All farm ids that have snapshots (drives farm-wide health schedulers). */
    @Query("SELECT DISTINCT s.farmId FROM HealthSnapshotJpaEntity s")
    List<Long> findDistinctFarmIds();

    /**
     * Targeted UPDATE of the learned-baseline fields only (plan 2026-11-03
     * §1.4). Deliberately NOT a full-entity save: processTelemetry does a
     * read-modify-write on the same row, and writing the whole entity here
     * would resurrect stale health-state columns (dirty-write-back lesson).
     * {@code updated_at} is bumped like every other write path; no signal
     * event is fired — the baseline is a slow-moving variable, not a signal.
     */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query(value = """
            UPDATE health_snapshots
               SET baseline_temp = :baselineTemp,
                   baseline_source = 'LEARNED',
                   baseline_sample_count = :sampleCount,
                   baseline_qualified_days = :qualifiedDays,
                   baseline_window_start = :windowStart,
                   baseline_computed_at = :computedAt,
                   baseline_band_low = :bandLow,
                   baseline_band_high = :bandHigh,
                   baseline_algorithm_version = :algorithmVersion,
                   updated_at = NOW()
             WHERE livestock_id = :livestockId
            """, nativeQuery = true)
    int updateLearnedBaseline(@Param("livestockId") Long livestockId,
                              @Param("baselineTemp") java.math.BigDecimal baselineTemp,
                              @Param("sampleCount") Integer sampleCount,
                              @Param("qualifiedDays") Integer qualifiedDays,
                              @Param("windowStart") java.time.Instant windowStart,
                              @Param("computedAt") java.time.Instant computedAt,
                              @Param("bandLow") java.math.BigDecimal bandLow,
                              @Param("bandHigh") java.math.BigDecimal bandHigh,
                              @Param("algorithmVersion") String algorithmVersion);

    /**
     * Targeted UPDATE of calving_risk_score only (NIX-381, plan 2026-11-06).
     * Deliberately NOT a full-entity save — same dirty-write-back reasoning
     * as {@link #updateLearnedBaseline}: the calving scheduler shares this
     * row with the telemetry chain and the baseline learner. {@code null}
     * riskScore writes NULL (alert released = never-assessed semantics).
     * {@code updated_at} is bumped like every other write path; no signal
     * event is fired here.
     */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query(value = """
            UPDATE health_snapshots
               SET calving_risk_score = :riskScore,
                   updated_at = NOW()
             WHERE livestock_id = :livestockId
            """, nativeQuery = true)
    int updateCalvingRiskScore(@Param("livestockId") Long livestockId,
                               @Param("riskScore") Integer riskScore);
}
