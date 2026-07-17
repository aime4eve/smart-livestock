package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.GpsQualitySession;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.Optional;

public interface GpsQualitySessionRepository {
    GpsQualitySession save(GpsQualitySession session);
    Optional<GpsQualitySession> findById(Long id);
    Optional<GpsQualitySession> findActiveByDeviceId(Long deviceId);
    Page<GpsQualitySession> findFiltered(Long deviceId, String status, Pageable pageable);
    void deleteById(Long id);
}
