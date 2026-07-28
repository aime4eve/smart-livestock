package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.StandardTrackLine;

import java.util.List;
import java.util.Optional;

public interface StandardTrackLineRepository {
    StandardTrackLine save(StandardTrackLine line);
    Optional<StandardTrackLine> findById(Long id);
    List<StandardTrackLine> findByTenantIdOrderByCreatedAtDesc(Long tenantId);
    void deleteById(Long id);
}
