package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.shared.domain.AggregateRoot;
import java.time.Instant;

public class TileGenerationTask extends AggregateRoot {
    private Long regionId;
    private double minLon, minLat, maxLon, maxLat;
    private int minZoom = 11, maxZoom = 15;
    private String regionName, status = "pending", triggeredBy, errorMessage;
    private Integer tileCount;
    private Double fileSizeMb, coverageRatio;
    private boolean customRegion = false;
    private Instant startedAt, finishedAt, createdAt;
    private String progress;

    public TileGenerationTask() {}
    public TileGenerationTask(String regionName, double minLon, double minLat,
                              double maxLon, double maxLat, int minZoom, int maxZoom) {
        this.regionName = regionName; this.minLon = minLon; this.minLat = minLat;
        this.maxLon = maxLon; this.maxLat = maxLat;
        this.minZoom = minZoom; this.maxZoom = maxZoom;
    }

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
    public String getErrorMessage() { return errorMessage; } public void setErrorMessage(String v) { errorMessage = v; }
    public Integer getTileCount() { return tileCount; } public void setTileCount(Integer v) { tileCount = v; }
    public Double getFileSizeMb() { return fileSizeMb; } public void setFileSizeMb(Double v) { fileSizeMb = v; }
    public Double getCoverageRatio() { return coverageRatio; } public void setCoverageRatio(Double v) { coverageRatio = v; }
    public boolean isCustomRegion() { return customRegion; } public void setCustomRegion(boolean v) { customRegion = v; }
    public Instant getStartedAt() { return startedAt; } public void setStartedAt(Instant v) { startedAt = v; }
    public Instant getFinishedAt() { return finishedAt; } public void setFinishedAt(Instant v) { finishedAt = v; }
    public Instant getCreatedAt() { return createdAt; } public void setCreatedAt(Instant v) { createdAt = v; }
    public String getProgress() { return progress; } public void setProgress(String v) { progress = v; }
}
