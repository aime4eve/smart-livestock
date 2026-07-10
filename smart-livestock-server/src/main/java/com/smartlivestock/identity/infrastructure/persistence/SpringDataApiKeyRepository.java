package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.infrastructure.persistence.entity.ApiKeyJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SpringDataApiKeyRepository extends JpaRepository<ApiKeyJpaEntity, Long> {
    Optional<ApiKeyJpaEntity> findByKeyHash(String keyHash);
    List<ApiKeyJpaEntity> findByTenantId(Long tenantId);
}
