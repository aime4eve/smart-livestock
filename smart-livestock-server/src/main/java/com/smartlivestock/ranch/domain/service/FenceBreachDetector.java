package com.smartlivestock.ranch.domain.service;

import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Component;

/**
 * Domain service for detecting fence breaches and approach zones.
 * <ul>
 *   <li>Breach: point is outside the fence polygon</li>
 *   <li>Approach: point is inside the buffer zone but outside the fence (near boundary)</li>
 *   <li>Safe: point is inside the fence and outside the buffer zone</li>
 * </ul>
 */
@Component
public class FenceBreachDetector {

    /**
     * Check if the given point is breaching (outside) the specified fence.
     */
    public boolean isBreaching(Fence fence, GpsCoordinate point) {
        return !fence.contains(point);
    }

    /**
     * Check if the given point is in the buffer zone (approaching) of the specified fence.
     * Buffer zone = inside buffer polygon AND outside fence polygon.
     */
    public boolean isApproaching(Fence fence, GpsCoordinate point) {
        // Approaching = in buffer zone but not yet breached (still inside fence)
        // Or: outside fence but within buffer zone
        boolean inBuffer = fence.containsBuffer(point);
        boolean inFence = fence.contains(point);
        return inBuffer && !inFence; // in buffer ring area
    }

    /**
     * Find all active fences that the given point is breaching (outside).
     */
    public List<Fence> findBreachedFences(List<Fence> fences, GpsCoordinate point) {
        return fences.stream()
            .filter(Fence::isActive)
            .filter(fence -> isBreaching(fence, point))
            .collect(Collectors.toList());
    }

    /**
     * Find all active fences that the given point is approaching (in buffer zone, outside fence).
     */
    public List<Fence> findApproachingFences(List<Fence> fences, GpsCoordinate point) {
        return fences.stream()
            .filter(Fence::isActive)
            .filter(fence -> isApproaching(fence, point))
            .collect(Collectors.toList());
    }

    /**
     * Check if the point has returned to safety (inside fence).
     * Used for auto-resolving fence alerts when livestock returns.
     */
    public boolean hasReturnedToSafe(Fence fence, GpsCoordinate point) {
        return fence.isActive() && fence.contains(point);
    }
}
