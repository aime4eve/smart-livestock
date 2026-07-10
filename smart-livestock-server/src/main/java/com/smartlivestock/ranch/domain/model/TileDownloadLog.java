package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.shared.domain.Entity;
import java.time.Instant;

public class TileDownloadLog extends Entity {
    private Long farmTileTaskId;
    private Long userId;
    private String deviceInfo;
    private Long bytesDownloaded;
    private Instant startedAt;
    private Instant finishedAt;

    public TileDownloadLog() {}
    public TileDownloadLog(Long farmTileTaskId, Long userId) {
        this.farmTileTaskId = farmTileTaskId;
        this.userId = userId;
        this.startedAt = Instant.now();
    }

    public Long getFarmTileTaskId() { return farmTileTaskId; } public void setFarmTileTaskId(Long v) { farmTileTaskId = v; }
    public Long getUserId() { return userId; } public void setUserId(Long v) { userId = v; }
    public String getDeviceInfo() { return deviceInfo; } public void setDeviceInfo(String v) { deviceInfo = v; }
    public Long getBytesDownloaded() { return bytesDownloaded; } public void setBytesDownloaded(Long v) { bytesDownloaded = v; }
    public Instant getStartedAt() { return startedAt; } public void setStartedAt(Instant v) { startedAt = v; }
    public Instant getFinishedAt() { return finishedAt; } public void setFinishedAt(Instant v) { finishedAt = v; }
}
