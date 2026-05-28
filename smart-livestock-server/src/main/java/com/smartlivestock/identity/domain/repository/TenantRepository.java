package com.smartlivestock.identity.domain.repository;

import com.smartlivestock.identity.domain.model.Tenant;

import java.util.Optional;

public interface TenantRepository {
    Tenant save(Tenant tenant);
    Optional<Tenant> findById(Long id);
    boolean existsById(Long id);
}
