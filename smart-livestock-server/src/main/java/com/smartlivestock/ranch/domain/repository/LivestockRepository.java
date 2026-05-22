package com.smartlivestock.ranch.domain.repository;

import com.smartlivestock.ranch.domain.model.Livestock;

import java.util.List;
import java.util.Optional;

public interface LivestockRepository {
    Livestock save(Livestock livestock);
    Optional<Livestock> findById(Long id);
    List<Livestock> findByFarmId(Long farmId);
    Optional<Livestock> findByLivestockCode(String livestockCode);
    void deleteById(Long id);
    long countByFarmId(Long farmId);
    long countByFarmIdAndTenantId(Long farmId, Long tenantId);
}
