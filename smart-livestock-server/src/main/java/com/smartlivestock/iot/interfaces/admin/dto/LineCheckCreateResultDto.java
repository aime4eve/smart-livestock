package com.smartlivestock.iot.interfaces.admin.dto;

import java.util.List;

/**
 * Result of POST /line-checks (NIX-68, spec §7.3): one READY LINE test per
 * device, computed synchronously.
 */
public class LineCheckCreateResultDto {

    private List<DeviceResult> devices;

    public record DeviceResult(
        Long testId,
        String deviceCode,
        int sampleCount,
        String grade
    ) {}

    public List<DeviceResult> getDevices() { return devices; }
    public void setDevices(List<DeviceResult> devices) { this.devices = devices; }
}
