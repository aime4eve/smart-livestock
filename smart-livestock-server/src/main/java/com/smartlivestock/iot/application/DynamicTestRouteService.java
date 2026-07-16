package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.DynamicTestRoute;
import com.smartlivestock.iot.domain.model.DynamicTestRoutePoint;
import com.smartlivestock.iot.domain.repository.DynamicTestRoutePointRepository;
import com.smartlivestock.iot.domain.repository.DynamicTestRouteRepository;
import com.smartlivestock.iot.domain.repository.RtkReferencePointRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * CRUD and point-sequence management for reusable dynamic test routes.
 * <p>
 * A route is an ordered sequence of RTK reference points that a device
 * passes during a DYNAMIC GPS quality test. Points are managed as an
 * atomic whole-replacement (PUT) to avoid concurrency-induced
 * sequence_no conflicts.
 */
@Service
@RequiredArgsConstructor
public class DynamicTestRouteService {

    private final DynamicTestRouteRepository routeRepository;
    private final DynamicTestRoutePointRepository pointRepository;
    private final RtkReferencePointRepository rtkPointRepository;

    public List<DynamicTestRoute> findAll() {
        return routeRepository.findAll();
    }

    public DynamicTestRoute findById(Long id) {
        return routeRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Route not found: " + id));
    }

    public DynamicTestRoute create(String name, String description) {
        if (name == null || name.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "name is required");
        }
        return routeRepository.save(new DynamicTestRoute(name, description));
    }

    public DynamicTestRoute update(Long id, String name, String description) {
        DynamicTestRoute existing = findById(id);
        if (name != null) {
            existing.setName(name);
        }
        if (description != null) {
            existing.setDescription(description);
        }
        return routeRepository.save(existing);
    }

    /**
     * Delete a route. Point sequence is removed by DB-level CASCADE on
     * {@code dynamic_test_route_points.route_id}.
     */
    public void delete(Long id) {
        if (!routeRepository.existsById(id)) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "Route not found: " + id);
        }
        routeRepository.deleteById(id);
    }

    /**
     * All waypoints of a route, ordered by sequence_no ascending.
     */
    public List<DynamicTestRoutePoint> findPoints(Long routeId) {
        if (!routeRepository.existsById(routeId)) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "Route not found: " + routeId);
        }
        return pointRepository.findByRouteIdOrderBySequenceNoAsc(routeId);
    }

    /**
     * Replace the entire point sequence of a route.
     * <p>
     * Existing points are deleted first, then the new list is inserted.
     * Each {@code rtkPointId} must reference an existing RTK reference point;
     * {@code sequenceNo} values must be non-null and unique within the list.
     *
     * @param routeId target route
     * @param points  new ordered waypoint list (may be empty to clear the route)
     */
    public void replacePoints(Long routeId, List<RoutePointInput> points) {
        if (!routeRepository.existsById(routeId)) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "Route not found: " + routeId);
        }
        pointRepository.deleteByRouteId(routeId);
        if (points == null || points.isEmpty()) {
            return;
        }

        Set<Integer> seenSequenceNo = new HashSet<>();
        List<DynamicTestRoutePoint> toSave = new ArrayList<>(points.size());
        for (int i = 0; i < points.size(); i++) {
            RoutePointInput input = points.get(i);
            if (input.rtkPointId() == null) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR,
                        "rtkPointId is required (row " + (i + 1) + ")");
            }
            if (!rtkPointRepository.existsById(input.rtkPointId())) {
                throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "RTK point not found: " + input.rtkPointId());
            }
            if (input.sequenceNo() == null) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR,
                        "sequenceNo is required (row " + (i + 1) + ")");
            }
            if (!seenSequenceNo.add(input.sequenceNo())) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR,
                        "Duplicate sequenceNo: " + input.sequenceNo());
            }
            toSave.add(new DynamicTestRoutePoint(routeId, input.rtkPointId(), input.sequenceNo()));
        }
        pointRepository.saveAll(toSave);
    }

    /** Input row for a route waypoint. */
    public record RoutePointInput(Long rtkPointId, Integer sequenceNo) {
    }
}
