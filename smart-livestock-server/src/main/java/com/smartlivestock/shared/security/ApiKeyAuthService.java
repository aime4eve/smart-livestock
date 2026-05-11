package com.smartlivestock.shared.security;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Component;

/**
 * Phase 1 API Key authentication helper for Open API controllers.
 * Validates that the request includes an API Key header.
 * Full key lookup and scope checking will be added in Phase 2.
 */
@Component
public class ApiKeyAuthService {

    private static final String API_KEY_HEADER = "X-API-Key";
    private static final String AUTHORIZATION_HEADER = "Authorization";
    private static final String BEARER_PREFIX = "Bearer ";

    /**
     * Extract and validate the API Key from the request.
     * Supports both X-API-Key header and Authorization: Bearer <key>.
     *
     * @param request the HTTP request
     * @return the extracted API key string
     * @throws ApiException if no API key is present
     */
    public String requireApiKey(HttpServletRequest request) {
        String apiKey = extractApiKey(request);
        if (apiKey == null || apiKey.isBlank()) {
            throw new ApiException(ErrorCode.AUTH_API_KEY_INVALID,
                    "缺少 API Key。请使用 X-API-Key 或 Authorization: Bearer <key> 头");
        }
        // Phase 1: Accept any non-blank key.
        // Phase 2 will look up key_hash in api_keys table, check status and expiry.
        return apiKey;
    }

    /**
     * Validate that the API Key belongs to the same tenant as the farm.
     * Phase 1: Always passes (no key-to-tenant lookup yet).
     *
     * @param apiKey  the API key from the request
     * @param farmId  the farm ID from the URL path
     * @throws ApiException if the key does not have access to this farm
     */
    public void validateFarmAccess(String apiKey, Long farmId) {
        // Phase 1 stub: no tenant-to-key mapping yet.
        // Phase 2 will: look up key -> tenantId, then farm -> tenantId, compare.
    }

    /**
     * Validate that the API Key has the device:register scope.
     * Phase 1: Always passes.
     *
     * @param apiKey the API key from the request
     * @throws ApiException if the key lacks device:register scope
     */
    public void requireDeviceRegisterScope(String apiKey) {
        // Phase 1 stub: no scope checking yet.
        // Phase 2 will check key scopes contain "device:register".
    }

    private String extractApiKey(HttpServletRequest request) {
        // Try X-API-Key header first
        String apiKey = request.getHeader(API_KEY_HEADER);
        if (apiKey != null && !apiKey.isBlank()) {
            return apiKey.trim();
        }

        // Fallback to Authorization: Bearer <key>
        String bearerToken = request.getHeader(AUTHORIZATION_HEADER);
        if (bearerToken != null && bearerToken.startsWith(BEARER_PREFIX)) {
            return bearerToken.substring(BEARER_PREFIX.length()).trim();
        }

        return null;
    }
}
