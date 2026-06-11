package com.smartlivestock.ranch.domain.model;

import java.math.BigDecimal;
import java.util.List;

/**
 * A key monitoring area inside a fence (e.g. water source, feed area).
 * Alerts can be configured when livestock approach or enter these zones.
 */
public class FenceZone {

    private Long id;
    private Long fenceId;
    private Long farmId;
    private String name;
    private String zoneType;
    private List<GpsCoordinate> vertices;
    private int alertRadius;
    private String severity;
    private boolean active;

    public FenceZone() {
        this.active = true;
        this.alertRadius = 20;
        this.severity = "INFO";
    }

    public FenceZone(Long fenceId, Long farmId, String name, String zoneType,
                     List<GpsCoordinate> vertices, int alertRadius, String severity) {
        this.fenceId = fenceId;
        this.farmId = farmId;
        this.name = name;
        this.zoneType = zoneType;
        this.vertices = vertices;
        this.alertRadius = alertRadius;
        this.severity = severity;
        this.active = true;
    }

    // --- Getters and Setters ---

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getFenceId() { return fenceId; }
    public void setFenceId(Long fenceId) { this.fenceId = fenceId; }

    public Long getFarmId() { return farmId; }
    public void setFarmId(Long farmId) { this.farmId = farmId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getZoneType() { return zoneType; }
    public void setZoneType(String zoneType) { this.zoneType = zoneType; }

    public List<GpsCoordinate> getVertices() { return vertices; }
    public void setVertices(List<GpsCoordinate> vertices) { this.vertices = vertices; }

    public int getAlertRadius() { return alertRadius; }
    public void setAlertRadius(int alertRadius) { this.alertRadius = alertRadius; }

    public String getSeverity() { return severity; }
    public void setSeverity(String severity) { this.severity = severity; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }
}
