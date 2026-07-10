package com.smartlivestock.iot.domain.event;

import com.smartlivestock.shared.domain.DomainEvent;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Domain event fired when a GPS log is recorded.
 */
public class GpsLogUpdatedEvent extends DomainEvent {

    private final Long deviceId;
    private final BigDecimal latitude;
    private final BigDecimal longitude;
    private final Instant recordedAt;

    public GpsLogUpdatedEvent(Long deviceId, BigDecimal latitude, BigDecimal longitude, Instant recordedAt) {
        this.deviceId = deviceId;
        this.latitude = latitude;
        this.longitude = longitude;
        this.recordedAt = recordedAt;
    }

    public Long getDeviceId() { return deviceId; }
    public BigDecimal getLatitude() { return latitude; }
    public BigDecimal getLongitude() { return longitude; }
    public Instant getRecordedAt() { return recordedAt; }
}
