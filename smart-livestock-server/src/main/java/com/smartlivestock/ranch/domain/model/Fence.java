package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.shared.domain.AggregateRoot;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

/**
 * Fence aggregate root representing a geographic polygon boundary on a farm.
 * <p>
 * Uses the ray casting algorithm to determine if a GPS point is inside the polygon.
 */
public class Fence extends AggregateRoot {

    private Long farmId;
    private String name;
    private List<GpsCoordinate> vertices;
    private String color;
    private boolean active;

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

    /**
     * Determine if the given GPS coordinate is inside this fence polygon.
     * Uses the ray casting (even-odd rule) algorithm.
     * A point exactly on an edge is considered inside.
     *
     * @param point the GPS coordinate to test
     * @return true if the point is inside or on the boundary of the polygon
     */
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

            // Check if point is exactly on a horizontal edge
            if (yi.compareTo(py) == 0 && yj.compareTo(py) == 0) {
                // Both endpoints at same latitude as point — check longitude range
                BigDecimal minX = xi.min(xj);
                BigDecimal maxX = xi.max(xj);
                if (px.compareTo(minX) >= 0 && px.compareTo(maxX) <= 0) {
                    return true;
                }
                continue;
            }

            // Check if point is exactly on a vertex
            if (yi.compareTo(py) == 0 && xi.compareTo(px) == 0) {
                return true;
            }

            // Ray casting: does the horizontal ray from (px, py) intersect edge (i,j)?
            boolean yiAbovePy = yi.compareTo(py) > 0;
            boolean yjAbovePy = yj.compareTo(py) > 0;

            if (yiAbovePy != yjAbovePy) {
                // Compute x-coordinate of intersection
                BigDecimal dx = xj.subtract(xi);
                BigDecimal dy = yj.subtract(yi);
                BigDecimal intersectX = xi.add(py.subtract(yi).multiply(dx).divide(dy, 20, java.math.RoundingMode.HALF_UP));

                if (px.compareTo(intersectX) <= 0) {
                    // Point is on or to the left of the intersection
                    if (px.compareTo(intersectX) == 0) {
                        return true; // On edge
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

    // --- Getters and Setters ---

    public Long getFarmId() { return farmId; }
    public void setFarmId(Long farmId) { this.farmId = farmId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public List<GpsCoordinate> getVertices() { return vertices; }
    public void setVertices(List<GpsCoordinate> vertices) { this.vertices = vertices; }

    public String getColor() { return color; }
    public void setColor(String color) { this.color = color; }

    public boolean isActive() { return active; }
}
