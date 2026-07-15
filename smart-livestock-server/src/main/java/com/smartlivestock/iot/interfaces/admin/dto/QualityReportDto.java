package com.smartlivestock.iot.interfaces.admin.dto;

import com.smartlivestock.iot.application.GpsQualityReportService;
import com.smartlivestock.iot.domain.port.dto.GpsQualityStats;

import java.util.List;

/**
 * Single-device GPS quality report: computed statistics plus per-point scatter.
 */
public class QualityReportDto {

    private Long sessionId;
    private Long rtkPointId;
    private String locationName;
    private String label;
    private Long deviceId;
    private String deviceCode;
    private boolean excludeSuspect;
    private GpsQualityStats stats;
    private List<GpsQualityReportService.ScatterPoint> scatter;

    public QualityReportDto() {
    }

    public static QualityReportDto from(GpsQualityReportService.ReportResult r) {
        QualityReportDto dto = new QualityReportDto();
        dto.sessionId = r.session().getId();
        dto.rtkPointId = r.rtk().getId();
        dto.locationName = r.rtk().getLocationName();
        dto.label = r.rtk().getPointLabel();
        dto.deviceId = r.session().getDeviceId();
        dto.deviceCode = r.deviceCode();
        dto.excludeSuspect = r.excludeSuspect();
        dto.stats = r.stats();
        dto.scatter = r.scatter();
        return dto;
    }

    public Long getSessionId() { return sessionId; }
    public void setSessionId(Long sessionId) { this.sessionId = sessionId; }

    public Long getRtkPointId() { return rtkPointId; }
    public void setRtkPointId(Long rtkPointId) { this.rtkPointId = rtkPointId; }

    public String getLocationName() { return locationName; }
    public void setLocationName(String locationName) { this.locationName = locationName; }

    public String getLabel() { return label; }
    public void setLabel(String label) { this.label = label; }

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }

    public String getDeviceCode() { return deviceCode; }
    public void setDeviceCode(String deviceCode) { this.deviceCode = deviceCode; }

    public boolean isExcludeSuspect() { return excludeSuspect; }
    public void setExcludeSuspect(boolean excludeSuspect) { this.excludeSuspect = excludeSuspect; }

    public GpsQualityStats getStats() { return stats; }
    public void setStats(GpsQualityStats stats) { this.stats = stats; }

    public List<GpsQualityReportService.ScatterPoint> getScatter() { return scatter; }
    public void setScatter(List<GpsQualityReportService.ScatterPoint> scatter) { this.scatter = scatter; }
}
