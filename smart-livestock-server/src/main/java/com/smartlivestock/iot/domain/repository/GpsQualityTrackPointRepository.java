package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.GpsQualityTrackPoint;

import java.util.List;

public interface GpsQualityTrackPointRepository {
    GpsQualityTrackPoint save(GpsQualityTrackPoint point);
    List<GpsQualityTrackPoint> saveAll(List<GpsQualityTrackPoint> points);
    List<GpsQualityTrackPoint> findByTestIdOrderByCollectedAt(Long testId);
    void deleteByTestId(Long testId);
}
