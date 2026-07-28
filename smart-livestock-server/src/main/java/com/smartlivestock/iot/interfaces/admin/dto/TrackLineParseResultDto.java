package com.smartlivestock.iot.interfaces.admin.dto;

import java.math.BigDecimal;
import java.util.List;

/**
 * Parse-preview result of an RTK handset track-line XLSX (NIX-68, spec §7.2).
 * Nothing is persisted at this stage.
 */
public class TrackLineParseResultDto {

    private String defaultName;
    private int rawPointCount;
    private int pointCount;
    private int removedDuplicates;
    private int invalidPoints;
    private double lengthMeters;
    private BigDecimal startLng;
    private BigDecimal startLat;
    private BigDecimal endLng;
    private BigDecimal endLat;
    private String metadataWarning;
    private List<Point> previewPoints;

    /** One preview coordinate point (after consecutive-duplicate removal). */
    public record Point(int sequenceNo, BigDecimal lng, BigDecimal lat) {}

    public String getDefaultName() { return defaultName; }
    public void setDefaultName(String defaultName) { this.defaultName = defaultName; }
    public int getRawPointCount() { return rawPointCount; }
    public void setRawPointCount(int rawPointCount) { this.rawPointCount = rawPointCount; }
    public int getPointCount() { return pointCount; }
    public void setPointCount(int pointCount) { this.pointCount = pointCount; }
    public int getRemovedDuplicates() { return removedDuplicates; }
    public void setRemovedDuplicates(int removedDuplicates) { this.removedDuplicates = removedDuplicates; }
    public int getInvalidPoints() { return invalidPoints; }
    public void setInvalidPoints(int invalidPoints) { this.invalidPoints = invalidPoints; }
    public double getLengthMeters() { return lengthMeters; }
    public void setLengthMeters(double lengthMeters) { this.lengthMeters = lengthMeters; }
    public BigDecimal getStartLng() { return startLng; }
    public void setStartLng(BigDecimal startLng) { this.startLng = startLng; }
    public BigDecimal getStartLat() { return startLat; }
    public void setStartLat(BigDecimal startLat) { this.startLat = startLat; }
    public BigDecimal getEndLng() { return endLng; }
    public void setEndLng(BigDecimal endLng) { this.endLng = endLng; }
    public BigDecimal getEndLat() { return endLat; }
    public void setEndLat(BigDecimal endLat) { this.endLat = endLat; }
    public String getMetadataWarning() { return metadataWarning; }
    public void setMetadataWarning(String metadataWarning) { this.metadataWarning = metadataWarning; }
    public List<Point> getPreviewPoints() { return previewPoints; }
    public void setPreviewPoints(List<Point> previewPoints) { this.previewPoints = previewPoints; }
}
