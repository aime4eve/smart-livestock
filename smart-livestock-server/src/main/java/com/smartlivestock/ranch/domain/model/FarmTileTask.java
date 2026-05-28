package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.shared.domain.Entity;
import java.time.Instant;

public class FarmTileTask extends Entity {
    private Long farmId;
    private Long regionId;
    private String status = "pending";
    private Long fileSize;
    private Instant requestedAt;
    private Instant completedAt;

    public FarmTileTask() {}
    public FarmTileTask(Long farmId, Long regionId) {
        this.farmId = farmId;
        this.regionId = regionId;
        this.requestedAt = Instant.now();
    }

    public Long getFarmId() { return farmId; } public void setFarmId(Long v) { farmId = v; }
    public Long getRegionId() { return regionId; } public void setRegionId(Long v) { regionId = v; }
    public String getStatus() { return status; } public void setStatus(String v) { status = v; }
    public Long getFileSize() { return fileSize; } public void setFileSize(Long v) { fileSize = v; }
    public Instant getRequestedAt() { return requestedAt; } public void setRequestedAt(Instant v) { requestedAt = v; }
    public Instant getCompletedAt() { return completedAt; } public void setCompletedAt(Instant v) { completedAt = v; }
}
