package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.GpsIngestionTaskJpaEntity;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public interface SpringDataGpsIngestionTaskRepository extends JpaRepository<GpsIngestionTaskJpaEntity, Long> {
    @Modifying
    @Query(value = """
           INSERT INTO gps_ingestion_tasks (
               device_id, latitude, longitude, accuracy, recorded_at, source,
               status, attempts, next_attempt_at, created_at, updated_at
           ) VALUES (
               :deviceId, :latitude, :longitude, :accuracy, :recordedAt, :source,
               'PENDING', 0, NOW(), NOW(), NOW()
           )
           ON CONFLICT (device_id, recorded_at) DO UPDATE SET
               latitude = EXCLUDED.latitude,
               longitude = EXCLUDED.longitude,
               accuracy = EXCLUDED.accuracy,
               source = EXCLUDED.source,
               status = 'PENDING',
               attempts = 0,
               next_attempt_at = NOW(),
               last_error = NULL,
               updated_at = NOW()
           """, nativeQuery = true)
    void enqueue(
            @Param("deviceId") Long deviceId,
            @Param("latitude") BigDecimal latitude,
            @Param("longitude") BigDecimal longitude,
            @Param("accuracy") BigDecimal accuracy,
            @Param("recordedAt") Instant recordedAt,
            @Param("source") String source);

    @Query("""
           SELECT t.id FROM GpsIngestionTaskJpaEntity t
           WHERE t.status = 'PENDING' AND t.nextAttemptAt <= :now
           ORDER BY t.recordedAt ASC
           """)
    List<Long> findReadyTaskIds(@Param("now") Instant now, Pageable pageable);
}
