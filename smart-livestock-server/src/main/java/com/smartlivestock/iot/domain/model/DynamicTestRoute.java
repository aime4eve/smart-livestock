package com.smartlivestock.iot.domain.model;

import com.smartlivestock.shared.domain.AggregateRoot;

import java.time.Instant;

/**
 * Reusable dynamic test route definition (an ordered sequence of RTK truth points).
 * <p>
 * A route can be referenced by multiple DYNAMIC {@link GpsQualityTest} instances,
 * supporting the "multiple devices share one test route" scenario.
 */
public class DynamicTestRoute extends AggregateRoot {

    private String name;
    private String description;
    private Instant createdAt;
    private Instant updatedAt;

    public DynamicTestRoute() {
    }

    public DynamicTestRoute(String name, String description) {
        this.name = name;
        this.description = description;
    }

    // --- Getters and Setters ---

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
