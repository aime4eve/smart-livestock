package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.GpsLog;

import java.time.Instant;
import java.util.List;

public interface GpsLogRepository {
    GpsLog save(GpsLog gpsLog);
    List<GpsLog> findByDeviceId(Long deviceId);
    List<GpsLog> findByDeviceIdAndRecordedAtBetween(Long deviceId, Instant from, Instant to);
    long countByDeviceIdAndRecordedAtBetween(Long deviceId, Instant from, Instant to);

    List<GpsLog> sampleByDeviceIdAndTimeRange(Long deviceId, Instant from, Instant to, long stride);
}
