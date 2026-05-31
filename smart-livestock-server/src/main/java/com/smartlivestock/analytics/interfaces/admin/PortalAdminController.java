package com.smartlivestock.analytics.interfaces.admin;

import com.smartlivestock.identity.application.ApiKeyApplicationService;
import com.smartlivestock.identity.domain.model.ApiKey;
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

    private final ApiKeyApplicationService apiKeyService;

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listAllKeys(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) Long tenantId) {
        requirePlatformAdmin();

        List<ApiKey> keys = tenantId != null
                ? apiKeyService.listApiKeysByTenant(tenantId)
                : apiKeyService.listApiKeys();

        List<Map<String, Object>> items = keys.stream()
                .map(this::toSummary)
                .toList();

        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "items", items, "page", page, "pageSize", pageSize, "total", items.size())));
    }

    @PutMapping("/{keyId}/rate-limit")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateRateLimit(
            @PathVariable Long keyId, @RequestBody Map<String, Object> body) {
        requirePlatformAdmin();
        ApiKey key = apiKeyService.findById(keyId);

        if (body.get("requestsPerMinute") != null)
            key.setRequestsPerMinute(((Number) body.get("requestsPerMinute")).intValue());
        if (body.get("dailyQuota") != null)
            key.setDailyQuota(((Number) body.get("dailyQuota")).intValue());

        apiKeyService.save(key);
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "id", keyId,
                "requestsPerMinute", key.getRequestsPerMinute() != null ? key.getRequestsPerMinute() : 0,
                "dailyQuota", key.getDailyQuota() != null ? key.getDailyQuota() : 0)));
    }

    @PutMapping("/{keyId}/scopes")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateScopes(
            @PathVariable Long keyId, @RequestBody Map<String, String> body) {
        requirePlatformAdmin();
        ApiKey key = apiKeyService.findById(keyId);

        String scopes = body.get("scopes");
        if (scopes == null) throw new ApiException(ErrorCode.VALIDATION_ERROR, "scopes 不能为空");
        key.setScopes(scopes);

        apiKeyService.save(key);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("id", keyId, "scopes", scopes)));
    }

    @PostMapping("/{keyId}/approve")
    public ResponseEntity<ApiResponse<Map<String, Object>>> approveKey(@PathVariable Long keyId) {
        requirePlatformAdmin();
        ApiKey key = apiKeyService.findById(keyId);
        if (!"PENDING".equals(key.getStatus())) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "Key 状态不是 PENDING，无法审批");
        }
        key.setStatus("ACTIVE");
        apiKeyService.save(key);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("id", keyId, "status", "ACTIVE")));
    }

    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getStats() {
        requirePlatformAdmin();
        List<ApiKey> all = apiKeyService.listApiKeys();
        long active = all.stream().filter(k -> "ACTIVE".equals(k.getStatus())).count();
        long revoked = all.stream().filter(k -> "REVOKED".equals(k.getStatus())).count();
        long pending = all.stream().filter(k -> "PENDING".equals(k.getStatus())).count();
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

    private Map<String, Object> toSummary(ApiKey k) {
        return Map.<String, Object>of(
                "id", k.getId(),
                "keyName", k.getKeyName() != null ? k.getKeyName() : "",
                "prefix", k.getKeyPrefix() != null ? k.getKeyPrefix() : "",
                "tenantId", k.getTenantId(),
                "status", k.getStatus() != null ? k.getStatus() : "",
                "scopes", k.getScopes() != null ? k.getScopes() : "",
                "requestsPerMinute", k.getRequestsPerMinute() != null ? k.getRequestsPerMinute() : 0,
                "dailyQuota", k.getDailyQuota() != null ? k.getDailyQuota() : 0,
                "createdAt", k.getCreatedAt() != null ? k.getCreatedAt().toString() : ""
        );
    }
}
