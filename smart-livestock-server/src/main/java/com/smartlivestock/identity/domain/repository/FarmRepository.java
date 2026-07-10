package com.smartlivestock.identity.domain.repository;

import com.smartlivestock.identity.domain.model.Farm;

import java.util.List;
import java.util.Optional;

public interface FarmRepository {
    Farm save(Farm farm);
    Optional<Farm> findById(Long id);
    List<Farm> findByTenantId(Long tenantId);
    void deleteById(Long id);
}
