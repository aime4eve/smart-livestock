package com.smartlivestock.iot.domain.model;

import com.smartlivestock.shared.domain.AggregateRoot;

import java.time.Instant;

/**
 * A single ordered waypoint on a {@link DynamicTestRoute}.
 * <p>
 * {@code sequenceNo} defines the order a device passes the points (1-based).
 * The same RTK point may appear more than once on a route (a device loops back).
 */
public class DynamicTestRoutePoint extends AggregateRoot {

    private Long routeId;
    private Long rtkPointId;
    private Integer sequenceNo;
    private Instant createdAt;

    public DynamicTestRoutePoint() {
    }

    public DynamicTestRoutePoint(Long routeId, Long rtkPointId, Integer sequenceNo) {
        this.routeId = routeId;
        this.rtkPointId = rtkPointId;
        this.sequenceNo = sequenceNo;
    }

    // --- Getters and Setters ---

    public Long getRouteId() { return routeId; }
    public void setRouteId(Long routeId) { this.routeId = routeId; }

    public Long getRtkPointId() { return rtkPointId; }
    public void setRtkPointId(Long rtkPointId) { this.rtkPointId = rtkPointId; }

    public Integer getSequenceNo() { return sequenceNo; }
    public void setSequenceNo(Integer sequenceNo) { this.sequenceNo = sequenceNo; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
