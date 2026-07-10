package com.smartlivestock.health.domain.model;

import java.math.BigDecimal;
import java.time.Instant;

public class ActivityLog {

    private Long id;
    private Long livestockId;
    private Long deviceId;
    private Integer stepCount;
    private BigDecimal activityIndex;
    private BigDecimal distanceMeters;
    private Instant recordedAt;
    private Instant createdAt;

    public ActivityLog() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getLivestockId() { return livestockId; }
    public void setLivestockId(Long livestockId) { this.livestockId = livestockId; }

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }

    public Integer getStepCount() { return stepCount; }
    public void setStepCount(Integer stepCount) { this.stepCount = stepCount; }

    public BigDecimal getActivityIndex() { return activityIndex; }
    public void setActivityIndex(BigDecimal activityIndex) { this.activityIndex = activityIndex; }

    public BigDecimal getDistanceMeters() { return distanceMeters; }
    public void setDistanceMeters(BigDecimal distanceMeters) { this.distanceMeters = distanceMeters; }

    public Instant getRecordedAt() { return recordedAt; }
    public void setRecordedAt(Instant recordedAt) { this.recordedAt = recordedAt; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
