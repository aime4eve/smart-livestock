package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.GpsLogJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public interface SpringDataGpsLogRepository extends JpaRepository<GpsLogJpaEntity, Long> {
    /**
     * Idempotent upsert guarded by the unique (device_id, recorded_at) index.
     * Re-syncs from the agentic-platform re-ingest the same frame; this collapses
     * it to a single row instead of stacking duplicates.
     */
    @Modifying
    @Query(value = """
           INSERT INTO gps_logs (device_id, latitude, longitude, accuracy, recorded_at, created_at)
           VALUES (:deviceId, :latitude, :longitude, :accuracy, :recordedAt, NOW())
           ON CONFLICT (device_id, recorded_at) DO UPDATE
           SET latitude = EXCLUDED.latitude,
               longitude = EXCLUDED.longitude,
               accuracy = EXCLUDED.accuracy
           """, nativeQuery = true)
    void upsertByDeviceAndRecordedAt(@Param("deviceId") Long deviceId,
                                     @Param("latitude") BigDecimal latitude,
                                     @Param("longitude") BigDecimal longitude,
                                     @Param("accuracy") BigDecimal accuracy,
                                     @Param("recordedAt") Instant recordedAt);

    @Query("SELECT g FROM GpsLogJpaEntity g WHERE g.deviceId = :deviceId AND (g.latitude <> 0 OR g.longitude <> 0) ORDER BY g.recordedAt DESC")
    List<GpsLogJpaEntity> findByDeviceId(@Param("deviceId") Long deviceId);

    @Query("SELECT COUNT(g) FROM GpsLogJpaEntity g WHERE g.deviceId = :deviceId AND (g.recordedAt BETWEEN :startTime AND :endTime) AND (g.latitude <> 0 OR g.longitude <> 0)")
    long countByDeviceIdAndRecordedAtBetween(@Param("deviceId") Long deviceId, @Param("startTime") Instant startTime, @Param("endTime") Instant endTime);

    @Query("SELECT g FROM GpsLogJpaEntity g WHERE g.deviceId = :deviceId AND (g.recordedAt BETWEEN :startTime AND :endTime) AND (g.latitude <> 0 OR g.longitude <> 0) ORDER BY g.recordedAt DESC")
    List<GpsLogJpaEntity> findByDeviceIdAndRecordedAtBetween(@Param("deviceId") Long deviceId, @Param("startTime") Instant startTime, @Param("endTime") Instant endTime);

    @Query(value = "SELECT id FROM (SELECT id, ROW_NUMBER() OVER (ORDER BY recorded_at ASC) AS rn FROM gps_logs WHERE device_id = :deviceId AND recorded_at BETWEEN :startTime AND :endTime AND (latitude <> 0 OR longitude <> 0)) numbered WHERE MOD(rn, :stride) = 0", nativeQuery = true)
    List<Long> sampleIdsByDeviceIdAndTimeRange(@Param("deviceId") Long deviceId,
                                               @Param("startTime") Instant startTime,
                                               @Param("endTime") Instant endTime,
                                               @Param("stride") long stride);

    @Query("SELECT g FROM GpsLogJpaEntity g WHERE g.id IN :ids ORDER BY g.recordedAt ASC")
    List<GpsLogJpaEntity> findAllByIdInOrderByRecordedAt(@Param("ids") List<Long> ids);

  @Query(value = """
         SELECT gl.latitude, gl.longitude, gl.accuracy, gl.recorded_at,
                dtl.step_number, dtl.motion_intensity, dtl.activity_class
        FROM (
             -- DISTINCT ON collapses any duplicate (device_id, recorded_at) frames
             -- in gps_logs (a re-sync can stack thousands of copies of one frame
             -- before the unique index existed). Keeps exactly one row per frame.
             SELECT DISTINCT ON (device_id, recorded_at)
                    device_id, latitude, longitude, accuracy, recorded_at
             FROM gps_logs
             WHERE device_id = :deviceId
               AND recorded_at BETWEEN :startTime AND :endTime
               AND latitude <> 0 AND longitude <> 0
             ORDER BY device_id, recorded_at, id
        ) gl
          LEFT JOIN (
              -- DISTINCT ON collapses exact-duplicate telemetry rows that would
              -- otherwise explode this join (a single duplicate report_time can
              -- multiply gps_logs rows thousands-fold). Same report_time for a
              -- device always carries identical payload, so this loses nothing.
              SELECT DISTINCT ON (device_id, report_time)
                    device_id, report_time, step_number, motion_intensity, activity_class
             FROM device_telemetry_logs
             WHERE device_id = :deviceId
               AND report_time BETWEEN :startTime AND :endTime
             ORDER BY device_id, report_time, id
         ) dtl
           ON dtl.report_time = gl.recorded_at
        ORDER BY gl.recorded_at
         """, nativeQuery = true)
  List<Object[]> findGpsWithTelemetryByDeviceIdAndTimeRange(
          @Param("deviceId") Long deviceId,
          @Param("startTime") Instant startTime,
          @Param("endTime") Instant endTime);
}
