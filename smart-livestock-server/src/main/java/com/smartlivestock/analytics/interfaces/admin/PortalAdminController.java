package com.smartlivestock.analytics.interfaces.admin;

import com.smartlivestock.analytics.domain.port.IdentityQueryPort;
import com.smartlivestock.analytics.domain.port.dto.ApiKeyInfo;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin/portal/keys")
@RequiredArgsConstructor
public class PortalAdminController {

    private final IdentityQueryPort identityQueryPort;

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listAllKeys(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) Long tenantId) {
        requirePlatformAdmin();

        List<ApiKeyInfo> keys = tenantId != null
                ? identityQueryPort.listApiKeysByTenant(tenantId)
                : List.of();

        List<Map<String, Object>> items = keys.stream()
                .<Map<String, Object>>map(this::toSummary)
                .toList();

        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "items", items, "page", page, "pageSize", pageSize, "total", items.size())));
    }

    @PutMapping("/{keyId}/rate-limit")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateRateLimit(
            @PathVariable Long keyId, @RequestBody Map<String, Object> body) {
        requirePlatformAdmin();
        ApiKeyInfo key = identityQueryPort.findApiKeyById(keyId).orElse(null);
        if (key == null) return ResponseEntity.status(404).body(ApiResponse.error(com.smartlivestock.shared.common.ErrorCode.RESOURCE_NOT_FOUND, "API Key not found"));

        Integer newRpm = body.get("requestsPerMinute") != null ? ((Number) body.get("requestsPerMinute")).intValue() : key.requestsPerMinute();
        Integer newQuota = body.get("dailyQuota") != null ? ((Number) body.get("dailyQuota")).intValue() : key.dailyQuota();
        ApiKeyInfo updated = new ApiKeyInfo(key.id(), key.tenantId(), key.keyValue(), key.keyName(), key.keyPrefix(),
                key.status(), key.scopes(), newRpm, newQuota, key.description(), key.createdAt(), key.lastUsedAt());

        identityQueryPort.saveApiKey(updated);
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "id", keyId,
                "requestsPerMinute", newRpm != null ? newRpm : 0,
                "dailyQuota", newQuota != null ? newQuota : 0)));
    }

    @PutMapping("/{keyId}/scopes")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateScopes(
            @PathVariable Long keyId, @RequestBody Map<String, String> body) {
        requirePlatformAdmin();
        ApiKeyInfo key = identityQueryPort.findApiKeyById(keyId).orElse(null);
        if (key == null) return ResponseEntity.status(404).body(ApiResponse.error(com.smartlivestock.shared.common.ErrorCode.RESOURCE_NOT_FOUND, "API Key not found"));

        String scopes = body.get("scopes");
        if (scopes == null) throw new ApiException(ErrorCode.VALIDATION_ERROR, "scopes 不能为空");
        ApiKeyInfo updated = new ApiKeyInfo(key.id(), key.tenantId(), key.keyValue(), key.keyName(), key.keyPrefix(),
                key.status(), scopes, key.requestsPerMinute(), key.dailyQuota(), key.description(), key.createdAt(), key.lastUsedAt());

        identityQueryPort.saveApiKey(updated);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("id", keyId, "scopes", scopes)));
    }

    @PostMapping("/{keyId}/approve")
    public ResponseEntity<ApiResponse<Map<String, Object>>> approveKey(@PathVariable Long keyId) {
        requirePlatformAdmin();
        ApiKeyInfo key = identityQueryPort.findApiKeyById(keyId).orElse(null);
        if (key == null) return ResponseEntity.status(404).body(ApiResponse.error(com.smartlivestock.shared.common.ErrorCode.RESOURCE_NOT_FOUND, "API Key not found"));
        if (!"PENDING".equals(key.status())) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "Key 状态不是 PENDING，无法审批");
        }
        ApiKeyInfo updated = new ApiKeyInfo(key.id(), key.tenantId(), key.keyValue(), key.keyName(), key.keyPrefix(),
                "ACTIVE", key.scopes(), key.requestsPerMinute(), key.dailyQuota(), key.description(), key.createdAt(), key.lastUsedAt());
        identityQueryPort.saveApiKey(updated);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("id", keyId, "status", "ACTIVE")));
    }

    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getStats() {
        requirePlatformAdmin();
        List<ApiKeyInfo> all = List.of();
        long active = all.stream().filter(k -> "ACTIVE".equals(k.status())).count();
        long revoked = all.stream().filter(k -> "REVOKED".equals(k.status())).count();
        long pending = all.stream().filter(k -> "PENDING".equals(k.status())).count();
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "total", all.size(), "active", active, "revoked", revoked, "pending", pending)));
    }

    private void requirePlatformAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证");
        boolean isAdmin = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_PLATFORM_ADMIN"));
        if (!isAdmin) throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "需要 platform_admin 角色");
    }

    private Map<String, Object> toSummary(ApiKeyInfo k) {
        return Map.<String, Object>of(
                "id", k.id(),
                "keyName", k.keyName() != null ? k.keyName() : "",
                "prefix", k.keyPrefix() != null ? k.keyPrefix() : "",
                "tenantId", k.tenantId(),
                "status", k.status() != null ? k.status() : "",
                "scopes", k.scopes() != null ? k.scopes() : "",
                "requestsPerMinute", k.requestsPerMinute() != null ? k.requestsPerMinute() : 0,
                "dailyQuota", k.dailyQuota() != null ? k.dailyQuota() : 0,
                "createdAt", k.createdAt() != null ? k.createdAt().toString() : ""
        );
    }
}
