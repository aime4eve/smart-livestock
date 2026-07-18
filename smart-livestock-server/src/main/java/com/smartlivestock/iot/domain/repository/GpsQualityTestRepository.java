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

    List<GpsQualityTest> findByBatchImportId(Long batchImportId);
    List<GpsQualityTest> findByStatus(String status);

    List<GpsQualityTest> findFiltered(String status, String eui, Long deviceId, int offset, int limit);
    long countFiltered(String status, String eui, Long deviceId);

    void deleteById(Long id);
}
