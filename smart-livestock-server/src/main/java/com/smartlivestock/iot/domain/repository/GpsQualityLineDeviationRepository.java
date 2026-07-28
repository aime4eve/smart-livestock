package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.GpsQualityLineDeviation;

import java.util.List;

public interface GpsQualityLineDeviationRepository {
    List<GpsQualityLineDeviation> saveAll(List<GpsQualityLineDeviation> deviations);
    List<GpsQualityLineDeviation> findByTestIdOrderBySequenceNo(Long testId);
    void deleteByTestId(Long testId);
}
