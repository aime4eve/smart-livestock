package com.smartlivestock.analytics.infrastructure.acl;

import com.smartlivestock.analytics.domain.port.IdentityQueryPort;
import com.smartlivestock.analytics.domain.port.dto.ApiKeyInfo;
import com.smartlivestock.identity.application.ApiKeyApplicationService;
import com.smartlivestock.identity.domain.model.ApiKey;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

@Component("analyticsIdentityQueryPort")
public class IdentityQueryPortImpl implements IdentityQueryPort {

    private final ApiKeyApplicationService apiKeyApplicationService;

    public IdentityQueryPortImpl(ApiKeyApplicationService apiKeyApplicationService) {
        this.apiKeyApplicationService = apiKeyApplicationService;
    }

    @Override
    public Optional<ApiKeyInfo> findApiKeyById(Long keyId) {
        return Optional.ofNullable(apiKeyApplicationService.findById(keyId)).map(this::toInfo);
    }

    @Override
    public List<ApiKeyInfo> listApiKeysByTenant(Long tenantId) {
        return apiKeyApplicationService.listApiKeysByTenant(tenantId).stream().map(this::toInfo).toList();
    }

    @Override
    public ApiKeyInfo createApiKey(Long tenantId, String name, String scopes, Integer rpm, Integer dailyQuota, String description) {
        var result = apiKeyApplicationService.createApiKeyForPortal(tenantId, name, scopes, rpm, dailyQuota, description);
        // result is Map<String, Object>, extract the key
        Long keyId = ((Number) result.get("id")).longValue();
        return findApiKeyById(keyId).orElseThrow();
    }

    @Override
    public void saveApiKey(ApiKeyInfo key) {
        ApiKey apiKey = apiKeyApplicationService.findById(key.id());
        if (apiKey != null) {
            if (key.keyName() != null) apiKey.setKeyName(key.keyName());
            if (key.description() != null) apiKey.setDescription(key.description());
            if (key.status() != null) apiKey.setStatus(key.status());
            if (key.scopes() != null) apiKey.setScopes(key.scopes());
            if (key.requestsPerMinute() != null) apiKey.setRequestsPerMinute(key.requestsPerMinute());
            if (key.dailyQuota() != null) apiKey.setDailyQuota(key.dailyQuota());
            apiKeyApplicationService.save(apiKey);
        }
    }

    @Override
    public void revokeApiKey(Long keyId) {
        apiKeyApplicationService.revokeApiKey(keyId);
    }

    @Override
    public void deleteApiKey(Long keyId) {
        apiKeyApplicationService.deleteApiKey(keyId);
    }

    private ApiKeyInfo toInfo(ApiKey k) {
        return new ApiKeyInfo(
            k.getId(), k.getTenantId(), k.getKeyPrefix() + "...", k.getKeyName(), k.getKeyPrefix(),
            k.getStatus(), k.getScopes(), k.getRequestsPerMinute(), k.getDailyQuota(),
            k.getDescription(), k.getCreatedAt(), null
        );
    }
}
