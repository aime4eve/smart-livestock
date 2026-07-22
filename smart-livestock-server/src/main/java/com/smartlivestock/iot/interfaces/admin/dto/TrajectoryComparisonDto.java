package com.smartlivestock.iot.interfaces.admin.dto;

import java.time.Instant;
import java.util.List;

/**
 * Cross-device trajectory comparison (spec D10): the latest READY TRAJECTORY
 * test per device.
 */
public class TrajectoryComparisonDto {

    private List<DeviceSummary> devices;

    public record DeviceSummary(
        Long testId,
        Long deviceId,
        String deviceCode,
        int totalPoints,
        int paired,
        double pairRate,
        double meanError,
        double p50,
        double p95,
        String grade,
        Instant startedAt,
        Instant endedAt
    ) {}

    public List<DeviceSummary> getDevices() { return devices; }
    public void setDevices(List<DeviceSummary> devices) { this.devices = devices; }
}
