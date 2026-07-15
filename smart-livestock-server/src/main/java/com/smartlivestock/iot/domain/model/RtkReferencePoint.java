package com.smartlivestock.iot.domain.model;

import com.smartlivestock.shared.domain.AggregateRoot;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * RTK reference point aggregate root.
 * <p>
 * Stores RTK ground-truth coordinates used as the reference for GPS quality checks.
 * Grouped by {@code locationName} (e.g. "一期楼顶") with a {@code pointLabel} (e.g. "11号点").
 */
public class RtkReferencePoint extends AggregateRoot {

    private String locationName;
    private String pointLabel;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private Instant createdAt;
    private Instant updatedAt;

    public RtkReferencePoint() {
    }

    public RtkReferencePoint(String locationName, String pointLabel, BigDecimal latitude, BigDecimal longitude) {
        this.locationName = locationName;
        this.pointLabel = pointLabel;
        this.latitude = latitude;
        this.longitude = longitude;
    }

    // --- Getters and Setters ---

    public String getLocationName() { return locationName; }
    public void setLocationName(String locationName) { this.locationName = locationName; }

    public String getPointLabel() { return pointLabel; }
    public void setPointLabel(String pointLabel) { this.pointLabel = pointLabel; }

    public BigDecimal getLatitude() { return latitude; }
    public void setLatitude(BigDecimal latitude) { this.latitude = latitude; }

    public BigDecimal getLongitude() { return longitude; }
    public void setLongitude(BigDecimal longitude) { this.longitude = longitude; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
