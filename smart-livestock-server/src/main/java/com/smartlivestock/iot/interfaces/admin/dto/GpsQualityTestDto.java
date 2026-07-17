package com.smartlivestock.iot.interfaces.admin.dto;

import com.smartlivestock.iot.domain.model.GpsQualityTest;

import java.time.Instant;

public class GpsQualityTestDto {

    private Long id;
    private Long sessionId;
    private String testType;
    private Long rtkPointId;
    private Long routeId;
    private Instant testStartedAt;
    private Instant testEndedAt;
    private Instant createdAt;

    public GpsQualityTestDto() {}

    public static GpsQualityTestDto from(GpsQualityTest t) {
        GpsQualityTestDto dto = new GpsQualityTestDto();
        dto.id = t.getId();
        dto.sessionId = t.getSessionId();
        dto.testType = t.getTestType() != null ? t.getTestType().name() : "STATIC";
        dto.rtkPointId = t.getRtkPointId();
        dto.routeId = t.getRouteId();
        dto.testStartedAt = t.getTestStartedAt();
        dto.testEndedAt = t.getTestEndedAt();
        dto.createdAt = t.getCreatedAt();
        return dto;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getSessionId() { return sessionId; }
    public void setSessionId(Long sessionId) { this.sessionId = sessionId; }
    public String getTestType() { return testType; }
    public void setTestType(String testType) { this.testType = testType; }
    public Long getRtkPointId() { return rtkPointId; }
    public void setRtkPointId(Long rtkPointId) { this.rtkPointId = rtkPointId; }
    public Long getRouteId() { return routeId; }
    public void setRouteId(Long routeId) { this.routeId = routeId; }
    public Instant getTestStartedAt() { return testStartedAt; }
    public void setTestStartedAt(Instant testStartedAt) { this.testStartedAt = testStartedAt; }
    public Instant getTestEndedAt() { return testEndedAt; }
    public void setTestEndedAt(Instant testEndedAt) { this.testEndedAt = testEndedAt; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
