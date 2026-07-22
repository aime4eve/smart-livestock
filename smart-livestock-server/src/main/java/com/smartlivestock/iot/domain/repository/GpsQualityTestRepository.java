package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.GpsQualityTest;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface GpsQualityTestRepository {
    GpsQualityTest save(GpsQualityTest test);
    Optional<GpsQualityTest> findById(Long id);
    List<GpsQualityTest> findByDeviceIdOrderByStartedAt(Long deviceId);
    List<GpsQualityTest> findByRtkPointId(Long rtkPointId);
    boolean existsByEuiAndTimeRange(String eui, Instant startedAt, String testType);

    /** NIX-22 D7 dedup: an identical TRAJECTORY window already imported for this device. */
    boolean existsTrajectoryWindow(String deviceCode, Instant startedAt, Instant endedAt);

    List<GpsQualityTest> findByBatchImportId(Long batchImportId);
    List<GpsQualityTest> findByStatus(String status);
    List<GpsQualityTest> findByStatusAndTenantId(String status, Long tenantId);
    List<GpsQualityTest> findByRouteIdAndStatus(Long routeId, String status);

    List<GpsQualityTest> findFiltered(String status, String eui, Long deviceId, int offset, int limit);
    long countFiltered(String status, String eui, Long deviceId);

    void deleteById(Long id);

    /** Delete all tests of one device; returns the number of rows deleted. */
    int deleteByDeviceId(Long deviceId);
}
