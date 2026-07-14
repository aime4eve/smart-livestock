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

    /** Count non-deleted livestock for a tenant (across all its farms). */
    long countByTenantId(Long tenantId);

    /** Paginated query without keyword filter. */
    List<Livestock> findByFarmIdPaged(Long farmId, int offset, int limit);

    /** Paginated query with keyword search on livestockCode and breed. */
    List<Livestock> findByFarmIdAndKeyword(Long farmId, String keyword, int offset, int limit);

    /** Count non-deleted livestock for a farm. */
    long countByFarmIdPaged(Long farmId);

    /** Count non-deleted livestock matching keyword for a farm. */
    long countByFarmIdAndKeyword(Long farmId, String keyword);
}
