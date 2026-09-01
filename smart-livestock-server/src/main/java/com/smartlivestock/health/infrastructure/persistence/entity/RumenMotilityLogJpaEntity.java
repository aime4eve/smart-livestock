package com.smartlivestock.health.infrastructure.persistence.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "rumen_motility_logs")
public class RumenMotilityLogJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "livestock_id")
    private Long livestockId;

    @Column(name = "device_id", nullable = false)
    private Long deviceId;

    @Column(name = "frequency", precision = 5, scale = 2)
    private BigDecimal frequency;

    @Column(name = "intensity", precision = 5, scale = 2)
    private BigDecimal intensity;

    @Column(name = "raw_counter")
    private Long rawCounter;

    @Column(name = "counter_delta")
    private Long counterDelta;

    @Column(name = "recorded_at", nullable = false)
    private Instant recordedAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "source", nullable = false, length = 20)
    private String source = "UNKNOWN";

    @PrePersist
    protected void onCreate() { this.createdAt = Instant.now(); }

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
