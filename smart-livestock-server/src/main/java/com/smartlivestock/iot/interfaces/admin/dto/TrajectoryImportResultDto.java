package com.smartlivestock.iot.interfaces.admin.dto;

import java.util.List;

/**
 * Result of an RTK trajectory import (spec §6.3): one TRAJECTORY test per device.
 */
public class TrajectoryImportResultDto {

    private int createdCount;
    private int skippedCount;
    private List<DeviceResult> devices;
    private int autoRegisteredCount;

    /**
     * @param status  CREATED / SKIPPED_DUPLICATE
     * @param testId  the new test id, or the existing test id when skipped
     */
    public record DeviceResult(
        String deviceEui,
        Long testId,
        String status,
        int totalPoints,
        int filePaired,
        int logPaired,
        int unpaired
    ) {}

    public int getCreatedCount() { return createdCount; }
    public void setCreatedCount(int createdCount) { this.createdCount = createdCount; }
    public int getSkippedCount() { return skippedCount; }
    public void setSkippedCount(int skippedCount) { this.skippedCount = skippedCount; }
    public List<DeviceResult> getDevices() { return devices; }
    public void setDevices(List<DeviceResult> devices) { this.devices = devices; }
    public int getAutoRegisteredCount() { return autoRegisteredCount; }
    public void setAutoRegisteredCount(int autoRegisteredCount) { this.autoRegisteredCount = autoRegisteredCount; }
}
