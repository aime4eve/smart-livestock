package com.smartlivestock.health.domain.model;

import java.math.BigDecimal;
import java.time.Instant;

public class TemperatureLog {

    private Long id;
    private Long livestockId;
    private Long deviceId;
    private BigDecimal temperature;
    private BigDecimal baselineTemp;
    private BigDecimal delta;
    private Instant recordedAt;
    private Instant createdAt;

    public TemperatureLog() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getLivestockId() { return livestockId; }
    public void setLivestockId(Long livestockId) { this.livestockId = livestockId; }

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }

    public BigDecimal getTemperature() { return temperature; }
    public void setTemperature(BigDecimal temperature) { this.temperature = temperature; }

    public BigDecimal getBaselineTemp() { return baselineTemp; }
    public void setBaselineTemp(BigDecimal baselineTemp) { this.baselineTemp = baselineTemp; }

    public BigDecimal getDelta() { return delta; }
    public void setDelta(BigDecimal delta) { this.delta = delta; }

    public Instant getRecordedAt() { return recordedAt; }
    public void setRecordedAt(Instant recordedAt) { this.recordedAt = recordedAt; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
