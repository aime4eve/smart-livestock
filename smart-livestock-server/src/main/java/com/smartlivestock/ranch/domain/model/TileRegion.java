package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.shared.domain.AggregateRoot;
import java.time.Instant;

public class TileRegion extends AggregateRoot {
    private String name;
    private double minLon, minLat, maxLon, maxLat;
    private int minZoom = 11, maxZoom = 15;
    private String fileName;
    private Long fileSize;
    private String md5;
    private Instant generatedAt;
    private String status = "pending";

    public TileRegion() {}
    public TileRegion(String name, double minLon, double minLat, double maxLon, double maxLat) {
        this.name = name; this.minLon = minLon; this.minLat = minLat;
        this.maxLon = maxLon; this.maxLat = maxLat;
    }

    public boolean containsPoint(double lon, double lat) {
        return lon >= minLon && lon <= maxLon && lat >= minLat && lat <= maxLat;
    }
    public boolean intersectsBbox(double bMinLon, double bMinLat, double bMaxLon, double bMaxLat) {
        return minLon <= bMaxLon && maxLon >= bMinLon && minLat <= bMaxLat && maxLat >= bMinLat;
    }

    public String getName() { return name; } public void setName(String n) { name = n; }
    public double getMinLon() { return minLon; } public void setMinLon(double v) { minLon = v; }
    public double getMinLat() { return minLat; } public void setMinLat(double v) { minLat = v; }
    public double getMaxLon() { return maxLon; } public void setMaxLon(double v) { maxLon = v; }
    public double getMaxLat() { return maxLat; } public void setMaxLat(double v) { maxLat = v; }
    public int getMinZoom() { return minZoom; } public void setMinZoom(int v) { minZoom = v; }
    public int getMaxZoom() { return maxZoom; } public void setMaxZoom(int v) { maxZoom = v; }
    public String getFileName() { return fileName; } public void setFileName(String v) { fileName = v; }
    public Long getFileSize() { return fileSize; } public void setFileSize(Long v) { fileSize = v; }
    public String getMd5() { return md5; } public void setMd5(String v) { md5 = v; }
    public Instant getGeneratedAt() { return generatedAt; } public void setGeneratedAt(Instant v) { generatedAt = v; }
    public String getStatus() { return status; } public void setStatus(String v) { status = v; }
}
