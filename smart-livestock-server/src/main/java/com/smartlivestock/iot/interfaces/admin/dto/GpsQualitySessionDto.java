package com.smartlivestock.iot.interfaces.admin.dto;

import com.smartlivestock.iot.domain.model.GpsQualitySession;
import com.smartlivestock.iot.domain.model.SessionStatus;

import java.time.Instant;

public class GpsQualitySessionDto {

    private Long id;
    private Long deviceId;
    private String deviceCode;
    private Instant startedAt;
    private Instant endedAt;
    private String status;
    private String note;
    private Instant createdAt;

    public GpsQualitySessionDto() {}

    public static GpsQualitySessionDto from(GpsQualitySession s, String deviceCode) {
        GpsQualitySessionDto dto = new GpsQualitySessionDto();
        dto.id = s.getId();
        dto.deviceId = s.getDeviceId();
        dto.deviceCode = deviceCode;
        dto.startedAt = s.getStartedAt();
        dto.endedAt = s.getEndedAt();
        dto.status = s.getStatus() != null ? s.getStatus().name() : SessionStatus.IN_PROGRESS.name();
        dto.note = s.getNote();
        dto.createdAt = s.getCreatedAt();
        return dto;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }
    public String getDeviceCode() { return deviceCode; }
    public void setDeviceCode(String deviceCode) { this.deviceCode = deviceCode; }
    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }
    public Instant getEndedAt() { return endedAt; }
    public void setEndedAt(Instant endedAt) { this.endedAt = endedAt; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
