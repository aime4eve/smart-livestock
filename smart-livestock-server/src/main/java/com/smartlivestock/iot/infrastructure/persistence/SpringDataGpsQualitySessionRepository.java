package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.GpsQualitySessionJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface SpringDataGpsQualitySessionRepository
        extends JpaRepository<GpsQualitySessionJpaEntity, Long>,
                JpaSpecificationExecutor<GpsQualitySessionJpaEntity> {

    @Query("SELECT s FROM GpsQualitySessionJpaEntity s WHERE s.deviceId = :deviceId AND s.status = 'IN_PROGRESS'")
    Optional<GpsQualitySessionJpaEntity> findActiveByDeviceId(@Param("deviceId") Long deviceId);
}
