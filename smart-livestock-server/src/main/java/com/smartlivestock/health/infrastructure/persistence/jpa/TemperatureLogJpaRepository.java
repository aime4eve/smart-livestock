package com.smartlivestock.health.infrastructure.persistence.jpa;

import com.smartlivestock.health.infrastructure.persistence.entity.TemperatureLogJpaEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface TemperatureLogJpaRepository extends JpaRepository<TemperatureLogJpaEntity, Long> {
    List<TemperatureLogJpaEntity> findByLivestockIdAndRecordedAtBetweenOrderByRecordedAtAsc(Long livestockId, Instant from, Instant to);
    List<TemperatureLogJpaEntity> findByLivestockIdOrderByRecordedAtDesc(Long livestockId);
    List<TemperatureLogJpaEntity> findByDeviceIdAndRecordedAtBetweenOrderByRecordedAtAsc(
            Long deviceId, Instant from, Instant to);
    Page<TemperatureLogJpaEntity> findByLivestockIdAndRecordedAtBetweenOrderByRecordedAtAsc(
            Long livestockId, Instant from, Instant to, Pageable pageable);
    Page<TemperatureLogJpaEntity> findByDeviceIdAndRecordedAtBetweenOrderByRecordedAtAsc(
            Long deviceId, Instant from, Instant to, Pageable pageable);
    boolean existsByDeviceIdAndRecordedAtAndSource(Long deviceId, Instant recordedAt, String source);

    /**
     * Points of one livestock (all its devices) recorded in {@code [from, to)}
     * — the sample-day minimum-points check (NIX-256 Task 5a). The
     * recorded_at range keeps the time-partition pruning intact.
     */
    long countByLivestockIdAndRecordedAtGreaterThanEqualAndRecordedAtLessThan(
            Long livestockId, Instant from, Instant to);

    /**
     * Daily AVG temperature + normal-reading counts for the /health/stats
     * trends (NIX-323). The recorded_at lower bound keeps time-partition
     * pruning intact.
     */
    @Query(value = """
            SELECT to_char(t.recorded_at, 'YYYY-MM-DD') AS day,
                   AVG(t.temperature)                    AS avg_temp,
                   COUNT(*)                              AS readings,
                   COUNT(*) FILTER (WHERE ABS(t.delta) <= 0.5) AS normal_readings
            FROM temperature_logs t
            WHERE t.livestock_id IN (:livestockIds)
              AND t.recorded_at >= :since
            GROUP BY day
            ORDER BY day
            """, nativeQuery = true)
    List<Object[]> aggregateDailyStatsRows(@Param("livestockIds") List<Long> livestockIds,
                                           @Param("since") Instant since);

    @org.springframework.data.jpa.repository.Query("""
            SELECT t FROM TemperatureLogJpaEntity t WHERE t.livestockId IN :livestockIds
            ORDER BY t.livestockId ASC, t.recordedAt ASC
            """)
    org.springframework.data.domain.Page<TemperatureLogJpaEntity> findPageByLivestockIdIn(
            @org.springframework.data.repository.query.Param("livestockIds") List<Long> livestockIds,
            org.springframework.data.domain.Pageable pageable);
}
