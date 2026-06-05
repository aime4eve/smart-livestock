package com.smartlivestock.iot.domain.event;

import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.shared.domain.DomainEvent;

import java.time.Instant;
import java.util.Map;

/**
 * Domain event fired when telemetry data is received from any device type.
 * Replaces SensorTelemetryReceivedEvent with a generic readings Map
 * that accommodates both TRACKER and CAPSULE (and future device types).
 * <p>
 * Published by TelemetryIngestionService (IoT), consumed via RocketMQ topic "telemetry-received".
 */
public class TelemetryReceivedEvent extends DomainEvent {

    private final Long deviceId;
    private final Long livestockId;
    private final Long farmId;
    private final DeviceType deviceType;
    private final Map<String, Object> readings;
    private final Instant recordedAt;

    public TelemetryReceivedEvent(Long deviceId, Long livestockId, Long farmId,
                                   DeviceType deviceType,
                                   Map<String, Object> readings,
                                   Instant recordedAt) {
        this.deviceId = deviceId;
        this.livestockId = livestockId;
        this.farmId = farmId;
        this.deviceType = deviceType;
        this.readings = readings;
        this.recordedAt = recordedAt;
    }

    public Long getDeviceId() { return deviceId; }
    public Long getLivestockId() { return livestockId; }
    public Long getFarmId() { return farmId; }
    public DeviceType getDeviceType() { return deviceType; }
    public Map<String, Object> getReadings() { return readings; }
    public Instant getRecordedAt() { return recordedAt; }
}
