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
}
