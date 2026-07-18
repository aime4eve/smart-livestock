package com.smartlivestock.iot.interfaces.admin.dto;

import com.smartlivestock.iot.domain.model.GpsQualityTest;

import java.time.Instant;

public class GpsQualityTestDto {

    private Long id;
    private String deviceCode;
    private Long deviceId;
    private String testType;
    private Long rtkPointId;
    private Long routeId;
    private Instant startedAt;
    private Instant endedAt;
    private String status;
    private String errorMessage;
    private Long batchImportId;
    private Instant createdAt;

    public GpsQualityTestDto() {}

    public static GpsQualityTestDto from(GpsQualityTest t) {
        GpsQualityTestDto dto = new GpsQualityTestDto();
        dto.id = t.getId();
        dto.deviceCode = t.getDeviceCode();
        dto.deviceId = t.getDeviceId();
        dto.testType = t.getTestType() != null ? t.getTestType().name() : "STATIC";
        dto.rtkPointId = t.getRtkPointId();
        dto.routeId = t.getRouteId();
        dto.startedAt = t.getStartedAt();
        dto.endedAt = t.getEndedAt();
        dto.status = t.getStatus();
        dto.errorMessage = t.getErrorMessage();
        dto.batchImportId = t.getBatchImportId();
        dto.createdAt = t.getCreatedAt();
        return dto;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getDeviceCode() { return deviceCode; }
    public void setDeviceCode(String deviceCode) { this.deviceCode = deviceCode; }
    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }
    public String getTestType() { return testType; }
    public void setTestType(String testType) { this.testType = testType; }
    public Long getRtkPointId() { return rtkPointId; }
    public void setRtkPointId(Long rtkPointId) { this.rtkPointId = rtkPointId; }
    public Long getRouteId() { return routeId; }
    public void setRouteId(Long routeId) { this.routeId = routeId; }
    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }
    public Instant getEndedAt() { return endedAt; }
    public void setEndedAt(Instant endedAt) { this.endedAt = endedAt; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getErrorMessage() { return errorMessage; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }
    public Long getBatchImportId() { return batchImportId; }
    public void setBatchImportId(Long batchImportId) { this.batchImportId = batchImportId; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
