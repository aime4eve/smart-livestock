package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.GpsQualityLineResult;

import java.util.Optional;

public interface GpsQualityLineResultRepository {
    GpsQualityLineResult save(GpsQualityLineResult result);
    Optional<GpsQualityLineResult> findByTestId(Long testId);
    void deleteByTestId(Long testId);
}
