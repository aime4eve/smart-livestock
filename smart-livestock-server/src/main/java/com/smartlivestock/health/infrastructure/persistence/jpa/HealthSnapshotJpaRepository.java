package com.smartlivestock.health.infrastructure.persistence.jpa;

import com.smartlivestock.health.infrastructure.persistence.entity.HealthSnapshotJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface HealthSnapshotJpaRepository extends JpaRepository<HealthSnapshotJpaEntity, Long> {
    List<HealthSnapshotJpaEntity> findByFarmId(Long farmId);
    Optional<HealthSnapshotJpaEntity> findByLivestockId(Long livestockId);
}
