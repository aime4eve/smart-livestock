package com.smartlivestock.identity.domain.repository;

import com.smartlivestock.identity.domain.model.ApiKey;
import java.util.List;
import java.util.Optional;

public interface ApiKeyRepository {
    ApiKey save(ApiKey apiKey);
    Optional<ApiKey> findById(Long id);
    Optional<ApiKey> findByKeyHash(String keyHash);
    List<ApiKey> findAll();
    List<ApiKey> findByTenantId(Long tenantId);
    void deleteById(Long id);
}
