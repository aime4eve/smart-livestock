package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.GpsQualityLinePoint;

import java.util.List;

public interface GpsQualityLinePointRepository {
    List<GpsQualityLinePoint> saveAll(List<GpsQualityLinePoint> points);
    List<GpsQualityLinePoint> findByTestIdOrderBySequenceNo(Long testId);
    void deleteByTestId(Long testId);
}
