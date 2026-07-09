package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.DeviceTelemetryLog;

import java.util.Optional;

public interface DeviceTelemetryLogRepository {
    DeviceTelemetryLog save(DeviceTelemetryLog log);

    /** Find the most recent telemetry log for a device (used for stepNumber delta calculation). */
    Optional<DeviceTelemetryLog> findLatestByDeviceId(Long deviceId);
}
