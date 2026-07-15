package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.RtkCalibrationSessionJpaEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SpringDataRtkCalibrationSessionRepository extends JpaRepository<RtkCalibrationSessionJpaEntity, Long> {

    @Query("SELECT s FROM RtkCalibrationSessionJpaEntity s WHERE s.deviceId = :deviceId AND s.status = 'IN_PROGRESS'")
    Optional<RtkCalibrationSessionJpaEntity> findActiveByDeviceId(@Param("deviceId") Long deviceId);

    List<RtkCalibrationSessionJpaEntity> findByRtkPointIdOrderByStartedAtDesc(@Param("rtkPointId") Long rtkPointId);

    List<RtkCalibrationSessionJpaEntity> findByDeviceIdOrderByStartedAtDesc(@Param("deviceId") Long deviceId);

    @Query("SELECT s FROM RtkCalibrationSessionJpaEntity s " +
           "WHERE (:rtkPointId IS NULL OR s.rtkPointId = :rtkPointId) " +
           "AND (:deviceId IS NULL OR s.deviceId = :deviceId) " +
           "AND (:status IS NULL OR s.status = :status) " +
           "ORDER BY s.startedAt DESC")
    Page<RtkCalibrationSessionJpaEntity> findFiltered(@Param("rtkPointId") Long rtkPointId,
                                                      @Param("deviceId") Long deviceId,
                                                      @Param("status") String status,
                                                      Pageable pageable);
}
