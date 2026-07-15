package com.smartlivestock.iot.interfaces.admin.dto;

import com.smartlivestock.iot.application.GpsQualityReportService;

import java.util.List;

/**
 * Multi-device comparison response for a single RTK reference point.
 */
public class ComparisonDto {

    private Long rtkPointId;
    private String locationName;
    private String label;
    private List<DeviceSummary> devices;

    public ComparisonDto() {
    }

    public static ComparisonDto from(GpsQualityReportService.ComparisonResult r) {
        ComparisonDto dto = new ComparisonDto();
        dto.rtkPointId = r.rtk().getId();
        dto.locationName = r.rtk().getLocationName();
        dto.label = r.rtk().getPointLabel();
        dto.devices = r.entries().stream()
                .map(e -> new DeviceSummary(
                        e.sessionId(),
                        e.deviceId(),
                        e.deviceCode(),
                        e.stats().grade().name(),
                        e.stats().p95(),
                        e.stats().meanError(),
                        e.stats().effectivePoints()))
                .toList();
        return dto;
    }

    public Long getRtkPointId() { return rtkPointId; }
    public void setRtkPointId(Long rtkPointId) { this.rtkPointId = rtkPointId; }

    public String getLocationName() { return locationName; }
    public void setLocationName(String locationName) { this.locationName = locationName; }

    public String getLabel() { return label; }
    public void setLabel(String label) { this.label = label; }

    public List<DeviceSummary> getDevices() { return devices; }
    public void setDevices(List<DeviceSummary> devices) { this.devices = devices; }

    public record DeviceSummary(Long sessionId, Long deviceId, String deviceCode,
                                String grade, double p95, double meanError, int effectivePoints) {
    }
}
