package com.smartlivestock.analytics.domain.port;

import com.smartlivestock.analytics.domain.port.dto.ApiKeyInfo;

import java.util.List;
import java.util.Map;
import java.util.Optional;

public interface IdentityQueryPort {
    Optional<ApiKeyInfo> findApiKeyById(Long keyId);
    List<ApiKeyInfo> listApiKeysByTenant(Long tenantId);
    /**
     * Returns the creation result including the one-time {@code rawKey}; the
     * secret cannot be recovered from persisted rows afterwards.
     */
    Map<String, Object> createApiKey(Long tenantId, String name, String scopes, Integer rpm, Integer dailyQuota, String description);
    void saveApiKey(ApiKeyInfo key);
    void revokeApiKey(Long keyId);
    void deleteApiKey(Long keyId);
}
