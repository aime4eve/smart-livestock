package com.smartlivestock.identity.application;

import com.smartlivestock.identity.domain.model.ApiKey;
import com.smartlivestock.identity.domain.repository.ApiKeyRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class ApiKeyApplicationService {

    private static final String KEY_PREFIX = "sk_live_";
    private final ApiKeyRepository apiKeyRepository;
    private final SecureRandom secureRandom = new SecureRandom();

    @Transactional
    public Map<String, Object> createApiKey(Long tenantId, String name, String role) {
        byte[] rawBytes = new byte[32];
        secureRandom.nextBytes(rawBytes);
        String rawKey = KEY_PREFIX + HexFormat.of().formatHex(rawBytes);
        String keyHash = sha256(rawKey);
        String keyPrefix = rawKey.substring(0, 12);

        ApiKey apiKey = new ApiKey();
        apiKey.setTenantId(tenantId);
        apiKey.setKeyName(name);
        apiKey.setKeyHash(keyHash);
        apiKey.setKeyPrefix(keyPrefix);
        apiKey.setRole(role != null ? role : "admin");
        apiKey.setCreatedAt(Instant.now());
        apiKey.setStatus("ACTIVE");
        ApiKey saved = apiKeyRepository.save(apiKey);

        return Map.of(
                "id", saved.getId(),
                "keyName", name,
                "prefix", keyPrefix,
                "role", apiKey.getRole(),
                "rawKey", rawKey
        );
    }

    @Transactional
    public Map<String, Object> createApiKeyForPortal(Long tenantId, String name, String scopes,
                                                      int requestsPerMinute, int dailyQuota, String description) {
        byte[] rawBytes = new byte[32];
        secureRandom.nextBytes(rawBytes);
        String rawKey = KEY_PREFIX + HexFormat.of().formatHex(rawBytes);
        String keyHash = sha256(rawKey);
        String keyPrefix = rawKey.substring(0, 12);

        ApiKey apiKey = new ApiKey();
        apiKey.setTenantId(tenantId);
        apiKey.setKeyName(name);
        apiKey.setKeyHash(keyHash);
        apiKey.setKeyPrefix(keyPrefix);
        apiKey.setRole("api_consumer");
        apiKey.setScopes(scopes);
        apiKey.setRequestsPerMinute(requestsPerMinute);
        apiKey.setDailyQuota(dailyQuota);
        apiKey.setDescription(description);
        apiKey.setCreatedAt(Instant.now());
        apiKey.setStatus("ACTIVE");
        ApiKey saved = apiKeyRepository.save(apiKey);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", saved.getId());
        result.put("keyName", name);
        result.put("prefix", keyPrefix);
        result.put("rawKey", rawKey);
        result.put("scopes", scopes);
        result.put("requestsPerMinute", requestsPerMinute);
        result.put("dailyQuota", dailyQuota);
        result.put("status", "ACTIVE");
        result.put("createdAt", saved.getCreatedAt().toString());
        result.put("warning", "请妥善保存 rawKey，创建后不可再次查看");
        return result;
    }

    @Transactional
    public ApiKey validateApiKey(String rawKey) {
        String hash = sha256(rawKey);
        ApiKey apiKey = apiKeyRepository.findByKeyHash(hash)
                .orElseThrow(() -> new ApiException(ErrorCode.AUTH_API_KEY_INVALID, "无效的 API Key"));
        if (!apiKey.isActive()) {
            throw new ApiException(ErrorCode.AUTH_API_KEY_INVALID, "API Key 已吊销");
        }
        apiKey.setLastUsedAt(Instant.now());
        apiKeyRepository.save(apiKey);
        return apiKey;
    }

    @Transactional
    public void revokeApiKey(Long id) {
        ApiKey apiKey = apiKeyRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "API Key 不存在: " + id));
        apiKey.setStatus("REVOKED");
        apiKeyRepository.save(apiKey);
    }

    @Transactional
    public void deleteApiKey(Long id) {
        ApiKey apiKey = apiKeyRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "API Key 不存在: " + id));
        if (apiKey.isActive()) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "不能删除仍有效的 API Key，请先吊销");
        }
        apiKeyRepository.deleteById(id);
    }

    public ApiKey findById(Long id) {
        return apiKeyRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "API Key 不存在: " + id));
    }

    public ApiKey save(ApiKey apiKey) {
        return apiKeyRepository.save(apiKey);
    }

    public List<ApiKey> listApiKeys() {
        return apiKeyRepository.findAll();
    }

    public List<ApiKey> listApiKeysByTenant(Long tenantId) {
        return apiKeyRepository.findByTenantId(tenantId);
    }

    private String sha256(String input) {
        try {
            byte[] hash = MessageDigest.getInstance("SHA-256")
                    .digest(input.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (Exception e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }
}
