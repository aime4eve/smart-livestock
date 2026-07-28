package com.smartlivestock.iot.interfaces.admin.dto;

import com.smartlivestock.iot.domain.model.StandardTrackLine;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * One standard track line candidate (NIX-68, spec §7.1).
 */
public class StandardTrackLineDto {

    private Long id;
    private String name;
    private String status;
    private Integer pointCount;
    private BigDecimal lengthM;
    private BigDecimal startLng;
    private BigDecimal startLat;
    private String sourceFile;
    private Instant createdAt;

    public static StandardTrackLineDto from(StandardTrackLine l) {
        StandardTrackLineDto dto = new StandardTrackLineDto();
        dto.setId(l.getId());
        dto.setName(l.getName());
        dto.setStatus(l.getStatus());
        dto.setPointCount(l.getPointCount());
        dto.setLengthM(l.getLengthM());
        dto.setStartLng(l.getStartLng());
        dto.setStartLat(l.getStartLat());
        dto.setSourceFile(l.getSourceFile());
        dto.setCreatedAt(l.getCreatedAt());
        return dto;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
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
