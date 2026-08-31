package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.DeviceTelemetryLogJpaEntity;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface SpringDataDeviceTelemetryLogRepository extends JpaRepository<DeviceTelemetryLogJpaEntity, Long> {

    @Query("SELECT t FROM DeviceTelemetryLogJpaEntity t WHERE t.deviceId = :deviceId ORDER BY t.reportTime DESC")
    List<DeviceTelemetryLogJpaEntity> findLatestByDeviceId(@Param("deviceId") Long deviceId, Pageable pageable);

    @Query("""
            SELECT t FROM DeviceTelemetryLogJpaEntity t
            WHERE t.deviceId = :deviceId
              AND t.reportTime < :reportTime
              AND t.latitude IS NOT NULL
              AND t.longitude IS NOT NULL
              AND t.latitude <> 0
              AND t.longitude <> 0
            ORDER BY t.reportTime DESC
            """)
    List<DeviceTelemetryLogJpaEntity> findLatestGpsByDeviceIdAndReportTimeBefore(
            @Param("deviceId") Long deviceId,
            @Param("reportTime") Instant reportTime,
            Pageable pageable);

    boolean existsByDeviceIdAndReportTime(Long deviceId, Instant reportTime);

    @Query("SELECT t.reportTime FROM DeviceTelemetryLogJpaEntity t WHERE t.deviceId = :deviceId AND t.reportTime BETWEEN :startTime AND :endTime")
    List<Instant> findReportTimesByDeviceIdAndReportTimeBetween(@Param("deviceId") Long deviceId,
                                                                @Param("startTime") Instant startTime,
                                                                @Param("endTime") Instant endTime);
}
