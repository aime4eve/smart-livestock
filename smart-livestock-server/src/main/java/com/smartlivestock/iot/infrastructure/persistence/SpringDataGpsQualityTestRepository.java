package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.GpsQualityTestJpaEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface SpringDataGpsQualityTestRepository extends JpaRepository<GpsQualityTestJpaEntity, Long> {

    List<GpsQualityTestJpaEntity> findByDeviceIdOrderByStartedAt(Long deviceId);
    List<GpsQualityTestJpaEntity> findByRtkPointId(Long rtkPointId);

    @Query("SELECT COUNT(t) > 0 FROM GpsQualityTestJpaEntity t " +
           "JOIN DeviceJpaEntity d ON d.id = t.deviceId " +
           "WHERE d.devEui = :eui AND t.testType = :testType " +
           "AND t.startedAt = :startedAt")
    boolean existsByEuiAndTimeRange(@Param("eui") String eui,
                                    @Param("startedAt") Instant startedAt,
                                    @Param("testType") String testType);

    boolean existsByDeviceCodeAndTestTypeAndStartedAtAndEndedAt(
            String deviceCode, String testType, Instant startedAt, Instant endedAt);

    List<GpsQualityTestJpaEntity> findByBatchImportId(Long batchImportId);
    List<GpsQualityTestJpaEntity> findByStatus(String status);

    @Query("SELECT t FROM GpsQualityTestJpaEntity t " +
           "JOIN DeviceJpaEntity d ON d.id = t.deviceId " +
           "WHERE t.status = :status AND d.tenantId = :tenantId")
    List<GpsQualityTestJpaEntity> findByStatusAndTenantId(@Param("status") String status,
                                                          @Param("tenantId") Long tenantId);

    List<GpsQualityTestJpaEntity> findByRouteIdAndStatus(Long routeId, String status);

    /** Bulk delete of all quality tests of one device (device record itself is kept). */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("DELETE FROM GpsQualityTestJpaEntity t WHERE t.deviceId = :deviceId")
    int deleteByDeviceId(@Param("deviceId") Long deviceId);

    @Query("SELECT t FROM GpsQualityTestJpaEntity t " +
           "LEFT JOIN DeviceJpaEntity d ON d.id = t.deviceId " +
           "WHERE (:status = '' OR t.status = :status) " +
           "AND (:deviceId = 0 OR t.deviceId = :deviceId) " +
           "AND (:eui = '' OR d.devEui LIKE CONCAT('%', :eui, '%')) " +
           "ORDER BY t.startedAt DESC")
    Page<GpsQualityTestJpaEntity> findByFilters(
            @Param("status") String status,
            @Param("deviceId") Long deviceId,
            @Param("eui") String eui,
            Pageable pageable);

    @Query("SELECT COUNT(t) FROM GpsQualityTestJpaEntity t " +
           "LEFT JOIN DeviceJpaEntity d ON d.id = t.deviceId " +
           "WHERE (:status = '' OR t.status = :status) " +
           "AND (:deviceId = 0 OR t.deviceId = :deviceId) " +
           "AND (:eui = '' OR d.devEui LIKE CONCAT('%', :eui, '%'))")
    long countByFilters(
            @Param("status") String status,
            @Param("deviceId") Long deviceId,
            @Param("eui") String eui);
}
