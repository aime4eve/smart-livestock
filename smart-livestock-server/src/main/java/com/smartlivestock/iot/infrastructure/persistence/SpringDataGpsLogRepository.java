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

    @Query("SELECT g FROM GpsLogJpaEntity g WHERE g.deviceId = :deviceId AND (g.recordedAt BETWEEN :startTime AND :endTime) AND (g.latitude <> 0 OR g.longitude <> 0) ORDER BY g.recordedAt DESC")
    List<GpsLogJpaEntity> findByDeviceIdAndRecordedAtBetween(@Param("deviceId") Long deviceId, @Param("startTime") Instant startTime, @Param("endTime") Instant endTime);
}
