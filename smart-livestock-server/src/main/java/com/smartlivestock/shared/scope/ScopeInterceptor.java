package com.smartlivestock.shared.scope;

import com.smartlivestock.identity.domain.model.ApiKey;
import com.smartlivestock.shared.security.ApiKeyAuthFilter;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.util.*;

@Component
public class ScopeInterceptor implements HandlerInterceptor {

    private static final Logger log = LoggerFactory.getLogger(ScopeInterceptor.class);
    private static final Set<String> WILDCARD_SCOPES = Set.of("*", "all");
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        Object attr = request.getAttribute(ApiKeyAuthFilter.ATTR_API_KEY);
        if (attr == null) {
            return true;
        }

        ApiKey apiKey = (ApiKey) attr;
        String requiredScope = resolveRequiredScope(request.getRequestURI());
        if (requiredScope == null) {
            return true;
        }

        if (hasScope(apiKey, requiredScope)) {
            return true;
        }

        log.warn("Scope denied: apiKeyId={}, required={}, uri={}", apiKey.getId(), requiredScope, request.getRequestURI());
        response.setStatus(HttpStatus.FORBIDDEN.value());
        response.setContentType("application/json;charset=UTF-8");
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("code", "AUTH_FORBIDDEN");
        body.put("message", "API Key 缺少所需权限: " + requiredScope);
        body.put("data", null);
        response.getWriter().write(objectMapper.writeValueAsString(body));
        return false;
    }

    String resolveRequiredScope(String uri) {
        if (uri == null) return null;
        if (uri.contains("/devices/register")) return "device:register";
        if (uri.contains("/livestock")) return "livestock:read";
        if (uri.contains("/fences")) return "fence:read";
        if (uri.contains("/alerts")) return "alert:read";
        if (uri.contains("/devices")) return "device:read";
        if (uri.contains("/gps-logs")) return "gps:read";
        if (uri.contains("/health")) return "health:read";
        return null;
    }

    boolean hasScope(ApiKey apiKey, String requiredScope) {
        String scopes = apiKey.getScopes();
        if (scopes == null || scopes.isBlank()) return false;
        Set<String> owned = new HashSet<>(Arrays.asList(scopes.split(",")));
        for (String ws : WILDCARD_SCOPES) {
            if (owned.contains(ws)) return true;
        }
        return owned.contains(requiredScope);
    }
}
