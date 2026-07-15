package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.GpsLog;
import com.smartlivestock.iot.domain.port.dto.GpsPointWithTelemetry;

import java.time.Instant;
import java.util.List;

public interface GpsLogRepository {
    GpsLog save(GpsLog gpsLog);
    List<GpsLog> findByDeviceId(Long deviceId);
    List<GpsLog> findByDeviceIdAndRecordedAtBetween(Long deviceId, Instant from, Instant to);
    long countByDeviceIdAndRecordedAtBetween(Long deviceId, Instant from, Instant to);

    List<GpsLog> sampleByDeviceIdAndTimeRange(Long deviceId, Instant from, Instant to, long stride);

    /** GPS points joined with telemetry (step/motion/activity) for a device time window. */
    List<GpsPointWithTelemetry> findByDeviceIdAndTimeRangeWithTelemetry(Long deviceId, Instant from, Instant to);
}
