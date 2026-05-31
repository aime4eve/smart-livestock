package com.smartlivestock.identity.infrastructure.persistence.mapper;

import com.smartlivestock.identity.domain.model.ApiKey;
import com.smartlivestock.identity.infrastructure.persistence.entity.ApiKeyJpaEntity;

public final class ApiKeyMapper {
    private ApiKeyMapper() {}

    public static ApiKeyJpaEntity toJpaEntity(ApiKey k) {
        ApiKeyJpaEntity jpa = new ApiKeyJpaEntity();
        jpa.setId(k.getId());
        jpa.setTenantId(k.getTenantId());
        jpa.setKeyName(k.getKeyName());
        jpa.setKeyHash(k.getKeyHash());
        jpa.setKeyPrefix(k.getKeyPrefix());
        jpa.setRole(k.getRole());
        jpa.setStatus(k.getStatus());
        jpa.setExpiresAt(k.getExpiresAt());
        jpa.setLastUsedAt(k.getLastUsedAt());
        jpa.setCreatedAt(k.getCreatedAt());
        jpa.setScopes(k.getScopes());
        jpa.setRequestsPerMinute(k.getRequestsPerMinute());
        jpa.setDailyQuota(k.getDailyQuota());
        jpa.setDescription(k.getDescription());
        return jpa;
    }

    public static ApiKey toDomain(ApiKeyJpaEntity jpa) {
        ApiKey k = new ApiKey();
        k.setId(jpa.getId());
        k.setTenantId(jpa.getTenantId());
        k.setKeyName(jpa.getKeyName());
        k.setKeyHash(jpa.getKeyHash());
        k.setKeyPrefix(jpa.getKeyPrefix());
        k.setRole(jpa.getRole());
        k.setStatus(jpa.getStatus());
        k.setExpiresAt(jpa.getExpiresAt());
        k.setLastUsedAt(jpa.getLastUsedAt());
        k.setCreatedAt(jpa.getCreatedAt());
        k.setScopes(jpa.getScopes());
        k.setRequestsPerMinute(jpa.getRequestsPerMinute());
        k.setDailyQuota(jpa.getDailyQuota());
        k.setDescription(jpa.getDescription());
        return k;
    }
}
