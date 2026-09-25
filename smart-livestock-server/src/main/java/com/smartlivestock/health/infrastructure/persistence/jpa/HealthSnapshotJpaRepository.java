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
}
