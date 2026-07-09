package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.DeviceTelemetryLogJpaEntity;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface SpringDataDeviceTelemetryLogRepository extends JpaRepository<DeviceTelemetryLogJpaEntity, Long> {

    @Query("SELECT t FROM DeviceTelemetryLogJpaEntity t WHERE t.deviceId = :deviceId ORDER BY t.reportTime DESC")
    List<DeviceTelemetryLogJpaEntity> findLatestByDeviceId(@Param("deviceId") Long deviceId, Pageable pageable);
}
