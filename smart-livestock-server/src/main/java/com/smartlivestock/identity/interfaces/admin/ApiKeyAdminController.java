package com.smartlivestock.identity.interfaces.admin;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Admin API Key Management — 4 endpoints.
 * Phase 1 stub: API Key infrastructure is Phase 2. Returns placeholder data.
 */
@RestController
@RequestMapping("/api/v1/admin/api-keys")
@RequiredArgsConstructor
public class ApiKeyAdminController {

    /**
     * GET /api/v1/admin/api-keys
     * List all API keys.
     * Phase 1 stub — returns empty list.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listApiKeys(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) Long tenantId,
            @RequestParam(required = false) String status) {
        requirePlatformAdmin();

        // Phase 1 stub: no API key storage yet
        List<Map<String, Object>> items = List.of();

        Map<String, Object> data = Map.of(
                "items", items,
                "page", page,
                "pageSize", pageSize,
                "total", 0
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * POST /api/v1/admin/api-keys
     * Create API key.
     * Phase 1 stub — returns placeholder response.
     */
    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> createApiKey(@RequestBody Map<String, Object> body) {
        requirePlatformAdmin();

        // Phase 1 stub: API key creation not yet implemented
        Map<String, Object> data = Map.<String, Object>of(
                "keyId", "stub_key",
                "prefix", "sl_stub_",
                "message", "API key creation not yet implemented (Phase 2)"
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(data));
    }

    /**
     * PUT /api/v1/admin/api-keys/{keyId}/status
     * Enable/disable API key. Idempotent.
     * Phase 1 stub.
     */
    @PutMapping("/{keyId}/status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateApiKeyStatus(
            @PathVariable String keyId,
            @RequestBody Map<String, String> body) {
        requirePlatformAdmin();

        String status = body.get("status");
        if (status == null || (!status.equals("active") && !status.equals("disabled"))) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "status 必须为 active 或 disabled");
        }

        // Phase 1 stub: no API key storage yet
        Map<String, Object> data = Map.of(
                "keyId", keyId,
                "status", status
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * DELETE /api/v1/admin/api-keys/{keyId}
     * Revoke API key (irreversible).
     * Phase 1 stub.
     */
    @DeleteMapping("/{keyId}")
    public ResponseEntity<ApiResponse<Void>> revokeApiKey(@PathVariable String keyId) {
        requirePlatformAdmin();

        // Phase 1 stub: no API key storage yet
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
