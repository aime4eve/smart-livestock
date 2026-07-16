package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.GpsQualityTest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;

public interface GpsQualityTestRepository {
    GpsQualityTest save(GpsQualityTest test);
    Optional<GpsQualityTest> findById(Long id);

    /** Active (IN_PROGRESS) test for a device, if any. */
    Optional<GpsQualityTest> findActiveByDeviceId(Long deviceId);

    List<GpsQualityTest> findByRtkPointIdOrderByStartedAtDesc(Long rtkPointId);
    List<GpsQualityTest> findByDeviceIdOrderByStartedAtDesc(Long deviceId);

    /** Tests with optional filters, paged (all params nullable). */
    Page<GpsQualityTest> findFiltered(Long rtkPointId, Long deviceId, String status, String testType, Pageable pageable);

    List<GpsQualityTest> findAll();
    void deleteById(Long id);
}
