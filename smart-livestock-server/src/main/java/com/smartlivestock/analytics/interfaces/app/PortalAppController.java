package com.smartlivestock.analytics.interfaces.app;

import com.smartlivestock.analytics.application.service.AnalyticsApplicationService;
import com.smartlivestock.analytics.domain.port.IdentityQueryPort;
import com.smartlivestock.analytics.domain.port.dto.ApiKeyInfo;
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

    private final IdentityQueryPort identityQueryPort;
    private final AnalyticsApplicationService analyticsService;

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listMyKeys(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        Long tenantId = requireTenant();
        List<ApiKeyInfo> keys = identityQueryPort.listApiKeysByTenant(tenantId);

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

        var newKey = identityQueryPort.createApiKey(tenantId, name, scopes, rpm, dailyQuota, description);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(toSummary(newKey)));
    }

    @PutMapping("/{keyId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateKey(
            @PathVariable Long keyId, @RequestBody Map<String, Object> body) {
        Long tenantId = requireTenant();
        ApiKeyInfo key = identityQueryPort.findApiKeyById(keyId).orElse(null);
        if (key == null) return ResponseEntity.status(404).body(ApiResponse.error(com.smartlivestock.shared.common.ErrorCode.RESOURCE_NOT_FOUND, "API Key not found"));
        ensureOwnership(key.tenantId(), tenantId, key.id());

        String name = (String) body.get("name");
        String description = (String) body.get("description");
        String newName = name != null ? name : key.keyName();
        String newDesc = description != null ? description : key.description();
        ApiKeyInfo updated = new ApiKeyInfo(key.id(), key.tenantId(), key.keyValue(), newName, key.keyPrefix(),
                key.status(), key.scopes(), key.requestsPerMinute(), key.dailyQuota(), newDesc, key.createdAt(), key.lastUsedAt());

        identityQueryPort.saveApiKey(updated);
        return ResponseEntity.ok(ApiResponse.ok(toSummary(updated)));
    }

    @PutMapping("/{keyId}/status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> toggleStatus(
            @PathVariable Long keyId, @RequestBody Map<String, String> body) {
        Long tenantId = requireTenant();
        String status = body.get("status");
        if (!"active".equals(status) && !"disabled".equals(status)) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "status 必须为 active 或 disabled");
        }

        ApiKeyInfo key = identityQueryPort.findApiKeyById(keyId).orElse(null);
        if (key == null) return ResponseEntity.status(404).body(ApiResponse.error(com.smartlivestock.shared.common.ErrorCode.RESOURCE_NOT_FOUND, "API Key not found"));
        ensureOwnership(key.tenantId(), tenantId, key.id());

        if ("disabled".equals(status)) {
            identityQueryPort.revokeApiKey(keyId);
        } else {
            ApiKeyInfo updated = new ApiKeyInfo(key.id(), key.tenantId(), key.keyValue(), key.keyName(), key.keyPrefix(),
                    "ACTIVE", key.scopes(), key.requestsPerMinute(), key.dailyQuota(), key.description(), key.createdAt(), key.lastUsedAt());
            identityQueryPort.saveApiKey(updated);
        }

        return ResponseEntity.ok(ApiResponse.ok(Map.of("id", keyId, "status",
                "disabled".equals(status) ? "REVOKED" : "ACTIVE")));
    }

    @DeleteMapping("/{keyId}")
    public ResponseEntity<ApiResponse<Void>> deleteKey(@PathVariable Long keyId) {
        Long tenantId = requireTenant();
        ApiKeyInfo key = identityQueryPort.findApiKeyById(keyId).orElse(null);
        if (key == null) return ResponseEntity.status(404).body(ApiResponse.error(com.smartlivestock.shared.common.ErrorCode.RESOURCE_NOT_FOUND, "API Key not found"));
        ensureOwnership(key.tenantId(), tenantId, key.id());
        identityQueryPort.deleteApiKey(keyId);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    @GetMapping("/{keyId}/usage")
    public ResponseEntity<ApiResponse<Object>> getKeyUsage(
            @PathVariable Long keyId,
            @RequestParam LocalDate from,
            @RequestParam LocalDate to) {
        Long tenantId = requireTenant();
        ApiKeyInfo key = identityQueryPort.findApiKeyById(keyId).orElse(null);
        if (key == null) return ResponseEntity.status(404).body(ApiResponse.error(com.smartlivestock.shared.common.ErrorCode.RESOURCE_NOT_FOUND, "API Key not found"));
        ensureOwnership(key.tenantId(), tenantId, key.id());
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

    private void ensureOwnership(Long keyTenantId, Long sessionTenantId, Long keyId) {
        if (!keyTenantId.equals(sessionTenantId)) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "无权操作此 API Key");
        }
    }

    private Map<String, Object> toSummary(ApiKeyInfo k) {
        return Map.<String, Object>of(
                "id", k.id(),
                "keyName", k.keyName() != null ? k.keyName() : "",
                "prefix", k.keyPrefix() != null ? k.keyPrefix() : "",
                "status", k.status() != null ? k.status() : "",
                "scopes", k.scopes() != null ? k.scopes() : "",
                "requestsPerMinute", k.requestsPerMinute() != null ? k.requestsPerMinute() : 0,
                "dailyQuota", k.dailyQuota() != null ? k.dailyQuota() : 0,
                "description", k.description() != null ? k.description() : "",
                "createdAt", k.createdAt() != null ? k.createdAt().toString() : "",
                "lastUsedAt", k.lastUsedAt() != null ? k.lastUsedAt().toString() : ""
        );
    }
}
