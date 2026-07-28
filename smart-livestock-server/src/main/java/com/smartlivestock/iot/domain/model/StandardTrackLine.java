package com.smartlivestock.iot.domain.model;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * A standard track line candidate imported from an RTK handset XLSX export
 * (NIX-68, spec §6.2): reusable line-level truth for LINE tests.
 * <p>
 * Candidates are managed append-only (D3): re-importing the same file adds a
 * new record instead of overwriting; SELECTED is a non-exclusive marker.
 * Point count / length / start point are computed from coordinates only —
 * file metadata (start/end time, length column) is never trusted (D6).
 */
public class StandardTrackLine {

    public static final String STATUS_CANDIDATE = "CANDIDATE";
    public static final String STATUS_SELECTED = "SELECTED";

    private Long id;
    private Long tenantId;
    private String name;
    private String status;
    private Integer pointCount;
    private BigDecimal lengthM;
    private BigDecimal startLng;
    private BigDecimal startLat;
    private String sourceFile;
    private Instant createdAt;

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
