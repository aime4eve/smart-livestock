package com.smartlivestock.iot.domain.event;

import com.smartlivestock.shared.domain.DomainEvent;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Domain event fired when a GPS log is recorded.
 * <p>
 * The {@code source} carries the {@code TelemetrySource} name (e.g.
 * AGENTIC_PLATFORM, MANUAL_IMPORT). Consumers must treat a missing/null
 * source as AGENTIC_PLATFORM so in-flight messages published before this
 * field existed keep their original behavior.
 */
public class GpsLogUpdatedEvent extends DomainEvent {

    private final Long deviceId;
    private final BigDecimal latitude;
    private final BigDecimal longitude;
    private final Instant recordedAt;
    private final String source;

    public GpsLogUpdatedEvent(Long deviceId, BigDecimal latitude, BigDecimal longitude,
                              Instant recordedAt, String source) {
        this.deviceId = deviceId;
        this.latitude = latitude;
        this.longitude = longitude;
        this.recordedAt = recordedAt;
        this.source = source;
    }

    public Long getDeviceId() { return deviceId; }
    public BigDecimal getLatitude() { return latitude; }
    public BigDecimal getLongitude() { return longitude; }
    public Instant getRecordedAt() { return recordedAt; }
    public String getSource() { return source; }
}
