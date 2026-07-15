package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.RtkReferencePoint;

import java.util.List;
import java.util.Optional;

public interface RtkReferencePointRepository {
    RtkReferencePoint save(RtkReferencePoint point);
    Optional<RtkReferencePoint> findById(Long id);
    List<RtkReferencePoint> findAll();
    List<RtkReferencePoint> findByLocationName(String locationName);
    void deleteById(Long id);
    boolean existsById(Long id);
}
