package com.smartlivestock.ranch.infrastructure.persistence.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "tile_regions")
public class TileRegionJpaEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "name", nullable = false, length = 100, unique = true)
    private String name;
    @Column(name = "min_lon", nullable = false) private double minLon;
    @Column(name = "min_lat", nullable = false) private double minLat;
    @Column(name = "max_lon", nullable = false) private double maxLon;
    @Column(name = "max_lat", nullable = false) private double maxLat;
    @Column(name = "min_zoom", nullable = false) private int minZoom = 11;
    @Column(name = "max_zoom", nullable = false) private int maxZoom = 15;
    @Column(name = "file_name") private String fileName;
    @Column(name = "file_size") private Long fileSize;
    @Column(name = "md5", length = 32) private String md5;
    @Column(name = "generated_at") private Instant generatedAt;
    @Column(name = "status", nullable = false, length = 20) private String status = "pending";
    @Column(name = "created_at", nullable = false) private Instant createdAt;
    @Column(name = "updated_at", nullable = false) private Instant updatedAt;

    @PrePersist protected void onCreate() { Instant now = Instant.now(); this.createdAt = now; this.updatedAt = now; }
    @PreUpdate protected void onUpdate() { this.updatedAt = Instant.now(); }

    public Long getId() { return id; } public void setId(Long id) { this.id = id; }
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
    public Instant getCreatedAt() { return createdAt; } public void setCreatedAt(Instant v) { createdAt = v; }
    public Instant getUpdatedAt() { return updatedAt; } public void setUpdatedAt(Instant v) { updatedAt = v; }
}
