package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.DynamicTestRoute;

import java.util.List;
import java.util.Optional;

public interface DynamicTestRouteRepository {
    DynamicTestRoute save(DynamicTestRoute route);
    Optional<DynamicTestRoute> findById(Long id);
    List<DynamicTestRoute> findAll();
    void deleteById(Long id);
    boolean existsById(Long id);
}
