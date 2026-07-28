package com.smartlivestock.iot.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "standard_track_lines")
public class StandardTrackLineJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "name", nullable = false, length = 200)
    private String name;

    @Column(name = "status", nullable = false, length = 10)
    private String status = "CANDIDATE";

    @Column(name = "point_count", nullable = false)
    private Integer pointCount;

    @Column(name = "length_m", nullable = false, precision = 10, scale = 1)
    private BigDecimal lengthM;

    @Column(name = "start_lng", nullable = false, precision = 10, scale = 7)
    private BigDecimal startLng;

    @Column(name = "start_lat", nullable = false, precision = 10, scale = 7)
    private BigDecimal startLat;

    @Column(name = "source_file")
    private String sourceFile;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @PrePersist
    protected void onCreate() {
        if (this.createdAt == null) this.createdAt = Instant.now();
        if (this.status == null) this.status = "CANDIDATE";
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Integer getPointCount() { return pointCount; }
    public void setPointCount(Integer pointCount) { this.pointCount = pointCount; }
    public BigDecimal getLengthM() { return lengthM; }
    public void setLengthM(BigDecimal lengthM) { this.lengthM = lengthM; }
    public BigDecimal getStartLng() { return startLng; }
    public void setStartLng(BigDecimal startLng) { this.startLng = startLng; }
    public BigDecimal getStartLat() { return startLat; }
    public void setStartLat(BigDecimal startLat) { this.startLat = startLat; }
    public String getSourceFile() { return sourceFile; }
    public void setSourceFile(String sourceFile) { this.sourceFile = sourceFile; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
