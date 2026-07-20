package com.smartlivestock.iot.interfaces.admin.dto;

import java.time.Instant;
import java.util.List;

/**
 * Multi-device dynamic comparison response for a single dynamic test route.
 * Each device contributes its latest READY dynamic test on the route.
 */
public class DynamicComparisonDto {

    private Long routeId;
    private String routeName;
    private List<DeviceSummary> devices;

    public DynamicComparisonDto() {
    }

    public Long getRouteId() { return routeId; }
    public void setRouteId(Long routeId) { this.routeId = routeId; }

    public String getRouteName() { return routeName; }
    public void setRouteName(String routeName) { this.routeName = routeName; }

    public List<DeviceSummary> getDevices() { return devices; }
    public void setDevices(List<DeviceSummary> devices) { this.devices = devices; }

    public record DeviceSummary(Long deviceId, String deviceCode, Long checkId,
                                double coverage, int matchedCount, int missedCount,
                                int ambiguousCount, boolean inOrder,
                                double meanError, double p50, double p95,
                                Instant startedAt, Instant endedAt) {
    }
}
