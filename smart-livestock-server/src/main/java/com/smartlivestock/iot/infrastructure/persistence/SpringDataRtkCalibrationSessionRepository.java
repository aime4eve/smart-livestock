package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.RtkCalibrationSessionJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SpringDataRtkCalibrationSessionRepository extends JpaRepository<RtkCalibrationSessionJpaEntity, Long>,
        JpaSpecificationExecutor<RtkCalibrationSessionJpaEntity> {

    @Query("SELECT s FROM RtkCalibrationSessionJpaEntity s WHERE s.deviceId = :deviceId AND s.status = 'IN_PROGRESS'")
    Optional<RtkCalibrationSessionJpaEntity> findActiveByDeviceId(@Param("deviceId") Long deviceId);

    List<RtkCalibrationSessionJpaEntity> findByRtkPointIdOrderByStartedAtDesc(@Param("rtkPointId") Long rtkPointId);

    List<RtkCalibrationSessionJpaEntity> findByDeviceIdOrderByStartedAtDesc(@Param("deviceId") Long deviceId);
}
