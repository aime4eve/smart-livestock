package com.smartlivestock.datagen.domain.model;

import com.smartlivestock.shared.domain.Entity;

import java.time.Instant;

public class DatagenDeviceAssignment extends Entity {
    private Long controlId;
    private Long deviceId;
    private Instant firstAssignedAt;
    private Instant createdAt;
    private Instant removedAt;

    public boolean isActive() { return removedAt == null; }

    public void activate() { this.removedAt = null; }

    public void deactivate(Instant removedAt) { this.removedAt = removedAt; }

    public Long getControlId() { return controlId; }
    public void setControlId(Long controlId) { this.controlId = controlId; }

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }

    public Instant getFirstAssignedAt() { return firstAssignedAt; }
    public void setFirstAssignedAt(Instant firstAssignedAt) { this.firstAssignedAt = firstAssignedAt; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getRemovedAt() { return removedAt; }
    public void setRemovedAt(Instant removedAt) { this.removedAt = removedAt; }
}
