package com.smartlivestock.ranch.domain.service;

import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Domain service for detecting fence breaches.
 * Determines whether a GPS position falls outside fence boundaries.
 */
public class FenceBreachDetector {

    /**
     * Check if the given point is breaching (outside) the specified fence.
     *
     * @param fence the fence to check against
     * @param point the GPS coordinate to test
     * @return true if the point is outside the fence (breaching)
     */
    public boolean isBreaching(Fence fence, GpsCoordinate point) {
        return !fence.contains(point);
    }

    /**
     * Find all active fences that the given point is breaching.
     *
     * @param fences list of fences to check
     * @param point  the GPS coordinate to test
     * @return list of active fences that the point is outside of
     */
    public List<Fence> findBreachedFences(List<Fence> fences, GpsCoordinate point) {
        return fences.stream()
            .filter(Fence::isActive)
            .filter(fence -> isBreaching(fence, point))
            .collect(Collectors.toList());
    }
}
