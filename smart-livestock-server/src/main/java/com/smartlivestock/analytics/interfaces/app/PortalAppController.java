package com.smartlivestock.analytics.interfaces.app;

import com.smartlivestock.analytics.application.service.AnalyticsApplicationService;
import com.smartlivestock.identity.application.ApiKeyApplicationService;
import com.smartlivestock.identity.domain.model.ApiKey;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/portal/keys")
@RequiredArgsConstructor
public class PortalAppController {

    private final ApiKeyApplicationService apiKeyService;
    private final AnalyticsApplicationService analyticsService;

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listMyKeys(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        Long tenantId = requireTenant();
        List<ApiKey> keys = apiKeyService.listApiKeysByTenant(tenantId);

        List<Map<String, Object>> items = keys.stream()
                .map(this::toSummary)
                .toList();

        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "items", items, "page", page, "pageSize", pageSize, "total", items.size())));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> createKey(@RequestBody Map<String, Object> body) {
        Long tenantId = requireTenant();
        String name = (String) body.getOrDefault("name", "默认 Key");
        String scopes = (String) body.getOrDefault("scopes", "livestock:read,fence:read,alert:read");
        int rpm = body.get("requestsPerMinute") != null ? ((Number) body.get("requestsPerMinute")).intValue() : 60;
        int dailyQuota = body.get("dailyQuota") != null ? ((Number) body.get("dailyQuota")).intValue() : 20000;
        String description = (String) body.get("description");

        Map<String, Object> result = apiKeyService.createApiKeyForPortal(tenantId, name, scopes, rpm, dailyQuota, description);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(result));
    }

    @PutMapping("/{keyId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateKey(
            @PathVariable Long keyId, @RequestBody Map<String, Object> body) {
        Long tenantId = requireTenant();
        ApiKey key = apiKeyService.findById(keyId);
        ensureOwnership(key, tenantId);

        String name = (String) body.get("name");
        String description = (String) body.get("description");
        if (name != null) key.setKeyName(name);
        if (description != null) key.setDescription(description);

        apiKeyService.save(key);
        return ResponseEntity.ok(ApiResponse.ok(toSummary(key)));
    }

    @PutMapping("/{keyId}/status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> toggleStatus(
            @PathVariable Long keyId, @RequestBody Map<String, String> body) {
        Long tenantId = requireTenant();
        String status = body.get("status");
        if (!"active".equals(status) && !"disabled".equals(status)) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "status 必须为 active 或 disabled");
        }

        ApiKey key = apiKeyService.findById(keyId);
        ensureOwnership(key, tenantId);

        if ("disabled".equals(status)) {
            apiKeyService.revokeApiKey(keyId);
        } else {
            key.setStatus("ACTIVE");
            apiKeyService.save(key);
        }

        return ResponseEntity.ok(ApiResponse.ok(Map.of("id", keyId, "status",
                "disabled".equals(status) ? "REVOKED" : "ACTIVE")));
    }

    @DeleteMapping("/{keyId}")
    public ResponseEntity<ApiResponse<Void>> deleteKey(@PathVariable Long keyId) {
        Long tenantId = requireTenant();
        ApiKey key = apiKeyService.findById(keyId);
        ensureOwnership(key, tenantId);
        apiKeyService.deleteApiKey(keyId);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    @GetMapping("/{keyId}/usage")
    public ResponseEntity<ApiResponse<Object>> getKeyUsage(
            @PathVariable Long keyId,
            @RequestParam LocalDate from,
            @RequestParam LocalDate to) {
        Long tenantId = requireTenant();
        ApiKey key = apiKeyService.findById(keyId);
        ensureOwnership(key, tenantId);
        return ResponseEntity.ok(ApiResponse.ok(
                analyticsService.getApiKeyOverview(tenantId, keyId, from, to)));
    }

    @GetMapping("/dashboard")
    public ResponseEntity<ApiResponse<Object>> dashboard(
            @RequestParam LocalDate from,
            @RequestParam LocalDate to) {
        Long tenantId = requireTenant();
        return ResponseEntity.ok(ApiResponse.ok(
                analyticsService.getTenantOverview(tenantId, from, to)));
    }

    private Long requireTenant() {
        Long tid = TenantContext.getCurrentTenant();
        if (tid == null) throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "无法识别租户");
        return tid;
    }

    private void ensureOwnership(ApiKey key, Long tenantId) {
        if (!tenantId.equals(key.getTenantId())) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "无权操作此 API Key");
        }
    }

    private Map<String, Object> toSummary(ApiKey k) {
        return Map.<String, Object>of(
                "id", k.getId(),
                "keyName", k.getKeyName() != null ? k.getKeyName() : "",
                "prefix", k.getKeyPrefix() != null ? k.getKeyPrefix() : "",
                "status", k.getStatus() != null ? k.getStatus() : "",
                "scopes", k.getScopes() != null ? k.getScopes() : "",
                "requestsPerMinute", k.getRequestsPerMinute() != null ? k.getRequestsPerMinute() : 0,
                "dailyQuota", k.getDailyQuota() != null ? k.getDailyQuota() : 0,
                "description", k.getDescription() != null ? k.getDescription() : "",
                "createdAt", k.getCreatedAt() != null ? k.getCreatedAt().toString() : "",
                "lastUsedAt", k.getLastUsedAt() != null ? k.getLastUsedAt().toString() : ""
        );
    }
}
