package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.DeviceTelemetryLog;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface DeviceTelemetryLogRepository {
    DeviceTelemetryLog save(DeviceTelemetryLog log);

    /** Find the most recent telemetry log for a device (used for stepNumber delta calculation). */
    Optional<DeviceTelemetryLog> findLatestByDeviceId(Long deviceId);

    /** Report times of a device's telemetry rows within [min, max] (import duplicate pre-check, NIX-79). */
    List<Instant> findReportTimesByDeviceIdAndReportTimeBetween(Long deviceId, Instant min, Instant max);
}
