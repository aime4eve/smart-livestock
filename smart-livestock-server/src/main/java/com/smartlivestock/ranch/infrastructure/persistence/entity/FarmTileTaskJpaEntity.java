package com.smartlivestock.ranch.infrastructure.persistence.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "farm_tile_tasks")
public class FarmTileTaskJpaEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "farm_id", nullable = false) private Long farmId;
    @Column(name = "region_id", nullable = false) private Long regionId;
    @Column(name = "status", nullable = false, length = 30) private String status = "pending";
    @Column(name = "file_size") private Long fileSize;
    @Column(name = "requested_at", nullable = false) private Instant requestedAt;
    @Column(name = "completed_at") private Instant completedAt;
    @Column(name = "created_at", nullable = false) private Instant createdAt;
    @Column(name = "updated_at", nullable = false) private Instant updatedAt;

    @PrePersist protected void onCreate() { Instant now = Instant.now(); this.createdAt = now; this.updatedAt = now; this.requestedAt = now; }
    @PreUpdate protected void onUpdate() { this.updatedAt = Instant.now(); }

    public Long getId() { return id; } public void setId(Long id) { this.id = id; }
    public Long getFarmId() { return farmId; } public void setFarmId(Long v) { farmId = v; }
    public Long getRegionId() { return regionId; } public void setRegionId(Long v) { regionId = v; }
    public String getStatus() { return status; } public void setStatus(String v) { status = v; }
    public Long getFileSize() { return fileSize; } public void setFileSize(Long v) { fileSize = v; }
    public Instant getRequestedAt() { return requestedAt; } public void setRequestedAt(Instant v) { requestedAt = v; }
    public Instant getCompletedAt() { return completedAt; } public void setCompletedAt(Instant v) { completedAt = v; }
    public Instant getCreatedAt() { return createdAt; } public void setCreatedAt(Instant v) { createdAt = v; }
    public Instant getUpdatedAt() { return updatedAt; } public void setUpdatedAt(Instant v) { updatedAt = v; }
}
