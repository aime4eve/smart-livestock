package com.smartlivestock.health.infrastructure.persistence.jpa;

import com.smartlivestock.health.infrastructure.persistence.entity.TemperatureLogJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;

public interface TemperatureLogJpaRepository extends JpaRepository<TemperatureLogJpaEntity, Long> {
    List<TemperatureLogJpaEntity> findByLivestockIdAndRecordedAtBetweenOrderByRecordedAtAsc(Long livestockId, Instant from, Instant to);
    List<TemperatureLogJpaEntity> findByLivestockIdOrderByRecordedAtDesc(Long livestockId);
    List<TemperatureLogJpaEntity> findByDeviceIdAndRecordedAtBetweenOrderByRecordedAtAsc(
            Long deviceId, Instant from, Instant to);
    boolean existsByDeviceIdAndRecordedAtAndSource(Long deviceId, Instant recordedAt, String source);

    /**
     * Points of one livestock (all its devices) recorded in {@code [from, to)}
     * — the sample-day minimum-points check (NIX-256 Task 5a). The
     * recorded_at range keeps the time-partition pruning intact.
     */
    long countByLivestockIdAndRecordedAtGreaterThanEqualAndRecordedAtLessThan(
            Long livestockId, Instant from, Instant to);
}
