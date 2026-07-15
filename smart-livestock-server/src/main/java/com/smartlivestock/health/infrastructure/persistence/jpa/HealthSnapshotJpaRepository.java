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
}
