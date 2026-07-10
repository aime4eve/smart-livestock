package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.GpsLogJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;

public interface SpringDataGpsLogRepository extends JpaRepository<GpsLogJpaEntity, Long> {
    List<GpsLogJpaEntity> findByDeviceId(Long deviceId);
    List<GpsLogJpaEntity> findByDeviceIdAndRecordedAtBetween(Long deviceId, Instant from, Instant to);
}
