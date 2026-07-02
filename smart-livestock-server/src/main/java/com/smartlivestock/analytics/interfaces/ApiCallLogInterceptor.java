package com.smartlivestock.analytics.interfaces;

import com.smartlivestock.analytics.application.service.AsyncApiCallLogService;
import com.smartlivestock.analytics.domain.model.ApiCallLog;
import com.smartlivestock.identity.domain.model.ApiKey;
import com.smartlivestock.shared.security.ApiKeyAuthFilter;
import com.smartlivestock.shared.tenant.TenantContext;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.time.Instant;

@Component
@RequiredArgsConstructor
@Slf4j
public class ApiCallLogInterceptor implements HandlerInterceptor {

    private static final String ATTR_START_TIME = "com.smartlivestock.requestStartTime";

    private final AsyncApiCallLogService asyncApiCallLogService;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
                             Object handler) {
        request.setAttribute(ATTR_START_TIME, System.currentTimeMillis());
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response,
                                Object handler, Exception ex) {
        Long startTime = (Long) request.getAttribute(ATTR_START_TIME);
        int responseTimeMs = startTime != null ? (int) (System.currentTimeMillis() - startTime) : 0;

        ApiCallLog callLog = new ApiCallLog();
        callLog.setEndpoint(extractEndpoint(request));
        callLog.setMethod(request.getMethod());
        callLog.setStatusCode(response.getStatus());
        callLog.setResponseTimeMs(responseTimeMs);
        callLog.setIpAddress(extractIpAddress(request));
        callLog.setUserAgent(truncate(request.getHeader("User-Agent"), 500));
        callLog.setFarmId(extractFarmId(request));
        callLog.setRequestedAt(Instant.now());

        // API Key 认证：从 ApiKeyAuthFilter 设置的属性获取
        Object cached = request.getAttribute(ApiKeyAuthFilter.ATTR_API_KEY);
        if (cached instanceof ApiKey apiKey) {
            callLog.setApiKeyId(apiKey.getId());
            callLog.setTenantId(apiKey.getTenantId());
        } else {
            // JWT 认证：从 TenantContext 获取租户 ID（auth 端点可能为 null）
            callLog.setApiKeyId(null);
            callLog.setTenantId(TenantContext.getCurrentTenant());
        }

        asyncApiCallLogService.logAsync(callLog);
    }

    private String extractEndpoint(HttpServletRequest request) {
        String uri = request.getRequestURI();
        // Normalize path params: /farms/123/livestock → /farms/{id}/livestock
        return uri.replaceAll("/\\d+", "/{id}");
    }

    private String extractIpAddress(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip != null && !ip.isBlank()) {
            return truncate(ip.split(",")[0].trim(), 45);
        }
        ip = request.getHeader("X-Real-IP");
        if (ip != null && !ip.isBlank()) {
            return truncate(ip.trim(), 45);
        }
        return truncate(request.getRemoteAddr(), 45);
    }

    private Long extractFarmId(HttpServletRequest request) {
        String uri = request.getRequestURI();
        // Match /farms/{id}/ in the URI
        java.util.regex.Matcher m = java.util.regex.Pattern.compile("/farms/(\\d+)/").matcher(uri);
        if (m.find()) {
            try { return Long.parseLong(m.group(1)); } catch (NumberFormatException ignored) {}
        }
        return null;
    }

    private String truncate(String s, int max) {
        if (s == null) return null;
        return s.length() > max ? s.substring(0, max) : s;
    }
}
