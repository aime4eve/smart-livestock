package com.smartlivestock.health.domain.repository;

import com.smartlivestock.health.domain.model.HealthSnapshot;

import java.util.List;
import java.util.Optional;

public interface HealthSnapshotRepository {
    List<HealthSnapshot> findByFarmId(Long farmId);
    Optional<HealthSnapshot> findByLivestockId(Long livestockId);
    HealthSnapshot save(HealthSnapshot snapshot);
    void ensureSnapshotExists(Long livestockId, Long farmId);
}
