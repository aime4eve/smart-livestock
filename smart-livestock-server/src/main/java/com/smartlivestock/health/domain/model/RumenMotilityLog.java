package com.smartlivestock.health.domain.model;

import java.math.BigDecimal;
import java.time.Instant;

public class RumenMotilityLog {

    private Long id;
    private Long livestockId;
    private Long deviceId;
    private BigDecimal frequency;
    private BigDecimal intensity;
    private Long rawCounter;
    private Long counterDelta;
    private Instant recordedAt;
    private Instant createdAt;
    private String source;

    public RumenMotilityLog() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getLivestockId() { return livestockId; }
    public void setLivestockId(Long livestockId) { this.livestockId = livestockId; }

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }

    public BigDecimal getFrequency() { return frequency; }
    public void setFrequency(BigDecimal frequency) { this.frequency = frequency; }

    public BigDecimal getIntensity() { return intensity; }
    public void setIntensity(BigDecimal intensity) { this.intensity = intensity; }

    public Long getRawCounter() { return rawCounter; }
    public void setRawCounter(Long rawCounter) { this.rawCounter = rawCounter; }

    public Long getCounterDelta() { return counterDelta; }
    public void setCounterDelta(Long counterDelta) { this.counterDelta = counterDelta; }

    public Instant getRecordedAt() { return recordedAt; }
    public void setRecordedAt(Instant recordedAt) { this.recordedAt = recordedAt; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }
}
