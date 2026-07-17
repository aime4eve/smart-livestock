package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.DynamicTestRoutePoint;

import java.util.List;

public interface DynamicTestRoutePointRepository {
    DynamicTestRoutePoint save(DynamicTestRoutePoint point);
    /** All waypoints of a route, ordered by sequence_no ascending. */
    List<DynamicTestRoutePoint> findByRouteIdOrderBySequenceNoAsc(Long routeId);
    List<DynamicTestRoutePoint> saveAll(List<DynamicTestRoutePoint> points);
    void deleteByRouteId(Long routeId);
}
