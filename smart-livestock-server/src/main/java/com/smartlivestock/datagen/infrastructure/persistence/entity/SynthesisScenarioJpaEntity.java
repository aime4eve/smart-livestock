package com.smartlivestock.datagen.infrastructure.persistence.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "synthesis_scenarios")
public class SynthesisScenarioJpaEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "name", nullable = false, length = 100)
    private String name;
    @Column(name = "status", nullable = false, length = 20)
    private String status;
    @Column(name = "type", nullable = false, length = 40)
    private String type;
    @Column(name = "penetration_rate", precision = 3, scale = 2)
    private BigDecimal penetrationRate;
    @Column(name = "window_start", nullable = false)
    private Instant windowStart;
    @Column(name = "window_end", nullable = false)
    private Instant windowEnd;
    @Column(name = "interval_seconds")
    private Integer intervalSeconds;
    @Column(name = "target_livestock_ids", columnDefinition = "text")
    private String targetLivestockIds;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    protected void onCreate() { Instant now = Instant.now(); this.createdAt = now; this.updatedAt = now; }
    @PreUpdate
    protected void onUpdate() { this.updatedAt = Instant.now(); }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public BigDecimal getPenetrationRate() { return penetrationRate; }
    public void setPenetrationRate(BigDecimal penetrationRate) { this.penetrationRate = penetrationRate; }
    public Instant getWindowStart() { return windowStart; }
    public void setWindowStart(Instant windowStart) { this.windowStart = windowStart; }
    public Instant getWindowEnd() { return windowEnd; }
    public void setWindowEnd(Instant windowEnd) { this.windowEnd = windowEnd; }
    public Integer getIntervalSeconds() { return intervalSeconds; }
    public void setIntervalSeconds(Integer intervalSeconds) { this.intervalSeconds = intervalSeconds; }
    public String getTargetLivestockIds() { return targetLivestockIds; }
    public void setTargetLivestockIds(String targetLivestockIds) { this.targetLivestockIds = targetLivestockIds; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
