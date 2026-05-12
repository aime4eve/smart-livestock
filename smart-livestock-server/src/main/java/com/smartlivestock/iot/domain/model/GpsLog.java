package com.smartlivestock.iot.domain.model;

import com.smartlivestock.shared.domain.Entity;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * GpsLog entity representing a single GPS position record from a device.
 * <p>
 * Simple value object / entity for GPS telemetry data.
 */
public class GpsLog extends Entity {

    private Long deviceId;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private BigDecimal accuracy;
    private Instant recordedAt;

    public GpsLog() {
    }

    public GpsLog(Long deviceId, BigDecimal latitude, BigDecimal longitude,
                  BigDecimal accuracy, Instant recordedAt) {
        this.deviceId = deviceId;
        this.latitude = latitude;
        this.longitude = longitude;
        this.accuracy = accuracy;
        this.recordedAt = recordedAt;
    }

    // --- Getters and Setters ---

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }

    public BigDecimal getLatitude() { return latitude; }
    public void setLatitude(BigDecimal latitude) { this.latitude = latitude; }

    public BigDecimal getLongitude() { return longitude; }
    public void setLongitude(BigDecimal longitude) { this.longitude = longitude; }

    public BigDecimal getAccuracy() { return accuracy; }
    public void setAccuracy(BigDecimal accuracy) { this.accuracy = accuracy; }

    public Instant getRecordedAt() { return recordedAt; }
    public void setRecordedAt(Instant recordedAt) { this.recordedAt = recordedAt; }
}
