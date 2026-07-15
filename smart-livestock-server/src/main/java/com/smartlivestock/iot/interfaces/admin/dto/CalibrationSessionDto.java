package com.smartlivestock.iot.interfaces.admin.dto;

import com.smartlivestock.iot.domain.model.RtkCalibrationSession;

import java.time.Instant;

/**
 * Calibration session request/response DTO. On create only
 * {@code rtkPointId/deviceId/startedAt/endedAt} are used.
 */
public class CalibrationSessionDto {

    private Long id;
    private Long rtkPointId;
    private Long deviceId;
    private String deviceCode;
    private Instant startedAt;
    private Instant endedAt;
    private String status;
    private Instant createdAt;

    public CalibrationSessionDto() {
    }

    public static CalibrationSessionDto from(RtkCalibrationSession s, String deviceCode) {
        CalibrationSessionDto dto = new CalibrationSessionDto();
        dto.id = s.getId();
        dto.rtkPointId = s.getRtkPointId();
        dto.deviceId = s.getDeviceId();
        dto.deviceCode = deviceCode;
        dto.startedAt = s.getStartedAt();
        dto.endedAt = s.getEndedAt();
        dto.status = s.getStatus() != null ? s.getStatus().name() : null;
        dto.createdAt = s.getCreatedAt();
        return dto;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getRtkPointId() { return rtkPointId; }
    public void setRtkPointId(Long rtkPointId) { this.rtkPointId = rtkPointId; }

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

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
