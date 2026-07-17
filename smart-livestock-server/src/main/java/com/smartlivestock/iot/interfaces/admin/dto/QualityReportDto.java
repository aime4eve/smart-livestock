package com.smartlivestock.iot.interfaces.admin.dto;

import com.smartlivestock.iot.application.GpsQualityReportService;
import com.smartlivestock.iot.domain.model.QualityGrade;
import com.smartlivestock.iot.domain.port.dto.GpsQualityStats;

import java.util.List;

/**
 * Single-device GPS quality report: computed statistics plus per-point scatter.
 */
public class QualityReportDto {

    private Long testId;
    private Long rtkPointId;
    private String locationName;
    private String label;
    private java.math.BigDecimal rtkLatitude;
    private java.math.BigDecimal rtkLongitude;
    private Long deviceId;
    private String deviceCode;
    private boolean excludeSuspect;
    private QualityGrade grade;
    private GpsQualityStats stats;
    private List<GpsQualityReportService.ScatterPoint> scatter;

    public QualityReportDto() {
    }

    public static QualityReportDto from(GpsQualityReportService.ReportResult r) {
        QualityReportDto dto = new QualityReportDto();
        dto.testId = r.test().getId();
        dto.rtkPointId = r.rtk().getId();
        dto.locationName = r.rtk().getLocationName();
        dto.label = r.rtk().getPointLabel();
        dto.rtkLatitude = r.rtk().getLatitude();
        dto.rtkLongitude = r.rtk().getLongitude();
        dto.deviceId = r.session().getDeviceId();
        dto.deviceCode = r.deviceCode();
        dto.excludeSuspect = r.excludeSuspect();
        dto.grade = r.stats().grade();
        dto.stats = r.stats();
        dto.scatter = r.scatter();
        return dto;
    }

    public Long getTestId() { return testId; }
    public void setTestId(Long testId) { this.testId = testId; }

    public Long getRtkPointId() { return rtkPointId; }
    public void setRtkPointId(Long rtkPointId) { this.rtkPointId = rtkPointId; }

    public String getLocationName() { return locationName; }
    public void setLocationName(String locationName) { this.locationName = locationName; }

    public String getLabel() { return label; }
    public void setLabel(String label) { this.label = label; }

    public java.math.BigDecimal getRtkLatitude() { return rtkLatitude; }
    public void setRtkLatitude(java.math.BigDecimal rtkLatitude) { this.rtkLatitude = rtkLatitude; }

    public java.math.BigDecimal getRtkLongitude() { return rtkLongitude; }
    public void setRtkLongitude(java.math.BigDecimal rtkLongitude) { this.rtkLongitude = rtkLongitude; }

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }

    public String getDeviceCode() { return deviceCode; }
    public void setDeviceCode(String deviceCode) { this.deviceCode = deviceCode; }

    public boolean isExcludeSuspect() { return excludeSuspect; }
    public void setExcludeSuspect(boolean excludeSuspect) { this.excludeSuspect = excludeSuspect; }

    public QualityGrade getGrade() { return grade; }
    public void setGrade(QualityGrade grade) { this.grade = grade; }

    public GpsQualityStats getStats() { return stats; }
    public void setStats(GpsQualityStats stats) { this.stats = stats; }

    public List<GpsQualityReportService.ScatterPoint> getScatter() { return scatter; }
    public void setScatter(List<GpsQualityReportService.ScatterPoint> scatter) { this.scatter = scatter; }
}
