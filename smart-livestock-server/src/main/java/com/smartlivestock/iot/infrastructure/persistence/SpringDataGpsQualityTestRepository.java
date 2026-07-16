package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.GpsQualityTestJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SpringDataGpsQualityTestRepository extends JpaRepository<GpsQualityTestJpaEntity, Long>,
        JpaSpecificationExecutor<GpsQualityTestJpaEntity> {

    @Query("SELECT s FROM GpsQualityTestJpaEntity s WHERE s.deviceId = :deviceId AND s.status = 'IN_PROGRESS'")
    Optional<GpsQualityTestJpaEntity> findActiveByDeviceId(@Param("deviceId") Long deviceId);

    List<GpsQualityTestJpaEntity> findByRtkPointIdOrderByStartedAtDesc(@Param("rtkPointId") Long rtkPointId);

    List<GpsQualityTestJpaEntity> findByDeviceIdOrderByStartedAtDesc(@Param("deviceId") Long deviceId);
}
