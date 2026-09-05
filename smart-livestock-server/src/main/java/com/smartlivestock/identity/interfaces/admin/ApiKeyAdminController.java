package com.smartlivestock.identity.interfaces.admin;

import com.smartlivestock.identity.application.ApiKeyApplicationService;
import com.smartlivestock.identity.domain.model.ApiKey;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import com.smartlivestock.shared.scope.ScopeInterceptor;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin/api-keys")
@RequiredArgsConstructor
public class ApiKeyAdminController {

    private final ApiKeyApplicationService apiKeyApplicationService;

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listApiKeys(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) Long tenantId,
            @RequestParam(required = false) String status) {
        requirePlatformAdmin();

        List<ApiKey> keys = tenantId != null
                ? apiKeyApplicationService.listApiKeysByTenant(tenantId)
                : apiKeyApplicationService.listApiKeys();

        List<Map<String, Object>> items = keys.stream()
                .map(k -> Map.<String, Object>of(
                        "id", k.getId(),
                        "keyName", k.getKeyName() != null ? k.getKeyName() : "",
                        "prefix", k.getKeyPrefix() != null ? k.getKeyPrefix() : "",
                        "role", k.getRole() != null ? k.getRole() : "",
                        "scopes", k.getScopes() != null ? k.getScopes() : "",
                        "status", k.getStatus() != null ? k.getStatus() : "",
                        "tenantId", k.getTenantId(),
                        "expiresAt", k.getExpiresAt() != null ? k.getExpiresAt().toString() : "",
                        "lastUsedAt", k.getLastUsedAt() != null ? k.getLastUsedAt().toString() : "",
                        "createdAt", k.getCreatedAt() != null ? k.getCreatedAt().toString() : ""
                ))
                .toList();

        Map<String, Object> data = Map.of(
                "items", items,
                "page", page,
                "pageSize", pageSize,
                "total", items.size()
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    @SuppressWarnings("unchecked")
    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> createApiKey(@RequestBody Map<String, Object> body) {
        requirePlatformAdmin();

        String name = (String) body.get("name");
        String role = (String) body.get("role");
        Long tenantId = body.get("tenantId") != null
                ? ((Number) body.get("tenantId")).longValue()
                : TenantContext.getCurrentTenant();
        String scopes = normalizeScopes(body.get("scopes"));

        Map<String, Object> result = apiKeyApplicationService.createApiKey(tenantId, name, role, scopes);

        Map<String, Object> response = new LinkedHashMap<>(
                Map.of(
                        "id", result.get("id"),
                        "keyName", result.get("keyName"),
                        "prefix", result.get("prefix"),
                        "role", result.get("role"),
                        "rawKey", result.get("rawKey")
                ));
        response.put("scopes", result.get("scopes"));
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(response));
    }

    /**
     * Accepts scopes as a JSON array or a comma-separated string (both shapes
     * appear in the field) and validates each token against the known scope
     * set, so keys are never created without the grants their consumers need.
     */
    private String normalizeScopes(Object raw) {
        if (raw == null) {
            return null;
        }
        List<String> tokens;
        if (raw instanceof List<?> list) {
            tokens = list.stream().map(String::valueOf).toList();
        } else {
            tokens = List.of(String.valueOf(raw).split(","));
        }
        List<String> cleaned = tokens.stream()
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList();
        if (cleaned.isEmpty()) {
            return null;
        }
        for (String scope : cleaned) {
            if (!ScopeInterceptor.KNOWN_SCOPES.contains(scope)) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.apiKeyScopeInvalid",
                        new Object[]{scope, String.join(", ", ScopeInterceptor.KNOWN_SCOPES)});
            }
        }
        return String.join(",", cleaned);
    }

    @PutMapping("/{keyId}/status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateApiKeyStatus(
            @PathVariable Long keyId,
            @RequestBody Map<String, String> body) {
        requirePlatformAdmin();

        String status = body.get("status");
        if (status == null || (!status.equals("active") && !status.equals("disabled"))) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "status 必须为 active 或 disabled");
        }

        if ("disabled".equals(status)) {
            apiKeyApplicationService.revokeApiKey(keyId);
        }

        Map<String, Object> data = Map.of("id", keyId, "status", "REVOKED");
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    @DeleteMapping("/{keyId}")
    public ResponseEntity<ApiResponse<Void>> deleteApiKey(@PathVariable Long keyId) {
        requirePlatformAdmin();
        apiKeyApplicationService.deleteApiKey(keyId);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    private void requirePlatformAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证");
        }
        boolean isAdmin = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_PLATFORM_ADMIN"));
        if (!isAdmin) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "需要 platform_admin 角色");
        }
    }
}
