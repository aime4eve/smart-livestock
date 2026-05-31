package com.smartlivestock.health.domain.model;

import java.math.BigDecimal;
import java.time.Instant;

public class ContactTrace {

    private Long id;
    private Long farmId;
    private Long fromLivestockId;
    private Long toLivestockId;
    private BigDecimal proximityMeters;
    private Integer contactDurationMinutes;
    private Instant lastContactAt;
    private Instant createdAt;

    public ContactTrace() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getFarmId() { return farmId; }
    public void setFarmId(Long farmId) { this.farmId = farmId; }

    public Long getFromLivestockId() { return fromLivestockId; }
    public void setFromLivestockId(Long fromLivestockId) { this.fromLivestockId = fromLivestockId; }

    public Long getToLivestockId() { return toLivestockId; }
    public void setToLivestockId(Long toLivestockId) { this.toLivestockId = toLivestockId; }

    public BigDecimal getProximityMeters() { return proximityMeters; }
    public void setProximityMeters(BigDecimal proximityMeters) { this.proximityMeters = proximityMeters; }

    public Integer getContactDurationMinutes() { return contactDurationMinutes; }
    public void setContactDurationMinutes(Integer contactDurationMinutes) { this.contactDurationMinutes = contactDurationMinutes; }

    public Instant getLastContactAt() { return lastContactAt; }
    public void setLastContactAt(Instant lastContactAt) { this.lastContactAt = lastContactAt; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
