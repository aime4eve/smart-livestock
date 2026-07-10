package com.smartlivestock.shared.security;

import com.smartlivestock.identity.application.ApiKeyApplicationService;
import com.smartlivestock.identity.domain.model.ApiKey;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class ApiKeyAuthService {

    private static final String API_KEY_HEADER = "X-API-Key";
    private static final String AUTHORIZATION_HEADER = "Authorization";
    private static final String BEARER_PREFIX = "Bearer ";

    private final ApiKeyApplicationService apiKeyApplicationService;
    private final FarmRepository farmRepository;

    public String requireApiKey(HttpServletRequest request) {
        String apiKey = extractApiKey(request);
        if (apiKey == null || apiKey.isBlank()) {
            throw new ApiException(ErrorCode.AUTH_API_KEY_INVALID,
                    "缺少 API Key。请使用 X-API-Key 或 Authorization: Bearer <key> 头");
        }
        apiKeyApplicationService.validateApiKey(apiKey);
        return apiKey;
    }

    public ApiKey validateRawKey(String rawKey) {
        return apiKeyApplicationService.validateApiKey(rawKey);
    }

    public void validateFarmAccess(String apiKey, Long farmId) {
        ApiKey key = apiKeyApplicationService.validateApiKey(apiKey);
        var farm = farmRepository.findById(farmId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牧场不存在: " + farmId));
        if (!farm.getTenantId().equals(key.getTenantId())) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "无权访问该牧场");
        }
    }

    public void requireDeviceRegisterScope(String apiKey) {
        ApiKey key = apiKeyApplicationService.validateApiKey(apiKey);
        if (!"admin".equals(key.getRole()) && !"device_manager".equals(key.getRole())) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "API Key 无设备注册权限");
        }
    }

    private String extractApiKey(HttpServletRequest request) {
        String apiKey = request.getHeader(API_KEY_HEADER);
        if (apiKey != null && !apiKey.isBlank()) {
            return apiKey.trim();
        }
        String bearerToken = request.getHeader(AUTHORIZATION_HEADER);
        if (bearerToken != null && bearerToken.startsWith(BEARER_PREFIX)) {
            return bearerToken.substring(BEARER_PREFIX.length()).trim();
        }
        return null;
    }
}
