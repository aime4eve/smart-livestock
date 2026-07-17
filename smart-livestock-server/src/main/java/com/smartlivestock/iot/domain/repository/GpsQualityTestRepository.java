package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.GpsQualityTest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;

public interface GpsQualityTestRepository {
    GpsQualityTest save(GpsQualityTest test);
    Optional<GpsQualityTest> findById(Long id);
    List<GpsQualityTest> findBySessionId(Long sessionId);
    List<GpsQualityTest> findByRtkPointId(Long rtkPointId);
    Page<GpsQualityTest> findFiltered(Long rtkPointId, Long routeId, String testType, Pageable pageable);
    void deleteById(Long id);
}
