package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.shared.domain.AggregateRoot;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class Fence extends AggregateRoot {

    private Long farmId;
    private String name;
    private List<GpsCoordinate> vertices;
    private String color;
    private boolean active;
    private int version = 1;
    private String fenceType = "sub";

    public Fence() {
        this.active = true;
        this.vertices = new ArrayList<>();
    }

    public Fence(Long farmId, String name, List<GpsCoordinate> vertices, String color) {
        this.farmId = farmId;
        this.name = name;
        this.vertices = new ArrayList<>(vertices);
        this.color = color;
        this.active = true;
    }

    public boolean contains(GpsCoordinate point) {
        Objects.requireNonNull(point, "point must not be null");
        if (vertices == null || vertices.size() < 3) {
            return false;
        }

        int n = vertices.size();
        boolean inside = false;
        BigDecimal px = point.longitude();
        BigDecimal py = point.latitude();

        for (int i = 0, j = n - 1; i < n; j = i++) {
            BigDecimal xi = vertices.get(i).longitude();
            BigDecimal yi = vertices.get(i).latitude();
            BigDecimal xj = vertices.get(j).longitude();
            BigDecimal yj = vertices.get(j).latitude();

            if (yi.compareTo(py) == 0 && yj.compareTo(py) == 0) {
                BigDecimal minX = xi.min(xj);
                BigDecimal maxX = xi.max(xj);
                if (px.compareTo(minX) >= 0 && px.compareTo(maxX) <= 0) {
                    return true;
                }
                continue;
            }

            if (yi.compareTo(py) == 0 && xi.compareTo(px) == 0) {
                return true;
            }

            boolean yiAbovePy = yi.compareTo(py) > 0;
            boolean yjAbovePy = yj.compareTo(py) > 0;

            if (yiAbovePy != yjAbovePy) {
                BigDecimal dx = xj.subtract(xi);
                BigDecimal dy = yj.subtract(yi);
                BigDecimal intersectX = xi.add(py.subtract(yi).multiply(dx).divide(dy, 20, java.math.RoundingMode.HALF_UP));

                if (px.compareTo(intersectX) <= 0) {
                    if (px.compareTo(intersectX) == 0) {
                        return true;
                    }
                    inside = !inside;
                }
            }
        }

        return inside;
    }

    public void disable() {
        this.active = false;
    }

    public void enable() {
        this.active = true;
    }

    public Long getFarmId() { return farmId; }
    public void setFarmId(Long farmId) { this.farmId = farmId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public List<GpsCoordinate> getVertices() { return vertices; }
    public void setVertices(List<GpsCoordinate> vertices) { this.vertices = vertices; }

    public String getColor() { return color; }
    public void setColor(String color) { this.color = color; }

    public boolean isActive() { return active; }

    public int getVersion() { return version; }
    public void setVersion(int version) { this.version = version; }

    public String getFenceType() { return fenceType; }
    public void setFenceType(String fenceType) { this.fenceType = fenceType; }

    // ── Buffer zone fields ──

    private int bufferDistance = 50; // meters
    private List<GpsCoordinate> bufferPolygon; // pre-computed buffer zone vertices

    public int getBufferDistance() { return bufferDistance; }
    public void setBufferDistance(int bufferDistance) { this.bufferDistance = bufferDistance; }

    public List<GpsCoordinate> getBufferPolygon() { return bufferPolygon; }
    public void setBufferPolygon(List<GpsCoordinate> bufferPolygon) { this.bufferPolygon = bufferPolygon; }

    /**
     * Check if point is inside the buffer zone (approaching fence).
     * Returns false if buffer polygon is not set.
     */
    public boolean containsBuffer(GpsCoordinate point) {
        if (bufferPolygon == null || bufferPolygon.size() < 3) return false;
        // Reuse ray-casting algorithm on buffer polygon
        List<GpsCoordinate> poly = bufferPolygon;
        java.math.BigDecimal px = point.longitude();
        java.math.BigDecimal py = point.latitude();
        int n = poly.size();
        boolean inside = false;
        for (int i = 0, j = n - 1; i < n; j = i++) {
            java.math.BigDecimal xi = poly.get(i).longitude();
            java.math.BigDecimal yi = poly.get(i).latitude();
            java.math.BigDecimal xj = poly.get(j).longitude();
            java.math.BigDecimal yj = poly.get(j).latitude();
            boolean yiAbovePy = yi.compareTo(py) > 0;
            boolean yjAbovePy = yj.compareTo(py) > 0;
            if (yiAbovePy != yjAbovePy) {
                java.math.BigDecimal dx = xj.subtract(xi);
                java.math.BigDecimal dy = yj.subtract(yi);
                java.math.BigDecimal intersectX = xi.add(py.subtract(yi).multiply(dx).divide(dy, 20, java.math.RoundingMode.HALF_UP));
                if (px.compareTo(intersectX) <= 0) {
                    if (px.compareTo(intersectX) == 0) return true;
                    inside = !inside;
                }
            }
        }
        return inside;
    }
}

