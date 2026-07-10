package com.smartlivestock.ranch.infrastructure.persistence.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "tile_download_logs")
public class TileDownloadLogJpaEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "farm_tile_task_id", nullable = false) private Long farmTileTaskId;
    @Column(name = "user_id", nullable = false) private Long userId;
    @Column(name = "device_info") private String deviceInfo;
    @Column(name = "bytes_downloaded") private Long bytesDownloaded;
    @Column(name = "started_at", nullable = false) private Instant startedAt;
    @Column(name = "finished_at") private Instant finishedAt;

    @PrePersist protected void onCreate() { this.startedAt = Instant.now(); }

    public Long getId() { return id; } public void setId(Long id) { this.id = id; }
    public Long getFarmTileTaskId() { return farmTileTaskId; } public void setFarmTileTaskId(Long v) { farmTileTaskId = v; }
    public Long getUserId() { return userId; } public void setUserId(Long v) { userId = v; }
    public String getDeviceInfo() { return deviceInfo; } public void setDeviceInfo(String v) { deviceInfo = v; }
    public Long getBytesDownloaded() { return bytesDownloaded; } public void setBytesDownloaded(Long v) { bytesDownloaded = v; }
    public Instant getStartedAt() { return startedAt; } public void setStartedAt(Instant v) { startedAt = v; }
    public Instant getFinishedAt() { return finishedAt; } public void setFinishedAt(Instant v) { finishedAt = v; }
}
