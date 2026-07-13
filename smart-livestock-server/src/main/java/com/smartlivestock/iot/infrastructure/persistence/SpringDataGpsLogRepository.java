package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.GpsLogJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface SpringDataGpsLogRepository extends JpaRepository<GpsLogJpaEntity, Long> {
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
}
