package com.smartlivestock.ranch.infrastructure.persistence.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "tile_generation_tasks")
public class TileGenerationTaskJpaEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "region_id") private Long regionId;
    @Column(name = "min_lon", nullable = false) private double minLon;
    @Column(name = "min_lat", nullable = false) private double minLat;
    @Column(name = "max_lon", nullable = false) private double maxLon;
    @Column(name = "max_lat", nullable = false) private double maxLat;
    @Column(name = "min_zoom", nullable = false) private int minZoom = 11;
    @Column(name = "max_zoom", nullable = false) private int maxZoom = 15;
    @Column(name = "region_name", nullable = false, length = 100) private String regionName;
    @Column(name = "status", nullable = false, length = 20) private String status = "pending";
    @Column(name = "triggered_by", length = 50) private String triggeredBy;
    @Column(name = "tile_count") private Integer tileCount;
    @Column(name = "file_size_mb") private Double fileSizeMb;
    @Column(name = "error_message", columnDefinition = "TEXT") private String errorMessage;
    @Column(name = "coverage_ratio") private Double coverageRatio;
    @Column(name = "progress", length = 100) private String progress;
    @Column(name = "is_custom_region", nullable = false) private boolean customRegion = false;
    @Column(name = "started_at") private Instant startedAt;
    @Column(name = "finished_at") private Instant finishedAt;
    @Column(name = "created_at", nullable = false) private Instant createdAt;

    @PrePersist protected void onCreate() { this.createdAt = Instant.now(); }

    public Long getId() { return id; } public void setId(Long id) { this.id = id; }
    public Long getRegionId() { return regionId; } public void setRegionId(Long v) { regionId = v; }
    public double getMinLon() { return minLon; } public void setMinLon(double v) { minLon = v; }
    public double getMinLat() { return minLat; } public void setMinLat(double v) { minLat = v; }
    public double getMaxLon() { return maxLon; } public void setMaxLon(double v) { maxLon = v; }
    public double getMaxLat() { return maxLat; } public void setMaxLat(double v) { maxLat = v; }
    public int getMinZoom() { return minZoom; } public void setMinZoom(int v) { minZoom = v; }
    public int getMaxZoom() { return maxZoom; } public void setMaxZoom(int v) { maxZoom = v; }
    public String getRegionName() { return regionName; } public void setRegionName(String v) { regionName = v; }
    public String getStatus() { return status; } public void setStatus(String v) { status = v; }
    public String getTriggeredBy() { return triggeredBy; } public void setTriggeredBy(String v) { triggeredBy = v; }
    public Integer getTileCount() { return tileCount; } public void setTileCount(Integer v) { tileCount = v; }
    public Double getFileSizeMb() { return fileSizeMb; } public void setFileSizeMb(Double v) { fileSizeMb = v; }
    public String getErrorMessage() { return errorMessage; } public void setErrorMessage(String v) { errorMessage = v; }
    public Double getCoverageRatio() { return coverageRatio; } public void setCoverageRatio(Double v) { coverageRatio = v; }
    public String getProgress() { return progress; } public void setProgress(String v) { progress = v; }
    public boolean isCustomRegion() { return customRegion; } public void setCustomRegion(boolean v) { customRegion = v; }
    public Instant getStartedAt() { return startedAt; } public void setStartedAt(Instant v) { startedAt = v; }
    public Instant getFinishedAt() { return finishedAt; } public void setFinishedAt(Instant v) { finishedAt = v; }
    public Instant getCreatedAt() { return createdAt; } public void setCreatedAt(Instant v) { createdAt = v; }
}
